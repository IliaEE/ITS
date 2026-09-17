import SwiftUI
import PhotosUI

struct BlurView: View {
    private let brushMin = 8.0, brushMax = 100.0
    private let maxCanvasHeight: CGFloat = 480

    @State private var items: [PhotosPickerItem] = []
    @State private var image: PickedImage?
    @State private var strokes: [Stroke] = []
    @State private var strength = 0.5
    @State private var brushT = 0.4
    @State private var blurredPreview: UIImage?
    @State private var busy = false
    @State private var result: Processed?
    @State private var error: String?
    @State private var shareURL: URL?
    @State private var blurTask: Task<Void, Never>?
    @State private var drawing = false

    private var brush: CGFloat { (brushMin + brushT * (brushMax - brushMin)).rounded() }
    private var sigma: CGFloat { 2 + strength * 30 } // canvas points

    // The canvas is exactly the photo, contained in the content width × maxCanvasHeight —
    // no bars, so every point of the canvas is a point of the photo.
    private struct Layout: Equatable { let w, h, scale: CGFloat }
    private var layout: Layout? {
        guard let image else { return nil }
        let cw = UIScreen.main.bounds.width - Tokens.pageInset * 2
        let s = min(cw / CGFloat(image.width), maxCanvasHeight / CGFloat(image.height))
        return Layout(w: CGFloat(image.width) * s, h: CGFloat(image.height) * s, scale: 1 / s)
    }

