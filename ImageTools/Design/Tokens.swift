import SwiftUI

// Design tokens adapted from the Revolut reference (docs/design-reference-revolut.md)
// for an app surface: true-black canvas, one elevated dark step, white pill CTAs,
// cobalt kept scarce, Inter for everything.
enum Tokens {
    enum Colors {
        static let canvas = Color.black
        static let surfaceDeep = Color(hex: 0x0A0A0A)
        static let surface = Color(hex: 0x16181A)
        static let primary = Color(hex: 0x494FDF)
        static let primaryBright = Color(hex: 0x4F55F1)
        static let onDark = Color.white
        static let onDarkMute = Color.white.opacity(0.72)
        static let onDarkFaint = Color.white.opacity(0.45)
        static let hairline = Color.white.opacity(0.12)
        static let divider = Color.white.opacity(0.06)
        static let ink = Color(hex: 0x191C1F)
        static let success = Color(hex: 0x00A87E)
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    static let pageInset: CGFloat = 20
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension Animation {
    static let press = Animation.spring(response: 0.22, dampingFraction: 0.72)
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.85)
    static let snappy = Animation.spring(response: 0.36, dampingFraction: 0.82)
}

// Type scale. Display sizes use the semibold cut with tight negative tracking.
enum Typo {
    case displayLg, displayMd, headingLg, headingMd, headingSm
    case bodyLg, bodyMd, bodyMdBold, bodySm
    case buttonMd, buttonSm, caption, overline

    private var spec: (name: String, size: CGFloat, lineHeight: CGFloat, tracking: CGFloat) {
        switch self {
        case .displayLg: return ("Inter-SemiBold", 40, 44, -1.2)
        case .displayMd: return ("Inter-SemiBold", 32, 36, -0.8)
        case .headingLg: return ("Inter-SemiBold", 28, 34, -0.56)
        case .headingMd: return ("Inter-SemiBold", 24, 30, -0.36)
        case .headingSm: return ("Inter-SemiBold", 20, 26, -0.2)
        case .bodyLg: return ("Inter-Regular", 18, 28, -0.09)
        case .bodyMd: return ("Inter-Regular", 16, 24, 0.1)
        case .bodyMdBold: return ("Inter-SemiBold", 16, 24, 0.1)
        case .bodySm: return ("Inter-Regular", 14, 20, 0)
        case .buttonMd: return ("Inter-SemiBold", 16, 24, 0.2)
        case .buttonSm: return ("Inter-SemiBold", 14, 20, 0.1)
        case .caption: return ("Inter-Regular", 13, 18, 0)
        case .overline: return ("Inter-SemiBold", 12, 16, 1.2)
        }
    }

    var font: Font { .custom(spec.name, size: spec.size) }
    var tracking: CGFloat { spec.tracking }
    var lineSpacing: CGFloat { max(0, spec.lineHeight - spec.size * 1.21) }
}

extension View {
    func typo(_ style: Typo) -> some View {
        font(style.font).tracking(style.tracking).lineSpacing(style.lineSpacing)
    }
}

enum Tone {
    case `default`, mute, faint, ink, primary, success
    var color: Color {
        switch self {
        case .default: return Tokens.Colors.onDark
        case .mute: return Tokens.Colors.onDarkMute
        case .faint: return Tokens.Colors.onDarkFaint
        case .ink: return Tokens.Colors.ink
        case .primary: return Tokens.Colors.primaryBright
        case .success: return Tokens.Colors.success
        }
    }
}

// Text with a type style and a tone in one call.
struct T: View {
    let text: String
    let style: Typo
    let tone: Tone
    init(_ text: String, _ style: Typo = .bodyMd, tone: Tone = .default) {
        self.text = text
        self.style = style
        self.tone = tone
    }
    var body: some View {
        Text(text).typo(style).foregroundStyle(tone.color)
    }
}
