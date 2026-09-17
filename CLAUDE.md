# Image Tools (iOS, SwiftUI)

Native iOS app, SwiftUI, iOS 18+, no dependencies. Four on-device photo utilities, no server, no AI:
**Convert** (HEIC/JPG/PNG + photo→PDF), **Image Size** (resize, batch, fit-to-ratio, DPI),
**Compress** (quality slider with live size), **Blur** (brush that blurs what you paint, adjustable
strength and brush size). A 1:1 port of the Expo prototype in `../ImageTools_expo`; product research
lives in `docs/` (`aso/demand-report-2026-09-16.md` says why exactly these features).

## Scope rule — data-driven only

A feature ships only if a keyword cluster in `docs/aso/demand-report-2026-09-16.md` supports it with
**popularity > 40 in at least one of US/CA/AU/GB**. Section 5.3 there is the source of truth for what is
in, what was removed and why. Do not add "expected" or "nice" features without a row in that table.

## Build & run

Open `ImageTools.xcodeproj` in Xcode, pick a simulator or your iPhone, Run. From the CLI:

```bash
xcodebuild -project ImageTools.xcodeproj -scheme ImageTools -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build/DerivedData build
```

`project.yml` is the xcodegen spec the project was generated from. Xcode is the source of truth now:
add files in Xcode, and only run `xcodegen` if you also update `project.yml` (it overwrites the .xcodeproj).
Bundle id `com.imagetools.app`, team `NH5YK4W96C`, automatic signing.

## Layout

- `ImageTools/App` — `ImageToolsApp` + `RootView` (NavigationStack, `Tool` enum drives `navigationDestination`).
- `ImageTools/Design/Tokens.swift` — colours, type scale (`Typo` + `T` text view), radii, spacing, springs. Inter is bundled (`Resources/Fonts`, OFL); PostScript names are `Inter-Regular/-Medium/-SemiBold/-Bold`.
- `ImageTools/Design/Components` — `PillButton`/`PillLabel`, `ScaleButtonStyle`, `Chip`, `Segmented` (matchedGeometryEffect), `ITSlider` (tick haptic every 10 %), `NumberField`, `WrapLayout`, `ScreenScaffold` (scroll + sticky footer), `ToolHeader`, `EmptyPickerLabel`, `ImagePreview`, `ThumbStrip`, `ResultSheet`, `CropStage` (+ `CropModel`: drag/pinch inside a fixed-ratio frame, all math in image pixels).
- `ImageTools/Design/Motion.swift` — `.rise` / `.pop` transitions, `riseIn()` modifier, `Haptics`. Screens animate on state changes via `.animation(.gentle, value:)` so inserted/removed blocks use these transitions.
- `ImageTools/Engine` — `ImageEngine` (ImageIO decode with orientation, encode with DPI, resize, pad), `PDFMaker` (A4 pages, JPEG streams), `BlurRenderer` (Core Image blur + mask), `PickedImage` (PhotosPicker → bytes + preview), `Naming`, `Saver` (Photos add-only, temp file for share).
- `ImageTools/Features/<Tool>/<Tool>View.swift` — one screen per tool, state lives in the view.

## Design rules (Revolut-derived)

- Canvas is true black; the only other dark step is `surface` `#16181A`. No shadows — depth comes from those two steps and hairlines.
- Primary CTA is a **white pill with black text**. Cobalt `#494FDF` appears at most once per screen (featured card, result check mark).
- All buttons/chips are capsules; cards 20 pt; inputs 12 pt. Inter everywhere; display sizes use tight negative tracking.
- Motion: every tappable uses `ScaleButtonStyle` (spring to 0.97 + light haptic); sections use `SectionBlock` (fade + slide); previews `.pop`, results `.rise`; numbers that change use `.contentTransition(.numericText())`. Prefer springs.

## Gotchas

- Blur canvas = the photo itself (no letterboxing). Don't `.frame(w, h)` a ZStack and then `.offset` its children — the frame already centres, so the offset doubles on portrait photos and the brush lands away from the finger (day-two bug).
- Image Size "Fill · move photo" crops the full-resolution image with `CropModel.cropRect` (frame ratio, whole pixels). The first photo uses the user's framing; other photos in a batch are centre-cropped.
- `context(width:height:alpha:)` picks an RGBX context for opaque photos — ImageIO logs `AlphaPremulLast` errors and doubles memory otherwise.

- Never put `.ignoresSafeArea()` on a view inside `safeAreaInset` — it expands to the whole screen and covers the content (that was the blank-screen bug on day one).
- `PhotosPicker` bound to an array is multi-select; pass `maxSelectionCount: 1` where one photo is expected or it will not auto-dismiss.
- PDF: draw CGImages created from JPEG data, otherwise UIKit embeds raw pixels (12 MB instead of 2 MB).
- DPI is written by ImageIO from `kCGImagePropertyDPIWidth/Height` — JFIF, EXIF and TIFF resolution all come out consistent; no byte patching needed here.
- Output names: `image-tools-<tool>-<YYYY-MM-DD>[-<n>].<ext>` (`Naming`); `Saver.temporaryURL` writes the temp file under that name so the share sheet and Photos show it.
