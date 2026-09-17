import SwiftUI
import UIKit

// Shared transitions and haptics so every screen moves the same way.
extension AnyTransition {
    /// Result cards: rise from below while fading in, fade out on removal.
    static let rise = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .opacity
    )
    /// Previews and pickers: a slight scale-up with fade.
    static let pop = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.96).combined(with: .opacity),
        removal: .opacity
    )
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func select() { UISelectionFeedbackGenerator().selectionChanged() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}

extension View {
    /// Fades and slides a block in on appear, with an optional stagger delay.
    func riseIn(delay: Double = 0) -> some View { modifier(RiseIn(delay: delay)) }
}

private struct RiseIn: ViewModifier {
    let delay: Double
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(delay)) { shown = true } }
    }
}
