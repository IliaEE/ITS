import SwiftUI
import UIKit

// Every tappable surface shrinks slightly on press and springs back — the one
// motion rule that makes the whole UI feel physical.
struct ScaleButtonStyle: ButtonStyle {
    var scaleTo: CGFloat = 0.97
    var haptic = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleTo : 1)
            .animation(.press, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed, haptic { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            }
    }
}

enum PillVariant { case primary, soft, outline, ghost, cobalt }
enum PillSize { case sm, md, lg }

struct PillLabel: View {
    let title: String
    var icon: String? = nil
    var variant: PillVariant = .primary
    var size: PillSize = .md
    var loading = false
    var fullWidth = true

    private var foreground: Color {
        switch variant {
        case .primary: return Tokens.Colors.ink
        case .soft, .outline, .cobalt: return Tokens.Colors.onDark
        case .ghost: return Tokens.Colors.onDarkMute
        }
    }

    @ViewBuilder private var background: some View {
        switch variant {
        case .primary: Capsule().fill(Tokens.Colors.onDark)
        case .soft: Capsule().fill(Tokens.Colors.surface)
        case .outline: Capsule().stroke(Tokens.Colors.onDark, lineWidth: 1)
        case .ghost: Color.clear
        case .cobalt: Capsule().fill(Tokens.Colors.primary)
        }
    }

    var body: some View {
        HStack(spacing: Tokens.Space.sm) {
            if loading {
                ProgressView().tint(foreground)
            } else {
                if let icon { Image(systemName: icon).font(.system(size: 16, weight: .semibold)) }
                Text(title).typo(.buttonMd)
            }
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .frame(height: size == .lg ? 56 : size == .sm ? 36 : 48)
        .padding(.horizontal, fullWidth ? 0 : size == .sm ? 16 : 28)
        .background(background)
        .contentShape(Capsule())
    }
}

struct PillButton: View {
    let title: String
    var icon: String? = nil
    var variant: PillVariant = .primary
    var size: PillSize = .md
    var loading = false
    var disabled = false
    var fullWidth = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PillLabel(title: title, icon: icon, variant: variant, size: size, loading: loading, fullWidth: fullWidth)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(disabled || loading)
        .opacity(disabled || loading ? 0.4 : 1)
    }
}

// Small soft pill with an SF Symbol, used for stage actions (Undo, Clear, Photo…).
struct IconPill: View {
    let icon: String
    let label: String
    var active = false
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                Text(label).typo(.buttonSm)
            }
            .fixedSize()
            .foregroundStyle(active ? Tokens.Colors.ink : Tokens.Colors.onDark)
            .frame(height: 36)
            .padding(.horizontal, 12)
            .background(Capsule().fill(active ? Tokens.Colors.onDark : Tokens.Colors.surface))
        }
        .buttonStyle(ScaleButtonStyle(scaleTo: 0.92))
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
    }
}
