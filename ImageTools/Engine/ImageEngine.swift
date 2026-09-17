import UIKit
import ImageIO
import UniformTypeIdentifiers

enum OutputFormat: String {
    case jpg, png
    var utType: UTType { self == .png ? .png : .jpeg }
    var ext: String { rawValue }
}

struct Processed {
    let data: Data
    let width: Int
    let height: Int
    let format: OutputFormat
    let image: UIImage   // ≤ 1200 px preview of the result, decoded once
    var size: Int { data.count }
}

// Everything here is ImageIO / CoreGraphics — no third-party code, no network.
enum ImageEngine {
    static func dimensions(of data: Data) throws -> (width: Int, height: Int) {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
              let w = props[kCGImagePropertyPixelWidth] as? Int, let h = props[kCGImagePropertyPixelHeight] as? Int
        else { throw ImageError.unreadable }
        // Orientation 5–8 swap the axes.
        let orientation = props[kCGImagePropertyOrientation] as? UInt32 ?? 1
        return orientation >= 5 ? (h, w) : (w, h)
    }

    // Decodes with EXIF orientation applied. ImageIO's thumbnail path is the one API that
    // does this in a single pass, and with maxPixel = the long side it yields the full image.
    static func decode(_ data: Data, maxPixel: Int? = nil) throws -> CGImage {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { throw ImageError.unreadable }
        let dims = try dimensions(of: data)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel ?? max(dims.width, dims.height),
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else { throw ImageError.unreadable }
        return image
    }

    static func encode(_ image: CGImage, format: OutputFormat, quality: CGFloat = 0.92, dpi: Int? = nil) throws -> Data {
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, format.utType.identifier as CFString, 1, nil) else { throw ImageError.encodeFailed }
        var props: [CFString: Any] = [:]
        if format == .jpg { props[kCGImageDestinationLossyCompressionQuality] = quality }
        if let dpi {
            // ImageIO writes this into JFIF density and the EXIF/TIFF resolution tags together.
            props[kCGImagePropertyDPIWidth] = dpi
            props[kCGImagePropertyDPIHeight] = dpi
        }
        CGImageDestinationAddImage(dest, image, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { throw ImageError.encodeFailed }
        return out as Data
    }

    static func process(_ image: CGImage, format: OutputFormat, quality: CGFloat = 0.92, dpi: Int? = nil) throws -> Processed {
        let data = try encode(image, format: format, quality: quality, dpi: dpi)
        let preview = UIImage(cgImage: (try? decode(data, maxPixel: 1200)) ?? image)
        return Processed(data: data, width: image.width, height: image.height, format: format, image: preview)
    }

    static func hasAlpha(_ image: CGImage) -> Bool {
        switch image.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast: return false
        default: return true
        }
    }

    // Opaque photos get an RGBX context: an alpha channel on a JPEG only doubles the memory.
    private static func context(width: Int, height: Int, alpha: Bool) -> CGContext? {
        let info = (alpha ? CGImageAlphaInfo.premultipliedLast : CGImageAlphaInfo.noneSkipLast).rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        return CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                         space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: info)
    }

    static func crop(_ image: CGImage, to rect: CGRect) -> CGImage {
        let bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let r = rect.integral.intersection(bounds)
        guard !r.isEmpty, let out = image.cropping(to: r) else { return image }
        return out
    }

    static func resize(_ image: CGImage, to size: CGSize) -> CGImage {
        let w = max(1, Int(size.width.rounded())), h = max(1, Int(size.height.rounded()))
        guard let ctx = context(width: w, height: h, alpha: hasAlpha(image)) else { return image }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage() ?? image
    }

    // "Fit to ratio": the photo centred inside a larger canvas, nothing cropped.
    static func pad(_ image: CGImage, canvas: CGSize, background: UIColor) -> CGImage {
        let w = Int(canvas.width.rounded()), h = Int(canvas.height.rounded())
        guard let ctx = context(width: w, height: h, alpha: false) else { return image }
        ctx.setFillColor(background.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.interpolationQuality = .high
        ctx.draw(image, in: containBox(image: CGSize(width: image.width, height: image.height), in: canvas))
        return ctx.makeImage() ?? image
    }

    static func containBox(image: CGSize, in target: CGSize) -> CGRect {
        let s = min(target.width / image.width, target.height / image.height)
        let w = (image.width * s).rounded(), h = (image.height * s).rounded()
        return CGRect(x: ((target.width - w) / 2).rounded(), y: ((target.height - h) / 2).rounded(), width: w, height: h)
    }
}
