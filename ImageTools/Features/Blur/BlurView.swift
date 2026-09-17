import SwiftUI
import PhotosUI

struct BlurView: View {
    private let brushMin = 8.0, brushMax = 100.0
    private let maxCanvasHeight: CGFloat = 380

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
    @State private var stageShown = false

    private var brush: CGFloat { (brushMin + brushT * (brushMax - brushMin)).rounded() }
    private var sigma: CGFloat { 2 + strength * 30 } // canvas points

    // The photo is drawn contained inside a canvas that spans the content width.
    private struct Layout { let w, h, dw, dh, x, y, scale: CGFloat }
    private func layout(width screen: CGFloat) -> Layout? {
        guard let image else { return nil }
        let w = screen - Tokens.pageInset * 2
        let h = min(maxCanvasHeight, w * CGFloat(image.height) / CGFloat(image.width))
        let s = min(w / CGFloat(image.width), h / CGFloat(image.height))
        let dw = CGFloat(image.width) * s, dh = CGFloat(image.height) * s
        return Layout(w: w, h: h, dw: dw, dh: dh, x: (w - dw) / 2, y: (h - dh) / 2, scale: CGFloat(image.width) / dw)
    }

    var body: some View {
        GeometryReader { geo in
            ScreenScaffold(scroll: image == nil || result != nil) {
                ToolHeader(title: "Blur", subtitle: "Paint over anything to hide it")

                if image == nil {
                    PhotosPicker(selection: $items, maxSelectionCount: 1, matching: .images) {
                        EmptyPickerLabel(title: "Choose a photo", hint: "Then paint with your finger over faces, plates or text.")
                    }
                    .buttonStyle(ScaleButtonStyle(scaleTo: 0.985))
                } else if let result {
                    ImagePreview(image: result.image, meta: "\(Format_.dims(result.width, result.height)) · \(Format_.bytes(result.size))")
                } else if let image, let lay = layout(width: geo.size.width) {
                    VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                        stage(image: image, lay: lay)
                        HStack {
                            T(strokes.isEmpty ? "Drag to paint" : "\(strokes.count) stroke\(strokes.count > 1 ? "s" : "")", .bodySm, tone: .mute).lineLimit(1)
                            Spacer(minLength: Tokens.Space.sm)
                            HStack(spacing: Tokens.Space.xs) {
                                IconPill(icon: "arrow.uturn.backward", label: "Undo", disabled: strokes.isEmpty) { _ = strokes.popLast() }
                                IconPill(icon: "trash", label: "Clear", disabled: strokes.isEmpty) { strokes = [] }
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
                    .scaleEffect(stageShown ? 1 : 0.96)
                    .opacity(stageShown ? 1 : 0)
                    .onAppear { withAnimation(.gentle) { stageShown = true } }
                }

                if image != nil, result == nil {
                    SectionBlock(label: "Strength") {
                        HStack(spacing: Tokens.Space.lg) {
                            ITSlider(value: $strength)
                            T("\(Int((strength * 100).rounded()))%", .headingSm).frame(width: 60, alignment: .trailing)
                        }
                    }
                    SectionBlock(label: "Brush size", delay: 0.04) {
                        HStack(spacing: Tokens.Space.lg) {
                            ITSlider(value: $brushT)
                            Circle().fill(Tokens.Colors.onDark).frame(width: brush * 0.4, height: brush * 0.4).frame(width: 40, height: 40)
                            T("\(Int(brush))", .headingSm).frame(width: 60, alignment: .trailing)
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
                    PillButton(title: strokes.isEmpty ? "Paint over something first" : "Apply blur", size: .lg, loading: busy, disabled: strokes.isEmpty) { run(width: geo.size.width) }
                }
            }
        }
        .onChange(of: items) { _, new in
            guard let item = new.first else { return }
            Task {
                if let loaded = try? await PickedImage.load(item) {
                    withAnimation(.gentle) { image = loaded; strokes = []; result = nil; blurredPreview = nil; stageShown = false }
                    scheduleBlur()
                }
                items = []
            }
        }
        .onChange(of: strength) { _, _ in scheduleBlur() }
        .alert("Could not blur the photo", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }

    // Base photo, then a blurred copy of it visible only inside the brush strokes.
    private func stage(image: PickedImage, lay: Layout) -> some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: image.preview).resizable().frame(width: lay.dw, height: lay.dh).offset(x: lay.x, y: lay.y)
            if let blurredPreview {
                Image(uiImage: blurredPreview).resizable().frame(width: lay.dw, height: lay.dh).offset(x: lay.x, y: lay.y)
                    .mask {
                        Canvas { ctx, _ in
                            for (path, width) in BlurRenderer.strokesPath(strokes, transform: { $0 }) {
                                ctx.stroke(Path(path), with: .color(.white), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                            }
                        }
                    }
            }
        }
        .frame(width: lay.w, height: lay.h)
        .background(Tokens.Colors.canvas)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { g in
                    if !drawing {
                        drawing = true
                        strokes.append(Stroke(points: [g.location], width: brush))
                    } else if !strokes.isEmpty {
                        strokes[strokes.count - 1].points.append(g.location)
                    }
                }
                .onEnded { _ in drawing = false }
        )
    }

    // The preview blur runs on the ≤1200 px preview at a sigma scaled from canvas points.
    private func scheduleBlur() {
        blurTask?.cancel()
        guard let image, let cg = image.preview.cgImage else { return }
        let s = sigma
        blurTask = Task.detached(priority: .userInitiated) {
            try? await Task.sleep(for: .milliseconds(90))
            guard !Task.isCancelled else { return }
            let canvasWidth = await UIScreen.main.bounds.width - Tokens.pageInset * 2
            let previewPerPoint = CGFloat(cg.width) / canvasWidth
            guard let out = BlurRenderer.blurred(cg, sigma: s * previewPerPoint), !Task.isCancelled else { return }
            let ui = UIImage(cgImage: out)
            await MainActor.run { blurredPreview = ui }
        }
    }

    private func run(width: CGFloat) {
        guard let image, let lay = layout(width: width) else { return }
        busy = true
        let strokes = strokes, s = sigma
        Task.detached(priority: .userInitiated) {
            do {
                let full = try image.fullImage()
                let cg = try BlurRenderer.export(full: full, strokes: strokes, origin: CGPoint(x: lay.x, y: lay.y), scale: lay.scale, sigma: s)
                let out = try ImageEngine.process(cg, format: .jpg, quality: 0.92)
                await MainActor.run {
                    shareURL = Saver.temporaryURL(NamedFile(data: out.data, name: Naming.output(tool: "blur", ext: "jpg")))
                    withAnimation(.gentle) { result = out }
                    busy = false
                }
            } catch {
                await MainActor.run { self.error = error.localizedDescription; busy = false }
            }
        }
    }

    private func reset() { withAnimation(.gentle) { image = nil; strokes = []; result = nil; blurredPreview = nil; shareURL = nil; stageShown = false } }
}
