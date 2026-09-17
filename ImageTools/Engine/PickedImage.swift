import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct PickedImage: Identifiable, Equatable {
    let id = UUID()
    let data: Data          // original bytes (HEIC/JPEG/PNG…) as the library holds them
    let width: Int
    let height: Int
    var size: Int { data.count }
    let format: String      // HEIC, JPG, PNG…
    let preview: UIImage    // ≤ 1200 px, orientation baked in

    static func == (a: PickedImage, b: PickedImage) -> Bool { a.id == b.id }

    // Full-resolution decode, orientation baked in. Done on demand so batches stay light.
    func fullImage() throws -> CGImage { try ImageEngine.decode(data) }

    static func load(_ item: PhotosPickerItem) async throws -> PickedImage {
        guard let data = try await item.loadTransferable(type: Data.self) else { throw ImageError.unreadable }
        let type = item.supportedContentTypes.first(where: { $0.conforms(to: .image) })
        let format: String = {
            switch type {
            case .some(.heic), .some(.heif): return "HEIC"
            case .some(.png): return "PNG"
            case .some(.jpeg): return "JPG"
            case .some(.webP): return "WEBP"
            default: return type?.preferredFilenameExtension?.uppercased() ?? "IMG"
            }
        }()
        return try await Task.detached(priority: .userInitiated) {
            let dims = try ImageEngine.dimensions(of: data)
            let preview = UIImage(cgImage: try ImageEngine.decode(data, maxPixel: 1200))
            return PickedImage(data: data, width: dims.width, height: dims.height, format: format, preview: preview)
        }.value
    }

    static func load(_ items: [PhotosPickerItem]) async -> [PickedImage] {
        var out: [PickedImage] = []
        for item in items { if let img = try? await load(item) { out.append(img) } }
        return out
    }
}

enum ImageError: LocalizedError {
    case unreadable, encodeFailed, noStrokes, surface
    var errorDescription: String? {
        switch self {
        case .unreadable: return "This photo could not be read."
        case .encodeFailed: return "The image could not be encoded."
        case .noStrokes: return "Paint over something first."
        case .surface: return "Could not create a drawing surface for this photo size."
        }
    }
}
