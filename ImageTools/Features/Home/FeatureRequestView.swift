import SwiftUI

/// The candidate list is not a wishlist — every row is a keyword cluster the App Store research
/// measured (`docs/aso/metadata-us-2026-09-26.md`). Votes here tell us which of those clusters our
/// own users actually want, which is the half the keyword data cannot answer.
struct FeatureIdea: Identifiable {
    let id: String
    let title: String
    let detail: String
}

let featureIdeas: [FeatureIdea] = [
    .init(id: "scan_to_pdf", title: "Scan documents with the camera",
          detail: "Shoot a page and get a straightened PDF"),
    .init(id: "remove_background", title: "Remove the background",
          detail: "Cut the subject out, save as transparent PNG"),
    .init(id: "erase_objects", title: "Erase objects from a photo",
          detail: "Paint over something and make it disappear"),
    .init(id: "enhance", title: "Enhance and upscale",
          detail: "Sharpen an old or low-resolution photo"),
    .init(id: "passport_photo", title: "Passport and ID photo sizes",
          detail: "Official dimensions for any country"),
    .init(id: "pixelate_brush", title: "Pixelate brush",
          detail: "A mosaic brush next to the blur one"),
    .init(id: "watermark", title: "Add a watermark",
          detail: "Your text or logo over a photo"),
    .init(id: "exif", title: "See and strip photo data",
          detail: "Camera, date and location stored in a file"),
]

struct FeatureRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var picked: Set<String> = []
    @State private var sent = false

    var body: some View {
        ScreenScaffold(scroll: !sent) {
            if sent {
                VStack(spacing: Tokens.Space.xl) {
                    IconCircle(systemName: "checkmark", size: 64, tone: .ink)
                    VStack(spacing: Tokens.Space.xs) {
                        T("Thank you", .headingLg)
                        T("We build what gets asked for most.", .bodyMd, tone: .mute)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, Tokens.Space.xxxl * 2)
                .transition(.pop)
            } else {
                VStack(alignment: .leading, spacing: Tokens.Space.md) {
                    T("Request a feature", .headingLg)
                    T("Pick everything you would use. Nothing else is sent.", .bodyMd, tone: .mute)
                }
                .padding(.top, Tokens.Space.lg)

                VStack(spacing: Tokens.Space.sm) {
                    ForEach(Array(featureIdeas.enumerated()), id: \.element.id) { i, idea in
                        row(idea).riseIn(delay: 0.04 * Double(i))
                    }
                }
            }
        } footer: {
            if sent {
                PillButton(title: "Done", size: .lg) { dismiss() }
            } else {
                PillButton(title: picked.isEmpty ? "Pick at least one" : "Send \(picked.count)",
                           size: .lg, disabled: picked.isEmpty) {
                    Analytics.featureRequested(featureIdeas.map(\.id).filter(picked.contains))
                    Haptics.success()
                    withAnimation(.gentle) { sent = true }
                }
            }
        }
        .onAppear { Analytics.featureRequestOpened() }
    }

    private func row(_ idea: FeatureIdea) -> some View {
        let on = picked.contains(idea.id)
        return Button {
            Haptics.select()
            withAnimation(.snappy) { _ = on ? picked.remove(idea.id) : picked.insert(idea.id).memberAfterInsert }
        } label: {
            HStack(spacing: Tokens.Space.lg) {
                VStack(alignment: .leading, spacing: 2) {
                    T(idea.title, .bodyMdBold)
                    T(idea.detail, .bodySm, tone: .mute)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    Circle().stroke(on ? Color.clear : Tokens.Colors.hairline, lineWidth: 1)
                    if on {
                        Circle().fill(Tokens.Colors.primary)
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                    }
                }
                .frame(width: 26, height: 26)
            }
            .padding(Tokens.Space.lg)
            .background(RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous).fill(Tokens.Colors.surface))
        }
        .buttonStyle(ScaleButtonStyle(scaleTo: 0.985))
    }
}