    var body: some View {
        ScreenScaffold {
            ToolHeader(title: "Blur", subtitle: "Paint over anything to hide it")

            if image == nil {
                PhotosPicker(selection: $items, maxSelectionCount: 1, matching: .images) {
                    EmptyPickerLabel(title: "Choose a photo", hint: "Then paint with your finger over faces, plates or text.")
                }
                .buttonStyle(ScaleButtonStyle(scaleTo: 0.985))
            } else if let result {
                ImagePreview(image: result.image, meta: "\(Format_.dims(result.width, result.height)) · \(Format_.bytes(result.size))", maxHeight: 420)
            } else if let image, let lay = layout {
                VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                    stage(image: image, lay: lay).frame(maxWidth: .infinity)
                    HStack {
                        T(strokes.isEmpty ? "Drag to paint" : "\(strokes.count) stroke\(strokes.count > 1 ? "s" : "")", .bodySm, tone: .mute)
                            .lineLimit(1)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: strokes.count)
                        Spacer(minLength: Tokens.Space.sm)
                        HStack(spacing: Tokens.Space.xs) {
                            IconPill(icon: "arrow.uturn.backward", label: "Undo", disabled: strokes.isEmpty) { withAnimation(.snappy) { _ = strokes.popLast() } }
                            IconPill(icon: "trash", label: "Clear", disabled: strokes.isEmpty) { withAnimation(.snappy) { strokes = [] } }
                            PhotosPicker(selection: $items, maxSelectionCount: 1, matching: .images) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 14, weight: .semibold))
                                    Text("Photo").typo(.buttonSm)
                                }
                                .fixedSize()
                                .foregroundStyle(Tokens.Colors.onDark)
                                .frame(height: 36).padding(.horizontal, 12)
                                .background(Capsule().fill(Tokens.Colors.surface))
                            }
                            .buttonStyle(ScaleButtonStyle(scaleTo: 0.92))
                        }
                    }
                    .padding(.horizontal, Tokens.Space.xs)
                }
                .transition(.pop)
            }

            if image != nil, result == nil {
                SectionBlock(label: "Strength") {
                    HStack(spacing: Tokens.Space.lg) {
                        ITSlider(value: $strength)
                        T("\(Int((strength * 100).rounded()))%", .headingSm)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: Int(strength * 100))
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                SectionBlock(label: "Brush size", delay: 0.04) {
                    HStack(spacing: Tokens.Space.lg) {
                        ITSlider(value: $brushT)
                        Circle().fill(Tokens.Colors.onDark)
                            .frame(width: brush * 0.4, height: brush * 0.4)
                            .frame(width: 40, height: 40)
                            .animation(.press, value: brush)
                        T("\(Int(brush))", .headingSm)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: Int(brush))
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }

            if let result {
                ResultSheet(
                    title: "Blurred",
                    stats: [ResultStat(label: "Strokes", value: String(strokes.count)), ResultStat(label: "Strength", value: "\(Int((strength * 100).rounded()))%"), ResultStat(label: "Size", value: Format_.bytes(result.size))],
                    filename: Naming.output(tool: "blur", ext: "jpg"),
                    primaryTitle: "Save to Photos",
                    onPrimary: { try await Saver.saveToPhotos([NamedFile(data: result.data, name: Naming.output(tool: "blur", ext: "jpg"))]) },
                    shareURL: shareURL,
                    onReset: reset
                )
            }
        } footer: {
            if image != nil, result == nil {
                PillButton(title: strokes.isEmpty ? "Paint over something first" : "Apply blur", size: .lg, loading: busy, disabled: strokes.isEmpty, action: run)
            }
        }
        .scrollDisabled(drawing)
        .animation(.gentle, value: result == nil)
        .animation(.gentle, value: image == nil)
        .onChange(of: items) { _, new in
            guard let item = new.first else { return }
            Task {
                if let loaded = try? await PickedImage.load(item) {
                    withAnimation(.gentle) { image = loaded; strokes = []; result = nil; blurredPreview = nil }
                    scheduleBlur()
                }
                items = []
            }
        }
        .onChange(of: strength) { _, _ in scheduleBlur() }
        .alert("Could not blur the photo", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }

    // Base photo, then a blurred copy of it visible only inside the brush strokes.
    // Both layers and the mask share the canvas coordinate space, so a stroke lands
    // exactly under the finger.
    private func stage(image: PickedImage, lay: Layout) -> some View {
        ZStack {
            Image(uiImage: image.preview).resizable()
            if let blurredPreview {
                Image(uiImage: blurredPreview).resizable()
                    .mask {
                        Canvas { ctx, _ in
                            for (path, width) in BlurRenderer.strokesPath(strokes, transform: { $0 }) {
                                ctx.stroke(Path(path), with: .color(.white), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                            }
                        }
                    }
                    .transition(.opacity)
            }
        }
        .frame(width: lay.w, height: lay.h)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { g in
                    let p = CGPoint(x: min(max(g.location.x, 0), lay.w), y: min(max(g.location.y, 0), lay.h))
                    if !drawing {
                        drawing = true
                        Haptics.tap()
                        strokes.append(Stroke(points: [p], width: brush))
                    } else if !strokes.isEmpty {
                        strokes[strokes.count - 1].points.append(p)
                    }
                }
                .onEnded { _ in drawing = false }
        )
    }

    // The preview blur runs on the ≤1200 px preview at a sigma scaled from canvas points.
    private func scheduleBlur() {
        blurTask?.cancel()
        guard let image, let cg = image.preview.cgImage, let lay = layout else { return }
        let s = sigma * CGFloat(cg.width) / lay.w
        blurTask = Task.detached(priority: .userInitiated) {
            try? await Task.sleep(for: .milliseconds(90))
            guard !Task.isCancelled, let out = BlurRenderer.blurred(cg, sigma: s), !Task.isCancelled else { return }
            let ui = UIImage(cgImage: out)
            await MainActor.run { withAnimation(.easeOut(duration: 0.2)) { blurredPreview = ui } }
        }
    }

    private func run() {
        guard let image, let lay = layout else { return }
        busy = true
        let strokes = strokes, s = sigma
        Task.detached(priority: .userInitiated) {
            do {
                let full = try image.fullImage()
                let cg = try BlurRenderer.export(full: full, strokes: strokes, origin: .zero, scale: lay.scale, sigma: s)
                let out = try ImageEngine.process(cg, format: .jpg, quality: 0.92)
                await MainActor.run {
                    shareURL = Saver.temporaryURL(NamedFile(data: out.data, name: Naming.output(tool: "blur", ext: "jpg")))
                    withAnimation(.gentle) { result = out }
                    busy = false
                }
            } catch {
                await MainActor.run { self.error = error.localizedDescription; busy = false; Haptics.error() }
            }
        }
    }

    private func reset() { withAnimation(.gentle) { image = nil; strokes = []; result = nil; blurredPreview = nil; shareURL = nil } }
}
