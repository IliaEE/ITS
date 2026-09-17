import SwiftUI
import PhotosUI

struct SizeView: View {
    enum Mode: Hashable { case resize, fit }
    private struct Preset: Identifiable { let id: String; let label: String; var percent: Double? = nil; var longest: Int? = nil }
    private struct Ratio: Identifiable { let id: String; let label: String; let w: Double; let h: Double }

    private let presets: [Preset] = [
        Preset(id: "100", label: "Original", percent: 1), Preset(id: "75", label: "75%", percent: 0.75),
        Preset(id: "50", label: "50%", percent: 0.5), Preset(id: "25", label: "25%", percent: 0.25),
        Preset(id: "hd", label: "HD 1280", longest: 1280), Preset(id: "fhd", label: "FHD 1920", longest: 1920),
        Preset(id: "4k", label: "4K 3840", longest: 3840),
    ]
    private let ratios: [Ratio] = [
        Ratio(id: "1:1", label: "Square 1:1", w: 1, h: 1), Ratio(id: "4:5", label: "Portrait 4:5", w: 4, h: 5),
        Ratio(id: "9:16", label: "Story 9:16", w: 9, h: 16), Ratio(id: "16:9", label: "Wide 16:9", w: 16, h: 9),
        Ratio(id: "3:4", label: "3:4", w: 3, h: 4), Ratio(id: "4:3", label: "4:3", w: 4, h: 3),
    ]
    private let dpis = [72, 150, 300]
    private let maxSide = 3000.0

    @State private var items: [PhotosPickerItem] = []
    @State private var images: [PickedImage] = []
    @State private var mode: Mode = .resize
    @State private var preset = "100"
    @State private var customW = ""
    @State private var customH = ""
    @State private var ratio = "1:1"
    @State private var background: UIColor = .white
    @State private var dpi: Int?
    @State private var busy = false
    @State private var progress = 0.0
    @State private var results: [Processed]?
    @State private var error: String?
    @State private var shareURL: URL?

    // The same rule is applied to every photo in the batch, so targets are computed per image.
    private func resizeTarget(_ w: Int, _ h: Int) -> CGSize? {
        if preset == "custom" {
            let cw = Int(customW) ?? 0, ch = Int(customH) ?? 0
            if cw > 0, ch <= 0 { return CGSize(width: Double(cw), height: (Double(cw) * Double(h) / Double(w)).rounded()) }
            if ch > 0, cw <= 0 { return CGSize(width: (Double(ch) * Double(w) / Double(h)).rounded(), height: Double(ch)) }
            if cw > 0, ch > 0 { return CGSize(width: Double(cw), height: Double(ch)) }
            return nil
        }
        guard let p = presets.first(where: { $0.id == preset }) else { return nil }
        if let pct = p.percent { return CGSize(width: (Double(w) * pct).rounded(), height: (Double(h) * pct).rounded()) }
        let s = min(1, Double(p.longest!) / Double(max(w, h)))
        return CGSize(width: (Double(w) * s).rounded(), height: (Double(h) * s).rounded())
    }

    private func fitTarget(_ w: Int, _ h: Int) -> CGSize {
        let r = ratios.first(where: { $0.id == ratio })!
        let want = r.w / r.h
        var width = Double(w), height = Double(h)
        if want >= width / height { width = (height * want).rounded() } else { height = (width / want).rounded() }
        let s = min(1, maxSide / max(width, height))
        return CGSize(width: (width * s).rounded(), height: (height * s).rounded())
    }

    private var first: PickedImage? { images.first }
    private var many: Bool { images.count > 1 }
    private var preview: CGSize? { first.flatMap { mode == .resize ? resizeTarget($0.width, $0.height) : fitTarget($0.width, $0.height) } }
    private var toolName: String { mode == .resize ? "resize" : "fit" }
    private var cta: String {
        let count = many ? "\(images.count) photos" : ""
        if mode == .resize {
            guard let p = preview else { return "Enter a size" }
            return many ? "Resize \(count)" : "Resize to \(Int(p.width)) × \(Int(p.height))"
        }
        return "Fit \(count.isEmpty ? "photo" : count) to \(ratio)"
    }

