import SwiftUI
import PhotosUI

struct CompressView: View {
    @State private var items: [PhotosPickerItem] = []
    @State private var image: PickedImage?
    @State private var full: CGImage?
    @State private var quality = 0.7
    @State private var estimate: Int?
    @State private var busy = false
    @State private var result: Processed?
    @State private var error: String?
    @State private var shareURL: URL?
    @State private var estimateTask: Task<Void, Never>?

    var body: some View {
        ScreenScaffold {
            ToolHeader(title: "Compress", subtitle: "Smaller files, same photo")

            if let image {
                ImagePreview(image: result?.image ?? image.preview, meta: "\(image.format) · \(Format_.bytes(image.size))") {
                    if result == nil {
                        PhotosPicker(selection: $items, maxSelectionCount: 1, matching: .images) { ReplaceBadge() }.buttonStyle(ScaleButtonStyle(scaleTo: 0.9))
                    }
                }
            } else {
                PhotosPicker(selection: $items, maxSelectionCount: 1, matching: .images) {
                    EmptyPickerLabel(title: "Choose a photo", hint: "Drag the quality down and watch the file size follow.")
                }
                .buttonStyle(ScaleButtonStyle(scaleTo: 0.985))
            }

            if let image, result == nil {
                SectionBlock(label: "Quality") {
                    VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                        HStack(alignment: .firstTextBaseline) {
                            T("\(Int((quality * 100).rounded()))%", .headingMd)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: Int(quality * 100))
                            Spacer()
                            HStack(spacing: 6) {
                                T("\(Format_.bytes(image.size)) → \(estimate.map(Format_.bytes) ?? "…")", .bodySm, tone: .mute)
                                    .contentTransition(.numericText())
                                if let estimate { T(Format_.savings(image.size, estimate), .bodySm, tone: .success).contentTransition(.numericText()) }
                            }
                            .animation(.snappy, value: estimate)
                        }
                        ITSlider(value: $quality)
                        HStack { T("Smaller", .caption, tone: .faint); Spacer(); T("Sharper", .caption, tone: .faint) }
                    }
                    .padding(Tokens.Space.xl)
                    .background(RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous).fill(Tokens.Colors.surface))
                }
            }

            if let image, let result {
                ResultSheet(
                    title: "Compressed",
                    tool: "compress",
                    stats: [ResultStat(label: "Before", value: Format_.bytes(image.size)), ResultStat(label: "After", value: Format_.bytes(result.size)), ResultStat(label: "Saved", value: Format_.savings(image.size, result.size), tone: .success)],
                    filename: Naming.output(tool: "compress", ext: "jpg"),
                    primaryTitle: "Save to Photos",
                    onPrimary: { try await Saver.saveToPhotos([NamedFile(data: result.data, name: Naming.output(tool: "compress", ext: "jpg"))]) },
                    shareURL: shareURL,
                    onReset: reset
                )
            }
        } footer: {
            if image != nil, result == nil {
                PillButton(title: "Compress" + (estimate.map { " · ≈ \(Format_.bytes($0))" } ?? ""), size: .lg, loading: busy, action: run)
            }
        }
        .animation(.gentle, value: result == nil)
        .animation(.gentle, value: image == nil)
        .onChange(of: items) { _, new in
            guard let item = new.first else { return }
            Task {
                if let loaded = try? await PickedImage.load(item) {
                    withAnimation(.gentle) { image = loaded; result = nil; estimate = nil }
                    Analytics.photosPicked(.compress, count: 1, format: loaded.format)
                    full = try? loaded.fullImage()
                    scheduleEstimate()
                }
                items = []
            }
        }
        .onChange(of: quality) { _, _ in scheduleEstimate() }
        .alert("Compression failed", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }

    // Live size estimate while the slider moves — re-encodes on device after a short pause.
    private func scheduleEstimate() {
        estimateTask?.cancel()
        guard let full, result == nil else { return }
        let q = quality
        estimateTask = Task.detached(priority: .userInitiated) {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled, let data = try? ImageEngine.encode(full, format: .jpg, quality: q) else { return }
            await MainActor.run { if !Task.isCancelled { estimate = data.count } }
        }
    }

    private func run() {
        guard let full, let image else { return }
        busy = true
        let q = quality
        let startedAt = Date()
        Analytics.jobStarted(.compress, count: 1, options: ["quality": Int((q * 100).rounded())])
        Task.detached(priority: .userInitiated) {
            do {
                let out = try ImageEngine.process(full, format: .jpg, quality: q)
                await MainActor.run {
                    shareURL = Saver.temporaryURL(NamedFile(data: out.data, name: Naming.output(tool: "compress", ext: "jpg")))
                    withAnimation(.gentle) { result = out }
                    busy = false
                    Analytics.jobFinished(.compress, count: 1, startedAt: startedAt, inBytes: image.size, outBytes: out.size)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription; busy = false; Haptics.error()
                    Analytics.jobFailed(.compress, reason: error.localizedDescription)
                }
            }
        }
    }

    private func reset() { withAnimation(.gentle) { image = nil; full = nil; result = nil; estimate = nil; shareURL = nil } }
}
