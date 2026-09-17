import SwiftUI

enum CardTone { case elevated, deep, featured }

struct ITCard<Content: View>: View {
    var tone: CardTone = .elevated
    var padding: CGFloat = Tokens.Space.xl
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous)
                    .fill(tone == .featured ? Tokens.Colors.primary : tone == .deep ? Tokens.Colors.surfaceDeep : Tokens.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous)
                    .stroke(Tokens.Colors.hairline, lineWidth: tone == .deep ? 1 : 0)
            )
    }
}

struct IconCircle: View {
    let systemName: String
    var size: CGFloat = 48
    var tone: Tone = .default // .default = translucent white circle, .ink = solid white with ink glyph

    var body: some View {
        ZStack {
            Circle().fill(tone == .ink ? Tokens.Colors.onDark : Color.white.opacity(0.08))
            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(tone == .ink ? Tokens.Colors.ink : Tokens.Colors.onDark)
        }
        .frame(width: size, height: size)
    }
}

struct StatView: View {
    let label: String
    let value: String
    var tone: Tone = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            T(label, .caption, tone: .mute)
            T(value, .headingSm, tone: tone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Labelled block that fades and slides in.
struct SectionBlock<Content: View>: View {
    let label: String
    var delay: Double = 0
    @ViewBuilder let content: Content
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            T(label.uppercased(), .overline, tone: .faint)
            content
        }
        .opacity(shown ? 1 : 0)
        .offset(y: shown ? 0 : 14)
        .onAppear { withAnimation(.gentle.delay(delay)) { shown = true } }
    }
}

struct ITProgressBar: View {
    let value: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Tokens.Colors.hairline)
                Capsule().fill(Tokens.Colors.onDark).frame(width: geo.size.width * value)
            }
        }
        .frame(height: 4)
        .animation(.easeOut(duration: 0.25), value: value)
    }
}
