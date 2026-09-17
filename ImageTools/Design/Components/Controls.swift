import SwiftUI

// Selectable pill: the selected state is the white-on-black inversion the reference
// uses for its loudest surfaces, animated instead of snapped.
struct Chip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .typo(.buttonSm)
                .foregroundStyle(selected ? Tokens.Colors.ink : Tokens.Colors.onDark)
                .frame(height: 40)
                .padding(.horizontal, 16)
                .background(Capsule().fill(selected ? Tokens.Colors.onDark : Tokens.Colors.surface))
                .animation(.snappy, value: selected)
        }
        .buttonStyle(ScaleButtonStyle(scaleTo: 0.95))
    }
}

// Segmented control with a single white indicator that slides between options.
struct Segmented<Key: Hashable>: View {
    let options: [(key: Key, label: String)]
    @Binding var selection: Key
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.key) { option in
                let active = option.key == selection
                Button {
                    Haptics.select()
                    withAnimation(.snappy) { selection = option.key }
                } label: {
                    Text(option.label)
                        .typo(.buttonSm)
                        .foregroundStyle(active ? Tokens.Colors.ink : Tokens.Colors.onDarkMute)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if active {
                                Capsule().fill(Tokens.Colors.onDark).matchedGeometryEffect(id: "indicator", in: ns)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Tokens.Colors.surface))
    }
}

// Hairline track, white fill, white thumb — the thumb grows while dragging.
struct ITSlider: View {
    @Binding var value: Double
    private let thumb: CGFloat = 28
    @State private var dragging = false
    @State private var lastTick = -1

    var body: some View {
        GeometryReader { geo in
            let usable = max(1, geo.size.width - thumb)
            let x = CGFloat(value) * usable
            ZStack(alignment: .leading) {
                Capsule().fill(Tokens.Colors.hairline).frame(height: 4)
                Capsule().fill(Tokens.Colors.onDark).frame(width: thumb / 2 + x, height: 4)
                Circle()
                    .fill(Tokens.Colors.onDark)
                    .frame(width: thumb, height: thumb)
                    .scaleEffect(dragging ? 1.15 : 1)
                    .offset(x: x)
            }
            .frame(height: 44)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        dragging = true
                        value = min(1, max(0, Double((g.location.x - thumb / 2) / usable)))
                        let tick = Int(value * 10)
                        if tick != lastTick { lastTick = tick; Haptics.select() }
                    }
                    .onEnded { _ in dragging = false }
            )
            .animation(.press, value: dragging)
        }
        .frame(height: 44)
    }
}

// Pill-shaped numeric field used for custom width / height.
struct NumberField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .keyboardType(.numberPad)
                .font(.custom("Inter-Medium", size: 18))
                .foregroundStyle(Tokens.Colors.onDark)
                .onChange(of: text) { _, new in
                    let digits = new.filter(\.isNumber)
                    if digits != new || digits.count > 5 { text = String(digits.prefix(5)) }
                }
            T("px", .caption, tone: .faint)
        }
        .padding(.horizontal, Tokens.Space.lg)
        .frame(height: 56)
        .background(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous).fill(Tokens.Colors.surface))
        .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous).stroke(Tokens.Colors.hairline, lineWidth: 1))
    }
}

// Wraps chips onto multiple rows like a flex-wrap container.
struct WrapLayout: Layout {
    var spacing: CGFloat = Tokens.Space.sm

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width == .infinity ? x : width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
