import SwiftUI
import PhotosUI

struct ConvertView: View {
    enum Format: Hashable { case jpg, png, pdf }
    enum Result { case images([Processed]); case pdf(data: Data, pages: Int) }

    @State private var items: [PhotosPickerItem] = []
    @State private var images: [PickedImage] = []
    @State private var format: Format = .jpg
    @State private var busy = false
    @State private var result: Result?
    @State private var error: String?
    @State private var shareURL: URL?

    private var totalIn: Int { images.reduce(0) { $0 + $1.size } }
    private var formatLabel: String { format == .pdf ? "PDF" : format == .png ? "PNG" : "JPG" }
    private var outputs: [Processed] { if case .images(let items) = result { return items } else { return [] } }

    var body: some View {
        ScreenScaffold {
            ToolHeader(title: "Convert", subtitle: "HEIC · JPG · PNG · PDF")

            if images.isEmpty {
                PhotosPicker(selection: $items, maxSelectionCount: 20, matching: .images) {
                    EmptyPickerLabel(title: "Choose photos", hint: "Pick one or several. HEIC from iPhone works out of the box.")
                }
                .buttonStyle(ScaleButtonStyle(scaleTo: 0.985))
            } else if images.count == 1, let first = images.first {
                ImagePreview(image: first.preview, meta: "\(first.format) · \(first.width) × \(first.height) · \(Format_.bytes(first.size))") {
                    if result == nil {
                        PhotosPicker(selection: $items, maxSelectionCount: 20, matching: .images) { ReplaceBadge() }
                            .buttonStyle(ScaleButtonStyle(scaleTo: 0.9))
                    }
                }
            } else {
                ThumbStrip(images: images, meta: "\(images.count) photos · \(Format_.bytes(totalIn))") {
                    if result == nil {
                        PhotosPicker(selection: $items, maxSelectionCount: 20, matching: .images) {
                            PillLabel(title: "Change", variant: .soft, size: .sm, fullWidth: false)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }

            if !images.isEmpty, result == nil {
                SectionBlock(label: "Output format") {
                    Segmented(options: [(Format.jpg, "JPG"), (.png, "PNG"), (.pdf, "PDF")], selection: $format)
                    T(format == .pdf ? "One photo per A4 page, in the order you picked them."
                      : format == .png ? "Lossless. Larger files, keeps transparency."
                      : "Lossy, small files. Best for photos.", .caption, tone: .faint)
                }
            }

            if case .images(let out) = result {
                ResultSheet(
                    title: out.count > 1 ? "\(out.count) photos converted" : "Converted",
                    stats: [ResultStat(label: "Format", value: formatLabel), ResultStat(label: "Before", value: Format_.bytes(totalIn)), ResultStat(label: "After", value: Format_.bytes(out.reduce(0) { $0 + $1.size }))],
                    filename: Naming.output(tool: "convert", ext: out[0].format.ext, index: 0, total: out.count),
                    primaryTitle: "Save to Photos",
                    onPrimary: { try await Saver.saveToPhotos(out.enumerated().map { NamedFile(data: $1.data, name: Naming.output(tool: "convert", ext: $1.format.ext, index: $0, total: out.count)) }) },
                    shareURL: out.count == 1 ? shareURL : nil,
                    onReset: reset
                )
            }
            if case .pdf(_, let pages) = result, let shareURL {
                ResultSheet(
                    title: "PDF ready",
                    stats: [ResultStat(label: "Pages", value: String(pages)), ResultStat(label: "Size", value: Format_.bytes((try? Data(contentsOf: shareURL).count) ?? 0))],
                    filename: shareURL.lastPathComponent,
                    primaryTitle: "Save or share PDF",
                    primaryIcon: "square.and.arrow.up",
                    onPrimary: { presentShare(shareURL) },
                    onReset: reset
                )
            }
        } footer: {
            if !images.isEmpty, result == nil {
                PillButton(title: busy ? "Converting…" : "\(images.count > 1 ? "Convert \(images.count) photos" : "Convert") to \(formatLabel)", size: .lg, loading: busy, action: run)
            }
        }
        .animation(.gentle, value: result == nil)
        .animation(.gentle, value: images.count)
        .onChange(of: items) { _, new in
            guard !new.isEmpty else { return }
            Task {
                let loaded = await PickedImage.load(new)
                if !loaded.isEmpty { withAnimation(.gentle) { images = loaded; result = nil } }
                items = []
            }
        }
        .alert("Conversion failed", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }

    private func run() {
        busy = true
        let images = images, format = format
        Task.detached(priority: .userInitiated) {
            do {
                let out: Result
                if format == .pdf {
                    let pdf = try PDFMaker.make(images)
                    out = .pdf(data: pdf.data, pages: pdf.pages)
                } else {
                    let fmt: OutputFormat = format == .png ? .png : .jpg
                    out = .images(try images.map { try ImageEngine.process(try $0.fullImage(), format: fmt) })
                }
                await MainActor.run {
                    switch out {
                    case .images(let list) where list.count == 1:
                        shareURL = Saver.temporaryURL(NamedFile(data: list[0].data, name: Naming.output(tool: "convert", ext: list[0].format.ext)))
                    case .pdf(let data, _):
                        shareURL = Saver.temporaryURL(NamedFile(data: data, name: Naming.output(tool: "convert", ext: "pdf")))
                    default: shareURL = nil
                    }
                    withAnimation(.gentle) { result = out }
                    busy = false
                }
            } catch {
                await MainActor.run { self.error = error.localizedDescription; busy = false; Haptics.error() }
            }
        }
    }

    private func reset() {
        withAnimation(.gentle) { images = []; result = nil; shareURL = nil }
    }

    // PDF has no "save to Photos"; the primary action opens the share sheet instead.
    private func presentShare(_ url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.keyWindow?.rootViewController?
            .presentedOrSelf.present(vc, animated: true)
    }
}

extension UIViewController {
    var presentedOrSelf: UIViewController { presentedViewController?.presentedOrSelf ?? self }
}

// Number formatting shared by all tools.
enum Format_ {
    static func bytes(_ n: Int) -> String {
        if n <= 0 { return "—" }
        if n < 1024 { return "\(n) B" }
        if n < 1024 * 1024 { return "\(Int((Double(n) / 1024).rounded())) KB" }
        let mb = Double(n) / (1024 * 1024)
        return String(format: mb < 10 ? "%.2f MB" : "%.1f MB", mb)
    }
    static func dims(_ w: Int, _ h: Int) -> String { w > 0 && h > 0 ? "\(w) × \(h)" : "—" }
    static func savings(_ before: Int, _ after: Int) -> String {
        guard before > 0, after > 0, after < before else { return "0%" }
        return "−\(Int(((1 - Double(after) / Double(before)) * 100).rounded()))%"
    }
}
