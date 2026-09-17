import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct Stroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]   // canvas coordinates
    var width: CGFloat
}

enum BlurRenderer {
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    static let maxSide = 4096

    // Whole-image blur used for the on-screen preview (mask is applied by SwiftUI).
    static func blurred(_ image: CGImage, sigma: CGFloat) -> CGImage? {
        let ci = CIImage(cgImage: image)
        let out = ci.clampedToExtent().applyingGaussianBlur(sigma: Double(sigma)).cropped(to: ci.extent)
        return ciContext.createCGImage(out, from: ci.extent)
    }

    static func strokesPath(_ strokes: [Stroke], transform: (CGPoint) -> CGPoint) -> [(CGPath, CGFloat)] {
        strokes.map { s in
            let p = CGMutablePath()
            for (i, pt) in s.points.enumerated() {
                let t = transform(pt)
                if i == 0 { p.move(to: t) }
                p.addLine(to: t)
            }
            return (p, s.width)
        }
    }

    // Re-draws the edit at photo resolution: original, blurred copy, and a mask painted from
    // the strokes (white on black) that CIBlendWithMask uses to pick between them.
    static func export(full: CGImage, strokes: [Stroke], origin: CGPoint, scale: CGFloat, sigma: CGFloat) throws -> CGImage {
        let fit = min(1, CGFloat(maxSide) / CGFloat(max(full.width, full.height)))
        let w = Int((CGFloat(full.width) * fit).rounded()), h = Int((CGFloat(full.height) * fit).rounded())
        let base = fit < 1 ? ImageEngine.resize(full, to: CGSize(width: w, height: h)) : full
        let k = scale * fit

        guard let maskCtx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        else { throw ImageError.surface }
        maskCtx.setFillColor(gray: 0, alpha: 1)
        maskCtx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        maskCtx.setStrokeColor(gray: 1, alpha: 1)
        maskCtx.setLineCap(.round)
        maskCtx.setLineJoin(.round)
        // CoreGraphics' origin is bottom-left; flip y so canvas strokes land where they were drawn.
        for (path, width) in strokesPath(strokes, transform: { CGPoint(x: ($0.x - origin.x) * k, y: CGFloat(h) - ($0.y - origin.y) * k) }) {
            maskCtx.setLineWidth(width * k)
            maskCtx.addPath(path)
            maskCtx.strokePath()
        }
        guard let mask = maskCtx.makeImage() else { throw ImageError.surface }

        let ci = CIImage(cgImage: base)
        let blurred = ci.clampedToExtent().applyingGaussianBlur(sigma: Double(sigma * k)).cropped(to: ci.extent)
        let blend = CIFilter.blendWithMask()
        blend.inputImage = blurred
        blend.backgroundImage = ci
        blend.maskImage = CIImage(cgImage: mask)
        guard let out = blend.outputImage, let result = ciContext.createCGImage(out, from: ci.extent) else { throw ImageError.surface }
        return result
    }
}
