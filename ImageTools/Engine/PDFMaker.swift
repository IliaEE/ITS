import UIKit
import ImageIO

// One photo per A4 page (595 × 842 pt), contained with a 24 pt margin.
enum PDFMaker {
    static let page = CGRect(x: 0, y: 0, width: 595, height: 842)
    static let inset: CGFloat = 24

    static func make(_ images: [PickedImage]) throws -> (data: Data, pages: Int) {
        // 2000 px on the long side is plenty for A4. Re-encoding to JPEG first matters: a CGImage
        // backed by JPEG data is embedded as a DCT stream, otherwise the PDF stores raw pixels.
        let decoded: [CGImage] = try images.map {
            let jpeg = try ImageEngine.encode(try ImageEngine.decode($0.data, maxPixel: 2000), format: .jpg, quality: 0.88)
            guard let src = CGImageSourceCreateWithData(jpeg as CFData, nil), let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else { throw ImageError.encodeFailed }
            return cg
        }
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let data = renderer.pdfData { ctx in
            for cg in decoded {
                ctx.beginPage()
                let box = page.insetBy(dx: inset, dy: inset)
                let rect = ImageEngine.containBox(image: CGSize(width: cg.width, height: cg.height), in: box.size)
                    .offsetBy(dx: box.minX, dy: box.minY)
                UIImage(cgImage: cg).draw(in: rect)
            }
        }
        return (data, decoded.count)
    }
}
