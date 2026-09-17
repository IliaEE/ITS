import SwiftUI

// "Fill & move": the photo covers a frame of the target ratio; drag to reposition,
// pinch to zoom. All math is in full-resolution pixels so the export crops exactly
// what the frame shows.
struct CropModel: Equatable {
    var imageSize: CGSize   // full-resolution pixels
    var frame: CGSize       // on-screen frame in points
    var zoom: CGFloat = 1   // 1 = just covers the frame
    var offset: CGSize = .zero

    static let maxZoom: CGFloat = 4

    var baseScale: CGFloat { max(frame.width / imageSize.width, frame.height / imageSize.height) }
    var scale: CGFloat { baseScale * zoom }
    var drawn: CGSize { CGSize(width: imageSize.width * scale, height: imageSize.height * scale) }

    func clamped(offset o: CGSize, zoom z: CGFloat) -> CGSize {
        let s = baseScale * min(max(z, 1), Self.maxZoom)
        let maxX = max(0, (imageSize.width * s - frame.width) / 2)
        let maxY = max(0, (imageSize.height * s - frame.height) / 2)
        return CGSize(width: min(maxX, max(-maxX, o.width)), height: min(maxY, max(-maxY, o.height)))
    }

    mutating func commit(offset o: CGSize, zoom z: CGFloat) {
        zoom = min(max(z, 1), Self.maxZoom)
        offset = clamped(offset: o, zoom: zoom)
    }

    /// The visible region in image pixels, snapped to whole pixels with the frame's exact ratio.
    var cropRect: CGRect {
        let s = scale
        let left = (frame.width - drawn.width) / 2 + offset.width
        let top = (frame.height - drawn.height) / 2 + offset.height
        let aspect = frame.width / frame.height
        var w = (frame.width / s).rounded(.down), h = (w / aspect).rounded()
        if h > imageSize.height { h = imageSize.height; w = (h * aspect).rounded(.down) }
        let x = min(max(0, (-left / s).rounded()), imageSize.width - w)
        let y = min(max(0, (-top / s).rounded()), imageSize.height - h)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    static func frameSize(aspect: CGFloat, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        var w = maxWidth, h = maxWidth / aspect
        if h > maxHeight { h = maxHeight; w = h * aspect }
        return CGSize(width: w, height: h)
    }
}

struct CropStage: View {
    let image: UIImage
    @Binding var model: CropModel
    @GestureState private var dragDelta: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @State private var interacting = false

    var body: some View {
        let zoom = min(max(model.zoom * pinch, 1), CropModel.maxZoom)
        let offset = model.clamped(offset: CGSize(width: model.offset.width + dragDelta.width, height: model.offset.height + dragDelta.height), zoom: zoom)
        let s = model.baseScale * zoom

        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: model.imageSize.width * s, height: model.imageSize.height * s)
                    .offset(offset)
            }
            .frame(width: model.frame.width, height: model.frame.height)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous)
                    .stroke(Tokens.Colors.onDark.opacity(interacting ? 0.5 : 0.18), lineWidth: 1)
            )
            .overlay { if interacting { GridOverlay().transition(.opacity) } }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 1)
                    .updating($dragDelta) { v, state, _ in state = v.translation }
                    .onChanged { _ in if !interacting { withAnimation(.snappy) { interacting = true } } }
                    .onEnded { v in
                        model.commit(offset: CGSize(width: model.offset.width + v.translation.width, height: model.offset.height + v.translation.height), zoom: model.zoom)
                        withAnimation(.snappy) { interacting = false }
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .updating($pinch) { v, state, _ in state = v }
                    .onChanged { _ in if !interacting { withAnimation(.snappy) { interacting = true } } }
                    .onEnded { v in
                        model.commit(offset: model.offset, zoom: model.zoom * v)
                        withAnimation(.snappy) { interacting = false }
                    }
            )
            .frame(maxWidth: .infinity)
            .animation(.snappy, value: model.frame)
            T("Drag to move · Pinch to zoom", .bodySm, tone: .mute).padding(.horizontal, Tokens.Space.xs)
        }
        .transition(.pop)
    }
}

// Rule-of-thirds guide shown while the photo is being moved.
private struct GridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { p in
                for i in 1...2 {
                    let x = geo.size.width * CGFloat(i) / 3, y = geo.size.height * CGFloat(i) / 3
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: geo.size.height))
                    p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}
