import SwiftUI

// Black canvas, safe-area aware, optional sticky footer for the main CTA.
struct ScreenScaffold<Content: View, Footer: View>: View {
    var scroll = true
    let content: Content
    let footer: Footer
    private let hasFooter: Bool

    init(scroll: Bool = true, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.scroll = scroll
        self.content = content()
        self.footer = footer()
        self.hasFooter = true
    }

    fileprivate init(scroll: Bool, content: Content, footer: Footer, hasFooter: Bool) {
        self.scroll = scroll
        self.content = content
        self.footer = footer
        self.hasFooter = hasFooter
    }

    var body: some View {
        Group {
            if scroll {
                ScrollView(showsIndicators: false) { body_ }
                    .scrollDismissesKeyboard(.interactively)
            } else {
                body_.frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .background(Tokens.Colors.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // No ignoresSafeArea on this background: inside safeAreaInset it would expand to
            // fill the screen and cover the content.
            if hasFooter {
                footer
                    .padding(.horizontal, Tokens.pageInset)
                    .padding(.top, Tokens.Space.md)
                    .padding(.bottom, Tokens.Space.md)
                    .background(Tokens.Colors.canvas)
                    .overlay(alignment: .top) { Rectangle().fill(Tokens.Colors.divider).frame(height: 0.5) }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var body_: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.lg) { content }
            .padding(.horizontal, Tokens.pageInset)
            .padding(.top, Tokens.Space.sm)
            .padding(.bottom, Tokens.Space.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension ScreenScaffold where Footer == EmptyView {
    init(scroll: Bool = true, @ViewBuilder content: () -> Content) {
        self.init(scroll: scroll, content: content(), footer: EmptyView(), hasFooter: false)
    }
}

struct ToolHeader: View {
    let title: String
    var subtitle: String? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.lg) {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(Tokens.Colors.surface)
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold)).foregroundStyle(Tokens.Colors.onDark)
                }
                .frame(width: 40, height: 40)
            }
            .buttonStyle(ScaleButtonStyle(scaleTo: 0.9))
            VStack(alignment: .leading, spacing: 2) {
                T(title, .headingLg)
                if let subtitle { T(subtitle, .bodySm, tone: .mute) }
            }
        }
        .padding(.top, Tokens.Space.xs)
    }
}

// The first thing a tool shows: one big surface to pick a photo (label for a PhotosPicker).
struct EmptyPickerLabel: View {
    let title: String
    let hint: String

    var body: some View {
        VStack(spacing: Tokens.Space.xl) {
            IconCircle(systemName: "photo", size: 64, tone: .ink)
            VStack(spacing: Tokens.Space.xs) {
                T(title, .headingSm)
                Text(hint).typo(.bodySm).foregroundStyle(Tokens.Colors.onDarkMute).multilineTextAlignment(.center)
            }
        }
        .padding(Tokens.Space.xxl)
        .frame(maxWidth: .infinity, minHeight: 280)
        .background(RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous).fill(Tokens.Colors.surface))
        .contentShape(RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
    }
}

struct ImagePreview<Replace: View>: View {
    let image: UIImage
    let meta: String
    var maxHeight: CGFloat = 300
    @ViewBuilder let replace: Replace
    @State private var shown = false

    init(image: UIImage, meta: String, maxHeight: CGFloat = 300, @ViewBuilder replace: () -> Replace) {
        self.image = image
        self.meta = meta
        self.maxHeight = maxHeight
        self.replace = replace()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            let ratio = image.size.height > 0 ? image.size.width / image.size.height : 1
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous).fill(Tokens.Colors.surface)
                Image(uiImage: image).resizable().scaledToFit()
                replace.padding(12)
            }
            .aspectRatio(max(ratio, 0.75), contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: maxHeight)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
            T(meta, .bodySm, tone: .mute).padding(.horizontal, Tokens.Space.xs)
        }
        .scaleEffect(shown ? 1 : 0.96)
        .opacity(shown ? 1 : 0)
        .onAppear { withAnimation(.gentle) { shown = true } }
    }
}

extension ImagePreview where Replace == EmptyView {
    init(image: UIImage, meta: String, maxHeight: CGFloat = 300) {
        self.init(image: image, meta: meta, maxHeight: maxHeight) { EmptyView() }
    }
}

// Round white button that sits over a preview (used for "replace photo").
struct ReplaceBadge: View {
    var body: some View {
        ZStack {
            Circle().fill(Tokens.Colors.onDark)
            Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 14, weight: .semibold)).foregroundStyle(Tokens.Colors.ink)
        }
        .frame(width: 36, height: 36)
    }
}

// Horizontal thumbnails for batch jobs — shared by Convert and Image Size.
struct ThumbStrip<Trailing: View>: View {
    let images: [PickedImage]
    let meta: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Tokens.Space.sm) {
                    ForEach(images) { img in
                        Image(uiImage: img.preview)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
                    }
                }
            }
            HStack {
                T(meta, .bodySm, tone: .mute)
                Spacer()
                trailing
            }
            .padding(.horizontal, Tokens.Space.xs)
        }
        .transition(.opacity)
    }
}

struct ResultStat { let label: String; let value: String; var tone: Tone = .default }

// Slides up once a job completes. Cobalt appears exactly once: on the check mark.
struct ResultSheet: View {
    let title: String
    let stats: [ResultStat]
    let filename: String
    let primaryTitle: String
    var primaryIcon: String = "square.and.arrow.down"
    let onPrimary: () async throws -> Void
    var shareURL: URL? = nil
    let onReset: () -> Void

    @State private var busy = false
    @State private var done = false
    @State private var error: String?
    @State private var shown = false

    var body: some View {
        ITCard(tone: .deep) {
            VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                HStack(spacing: Tokens.Space.md) {
                    ZStack {
                        Circle().fill(Tokens.Colors.primary)
                        Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    }
                    .frame(width: 36, height: 36)
                    T(title, .headingMd)
                }
                HStack(alignment: .top, spacing: Tokens.Space.lg) {
                    ForEach(stats.indices, id: \.self) { i in StatView(label: stats[i].label, value: stats[i].value, tone: stats[i].tone) }
                }
                .padding(.top, Tokens.Space.lg)
                .overlay(alignment: .top) { Rectangle().fill(Tokens.Colors.hairline).frame(height: 1) }
                T(filename, .caption, tone: .faint).lineLimit(1)
                VStack(spacing: Tokens.Space.sm) {
                    PillButton(title: done ? "Saved" : primaryTitle, icon: done ? nil : primaryIcon, size: .lg, loading: busy, disabled: done) {
                        Task {
                            busy = true
                            defer { busy = false }
                            do { try await onPrimary(); done = true } catch { self.error = error.localizedDescription }
                        }
                    }
                    if let shareURL {
                        ShareLink(item: shareURL) {
                            PillLabel(title: "Share", icon: "square.and.arrow.up", variant: .soft, size: .lg)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    PillButton(title: "Start over", variant: .ghost, action: onReset)
                }
            }
        }
        .offset(y: shown ? 0 : 24)
        .opacity(shown ? 1 : 0)
        .onAppear { withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { shown = true } }
        .alert("Could not save", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") { error = nil }
        } message: { Text(error ?? "") }
    }
}
