import SwiftUI

struct HomeView: View {
    let onSelect: (Tool) -> Void

    private struct Card { let tool: Tool; let icon: String; let title: String; let desc: String; let featured: Bool }

    private let cards: [Card] = [
        Card(tool: .convert, icon: "arrow.triangle.2.circlepath", title: "Convert", desc: "HEIC to JPG or PNG — or a PDF from any photos.", featured: false),
        Card(tool: .size, icon: "arrow.up.left.and.arrow.down.right", title: "Image Size", desc: "Resize one photo or a batch. Fit any ratio without cropping. Set DPI.", featured: false),
        Card(tool: .compress, icon: "arrow.down.right.and.arrow.up.left", title: "Compress", desc: "Smaller files, same photo. See the size as you drag.", featured: false),
        Card(tool: .blur, icon: "drop", title: "Blur", desc: "Paint over faces, plates or text. Dial the strength.", featured: false),
    ]

    @State private var shown = false
    @State private var showRequest = false
    @State private var copied = false

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                T("IMAGE TOOLS", .overline, tone: .faint)
                Text("Convert.\nResize.\nCompress.").typo(.displayLg).foregroundStyle(Tokens.Colors.onDark)
                T("Runs on your device. Photos never leave your phone.", .bodyLg, tone: .mute)
            }
            .padding(.top, Tokens.Space.xl)
            .padding(.bottom, Tokens.Space.lg)
            .opacity(shown ? 1 : 0)

            VStack(spacing: Tokens.Space.md) {
                ForEach(Array(cards.enumerated()), id: \.element.tool) { i, card in
                    Button { onSelect(card.tool) } label: {
                        HStack(spacing: Tokens.Space.lg) {
                            IconCircle(systemName: card.icon, tone: card.featured ? .ink : .default)
                            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                                T(card.title, .headingMd)
                                Text(card.desc).typo(.bodySm).foregroundStyle(card.featured ? Color.white.opacity(0.8) : Tokens.Colors.onDarkMute)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(card.featured ? Color.white : Tokens.Colors.onDarkFaint)
                        }
                        .padding(Tokens.Space.xl)
                        .background(RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous).fill(card.featured ? Tokens.Colors.primary : Tokens.Colors.surface))
                    }
                    .buttonStyle(ScaleButtonStyle(scaleTo: 0.975))
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown ? 0 : 24)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.12 + Double(i) * 0.09), value: shown)
                }
            }

            VStack(spacing: Tokens.Space.md) {
                // The one cobalt element on this screen: the ask we want people to notice.
                PillButton(title: "Request a feature", icon: "lightbulb", variant: .cobalt, fullWidth: false) {
                    showRequest = true
                }
                Button {
                    UIPasteboard.general.string = Analytics.userID
                    Haptics.tap()
                    withAnimation(.snappy) { copied = true }
                } label: {
                    HStack(spacing: 6) {
                        // Short form is enough to recognise; the tap copies the whole id for support.
                        T(copied ? "Copied" : "ID \(Analytics.userID.prefix(8))", .caption, tone: .faint)
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Tokens.Colors.onDarkFaint)
                    }
                    .contentTransition(.opacity)
                }
                .buttonStyle(ScaleButtonStyle(scaleTo: 0.94, haptic: false))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Tokens.Space.sm)
            .opacity(shown ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.5), value: shown)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.4)) { shown = true } }
        .sheet(isPresented: $showRequest) {
            FeatureRequestView().preferredColorScheme(.dark)
        }
        .onChange(of: copied) { _, on in
            guard on else { return }
            Task { try? await Task.sleep(for: .seconds(2)); withAnimation(.snappy) { copied = false } }
        }
    }
}
