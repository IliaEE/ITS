import Foundation
import Photos

struct NamedFile { let data: Data; let name: String }

enum Saver {
    enum SaveError: LocalizedError {
        case denied
        var errorDescription: String? { "Photo library access was not granted." }
    }

    // Add-only access: the app never reads the library, so the picker stays out-of-process.
    static func saveToPhotos(_ files: [NamedFile]) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw SaveError.denied }
        try await PHPhotoLibrary.shared().performChanges {
            for file in files {
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.originalFilename = file.name
                request.addResource(with: .photo, data: file.data, options: options)
            }
        }
    }

    // A temp file under its final name, so the share sheet shows image-tools-… instead of a UUID.
    static func temporaryURL(_ file: NamedFile) -> URL? {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("image-tools/\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let url = dir.appendingPathComponent(file.name)
            try file.data.write(to: url)
            return url
        } catch { return nil }
    }
}
