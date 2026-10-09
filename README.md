# Tahanan — buyer app (Flutter)

The Tahanan by Raemulan Lands buyer app for iOS and Android. Buyers browse brands → locations → products, scan a
seller's QR to book a consultation, pay the fee, and track their housing loan application, requirements and
support tickets.

The UI is complete and matches the Figma file *Tahanan — App Design*. Data comes from repository interfaces with
two implementations: bundled mock JSON (default) and a REST client that is ready to point at the backend.
**To connect the backend, see [docs/BACKEND_INTEGRATION.md](docs/BACKEND_INTEGRATION.md).**

## Requirements

| Tool | Version |
| --- | --- |
| Flutter | 3.47 (stable) · Dart 3.13 |
| Xcode | 26+ (iOS 17.0 deployment target, Swift Package Manager — no CocoaPods) |
| Android | SDK 36, NDK 28.2.13676358, JDK 17 |

Swift Package Manager is enabled in `pubspec.yaml` (`flutter: config: enable-swift-package-manager: true`).

## Run

```sh
flutter pub get
flutter run                                   # mock data (assets/data/*.json), any login works
flutter run --dart-define-from-file=env/dev.json   # against the API in env/dev.json
```

| Define | Default | Meaning |
| --- | --- | --- |
| `USE_MOCK_DATA` | `true` | `false` switches every repository to HTTP |
| `API_BASE_URL` | `http://localhost:3100/api/v1` | Versioned REST root (no trailing slash) |
| `START` | — | Debug only: open a screen directly, e.g. `catalog`, `project`, `product`, `tradizo1br`, `pending`, `application`, `help`, `ticket`, `about` (any `ScreenKind` name) |

Android emulator: use `http://10.0.2.2:3100/api/v1` to reach a server on your Mac.

## Check

```sh
flutter analyze        # lints in analysis_options.yaml; must be clean
flutter test           # widget, navigation, layout-regression, adaptive-layout and API-client tests
```

CI config is ready in `docs/ci/flutter.yml`; move it to `.github/workflows/` to run analyze and tests on every push (pushing workflows needs a token with the `workflow` scope).

## Project structure

```
lib/
  main.dart                 app entry, root text style, debug start screen
  app/
    router.dart             Screen / ScreenKind state machine (no Navigator routes except the media viewer)
    root_view.dart          screen switcher, floating tab bar, bottom sheet, toast, deep links
    app_state.dart          app-wide state (ChangeNotifier via provider) + `run()` for backend calls
    navigation.dart         context.go(Screen)
  data/
    repositories.dart       repository interfaces + mock and HTTP implementations
    api/api_client.dart     JSON/HTTP client: bearer auth, { data } envelope, errors, 401 → refresh → retry
    api/api_config.dart     --dart-define configuration
  models/models.dart        immutable models with fromJson (the API contract)
  theme/                    design tokens: colors, typography, spacing, layout (breakpoints), shapes, motion, icons
  widgets/                  shared UI primitives (buttons, glass surfaces, fields, overlays, art, adaptive)
  features/<area>/          screens per area: auth, home, discover, booking, application, spouse, help, profile, …
assets/data/*.json          mock data = sample API responses
specs/exact_ui_design_tokens.md   the token spec the theme implements
native_ios_backup/          the original SwiftUI app (reference only, not built)
```

### Conventions

- Screens read state with `context.watch<AppState>()` and navigate with `context.go(Screen…)`.
- Backend calls from screens go through `state.run((r) => r.<repo>.<call>(…))`: it returns `true`/`false` and
  turns `ApiException`s into a toast. Flows stay optimistic as in the design.
- Fidelity rules (see `specs/exact_ui_design_tokens.md` §7): use `IText` for wrapping text (iOS line breaking),
  `squircle()` / `ClipRSuperellipse` for continuous corners, borders as foreground decorations.
- Every remaining backend touch point is marked `// TODO: API`.

### Discover flow

Home carousel / **All brands** catalog (filter by home type) → **Choose a location** sheet (skipped for
single-project brands) → **brand location page** (arch hero with the starting price, facts, availability, About the
project, gallery, **Available units** ladder, How to get there, Homeowner stories, "Book your home") → **unit page**
(price, specs, income gauge, gallery, "What you pay" receipt, next steps, docked "Scan seller QR"). Galleries show
CMS media when the API supplies `media`, otherwise clearly labelled sample media. Sections whose data the API hasn't
supplied are hidden or shown as a dashed "pending" note, never invented values.

### Booking flow

Scan a seller's **booking QR** → the unit page in booking mode ("From seller QR", "Proceed booking") → Terms &
Privacy prompt (scroll-gated) → **1 · Attach ID & Selfie** (`id_capture_screen.dart`: ID type → capture or upload
→ selfie → review) → **2 · Pay** (`booking_flow.dart`: method → reminders sheet → card form or InstaPay QR) →
**3 · Payment successful** → **Getting started** sheet → **Edit application** (the Customer Information Form,
`application_edit_screen.dart`, fields defined once in `application_form.dart`).

### Adaptive layout (phones, foldables, tablets)

Rules live in `lib/theme/layout.dart` and `lib/widgets/adaptive.dart`:

| Width | Devices | Behaviour |
| --- | --- | --- |
| < 600 dp | phones, folded foldables (Galaxy Z Fold cover, Pixel Fold outer) | the 390 pt design, edge to edge |
| 600–759 dp | unfolded Galaxy Z Fold, small tablets | content in a centered 600 dp column; bars, sheets and the tab bar cap at 560 dp |
| ≥ 760 dp | tablets, Pixel Fold unfolded | brand and unit pages split into two panes (hero + facts / details) |
| vertical hinge | Surface Duo spanned, book-style fold half-open | single-column screens stay on one screen (`DisplayFeatureSubScreen`); two-pane pages put one pane on each side |

- Build new screens on `ScreenScroll` (centred and capped automatically) and `BottomCTABar`.
- Use `AdaptivePanes` when a screen has two natural halves; check `AdaptivePanes.splits(context)` first.
- Never hard-code a screen width; use `LayoutBuilder` or `Layout.width(context)`.
- `test/adaptive_layout_test.dart` renders every screen on iPhone SE, iPhone 17 Pro, Galaxy Z Fold (cover and
  unfolded), Pixel Fold, iPad 11" and Surface Duo (with hinge) and fails on any overflow. Add new screens to it.

### Motion

Entrances use `Reveal` (fade + 18 pt rise, 0.5 s, staggered ≤ 0.6 s) and one-shot intros (`ArchHero`, `CountUp`,
bars). No blur in entrances on discover pages (expensive on low-end Android). Every intro is skipped on revisits
(`SkipEntrance`) and when the OS asks for reduced motion (`reduceMotion`).

## Release

Bump `version:` in `pubspec.yaml` (`1.0.0+N`), then:

```sh
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist   # uploads to App Store Connect
flutter build appbundle --release                                            # Play Console
```

Bundle ID / application ID: `com.raemulanlands.tahanan` (team `UZMK9VPGZ7`). Android release signing still needs a
keystore (`android/key.properties`, not committed).
