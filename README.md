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
flutter test           # widget, navigation, layout-regression and API-client tests
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
  theme/                    design tokens: colors, typography, spacing, shapes, motion, icons
  widgets/                  shared UI primitives (buttons, glass surfaces, fields, overlays, art)
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

### Discover flow (Figma "02 · Home & Discover")

Home carousel / **All brands** catalog (filter by home type) → **Choose a location** sheet (skipped for
single-project brands) → **project page** (gallery, compare strip, products) → **product page** (affordability
check against the buyer's income, gallery, financing, fees, docked "Scan seller QR"). Galleries show CMS media when
the API supplies `media`, otherwise clearly labelled sample photos, videos and drawn placeholders. Data the
spreadsheet hasn't supplied yet renders as a dashed "pending" note, never invented values.

## Release

Bump `version:` in `pubspec.yaml` (`1.0.0+N`), then:

```sh
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist   # uploads to App Store Connect
flutter build appbundle --release                                            # Play Console
```

Bundle ID / application ID: `com.raemulanlands.tahanan` (team `UZMK9VPGZ7`). Android release signing still needs a
keystore (`android/key.properties`, not committed).