    var body: some View {
        ScreenScaffold {
            ToolHeader(title: "Image Size", subtitle: "Resize · Fit to ratio · DPI")

            if first == nil {
                PhotosPicker(selection: $items, maxSelectionCount: 20, matching: .images) {
                    EmptyPickerLabel(title: "Choose photos", hint: "One photo, or a batch — the same size applies to all of them.")
                }
                .buttonStyle(ScaleButtonStyle(scaleTo: 0.985))
            } else if many, results == nil {
                ThumbStrip(images: images, meta: "\(images.count) photos · \(Format_.bytes(images.reduce(0) { $0 + $1.size }))") {
                    PhotosPicker(selection: $items, maxSelectionCount: 20, matching: .images) {
                        PillLabel(title: "Change", variant: .soft, size: .sm, fullWidth: false)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            } else if let first {
                let shown = results?.first
                let meta: String = {
                    if let results, let r = shown {
                        return many ? "\(results.count) photos · \(Format_.bytes(results.reduce(0) { $0 + $1.size }))"
                                    : "\(Format_.dims(r.width, r.height)) · \(Format_.bytes(r.size))\(dpi.map { " · \($0) DPI" } ?? "")"
                    }
                    return "\(first.format) · \(Format_.dims(first.width, first.height)) · \(Format_.bytes(first.size))"
                }()
                ImagePreview(image: shown?.image ?? first.preview, meta: meta) {
                    if results == nil {
                        PhotosPicker(selection: $items, maxSelectionCount: 20, matching: .images) { ReplaceBadge() }
                            .buttonStyle(ScaleButtonStyle(scaleTo: 0.9))
                    }
                }
            }

            if first != nil, results == nil {
                SectionBlock(label: "Mode") {
                    Segmented(options: [(Mode.resize, "Resize"), (.fit, "Fit to ratio")], selection: $mode)
                }
                if mode == .resize {
                    SectionBlock(label: "Size", delay: 0.04) {
                        WrapLayout {
                            ForEach(presets) { p in Chip(label: p.label, selected: preset == p.id) { preset = p.id } }
                            Chip(label: "Custom", selected: preset == "custom") { preset = "custom" }
                        }
                        if preset == "custom" {
                            HStack(spacing: Tokens.Space.md) {
                                NumberField(placeholder: "Width", text: $customW).onChange(of: customW) { _, v in if !v.isEmpty { customH = "" } }
                                T("×", .bodyMd, tone: .faint)
                                NumberField(placeholder: "Height", text: $customH).onChange(of: customH) { _, v in if !v.isEmpty { customW = "" } }
                            }
                            .transition(.opacity)
                        }
                        if let p = preview {
                            T(many ? "First photo → \(Int(p.width)) × \(Int(p.height)) px, others scaled the same way" : "Output \(Int(p.width)) × \(Int(p.height)) px", .caption, tone: .faint)
                        }
                    }
                } else {
                    SectionBlock(label: "Aspect ratio", delay: 0.04) {
                        WrapLayout { ForEach(ratios) { r in Chip(label: r.label, selected: ratio == r.id) { ratio = r.id } } }
                        if let p = preview { T("Canvas \(Int(p.width)) × \(Int(p.height)) px, photo centered, nothing cropped", .caption, tone: .faint) }
                    }
                    SectionBlock(label: "Background", delay: 0.08) {
                        WrapLayout {
                            Chip(label: "White", selected: background == .white) { background = .white }
                            Chip(label: "Black", selected: background == .black) { background = .black }
                        }
                    }
                }
                SectionBlock(label: "DPI", delay: 0.12) {
                    WrapLayout {
                        Chip(label: "Keep", selected: dpi == nil) { dpi = nil }
                        ForEach(dpis, id: \.self) { d in Chip(label: "\(d) DPI", selected: dpi == d) { dpi = d } }
                    }
                    T("Print resolution written into the file. Pixels stay the same.", .caption, tone: .faint)
                    if busy, many { ITProgressBar(value: progress) }
                }
            }

            if let first, let results, let r = results.first {
                ResultSheet(
                    title: mode == .resize ? (many ? "\(results.count) photos resized" : "Resized") : (many ? "\(results.count) photos fitted" : "Fitted"),
                    stats: many
                        ? [ResultStat(label: "Photos", value: String(results.count)), ResultStat(label: "First", value: Format_.dims(r.width, r.height)), ResultStat(label: "Total", value: Format_.bytes(results.reduce(0) { $0 + $1.size }))]
                        : [ResultStat(label: "Before", value: Format_.dims(first.width, first.height)), ResultStat(label: "After", value: Format_.dims(r.width, r.height)), ResultStat(label: dpi == nil ? "Size" : "DPI", value: dpi.map(String.init) ?? Format_.bytes(r.size))],
                    filename: Naming.output(tool: toolName, ext: r.format.ext, index: 0, total: results.count),
                    primaryTitle: many ? "Save all to Photos" : "Save to Photos",
                    onPrimary: { try await Saver.saveToPhotos(results.enumerated().map { NamedFile(data: $1.data, name: Naming.output(tool: toolName, ext: $1.format.ext, index: $0, total: results.count)) }) },
                    shareURL: many ? nil : shareURL,
                    onReset: reset
                )
            }
        } footer: {
            if first != nil, results == nil {
                PillButton(title: cta, size: .lg, loading: busy, disabled: preview == nil, action: run)
            }
        }
        .onChange(of: items) { _, new in
            guard !new.isEmpty else { return }
            Task {
                let loaded = await PickedImage.load(new)
                if !loaded.isEmpty { withAnimation(.gentle) { images = loaded; results = nil; preset = "100" } }
                items = []
            }
        }
        .animation(.gentle, value: mode)
        .animation(.gentle, value: preset)
        .alert("Could not process the photo", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }

    private func run() {
        busy = true
        progress = 0
        let images = images, mode = mode, dpi = dpi, background = background
        Task.detached(priority: .userInitiated) {
            do {
                var out: [Processed] = []
                for (i, img) in images.enumerated() {
                    let full = try img.fullImage()
                    let processed: Processed
                    if mode == .resize {
                        guard let target = await resizeTarget(img.width, img.height) else { throw SizeError.noSize }
                        let fmt: OutputFormat = img.format == "PNG" ? .png : .jpg
                        processed = try ImageEngine.process(ImageEngine.resize(full, to: target), format: fmt, dpi: dpi)
                    } else {
                        let target = await fitTarget(img.width, img.height)
                        processed = try ImageEngine.process(ImageEngine.pad(full, canvas: target, background: background), format: .jpg, quality: 0.95, dpi: dpi)
                    }
                    out.append(processed)
                    let p = Double(i + 1) / Double(images.count)
                    await MainActor.run { progress = p }
                }
                let finished = out
                await MainActor.run {
                    if finished.count == 1, let r = finished.first {
                        shareURL = Saver.temporaryURL(NamedFile(data: r.data, name: Naming.output(tool: toolName, ext: r.format.ext)))
                    }
                    withAnimation(.gentle) { results = finished }
                    busy = false
                }
            } catch {
                await MainActor.run { self.error = error.localizedDescription; busy = false }
            }
        }
    }

    private func reset() { withAnimation(.gentle) { images = []; results = nil; shareURL = nil } }

    enum SizeError: LocalizedError {
        case noSize
        var errorDescription: String? { "Enter a width or a height." }
    }
}
