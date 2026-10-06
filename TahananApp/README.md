# Tahanan Buyers App (iOS)

SwiftUI app built from `../tahanan-design` (iOS 17+, Observation, no third-party UI libraries).

## Run

```bash
xcodegen generate
open Tahanan.xcodeproj
```

- `Config.xcconfig` (gitignored, copied from `Config.example.xcconfig`) holds `USE_MOCK_DATA`, Supabase and API values.
- Debug builds accept `-start <screen>` (home, brand, loc, scan, booking, payment, paid, application, spouse, profile, account, security, about, help, ticket, newticket, login, signup, welcome, forgot, gallery) to open a screen directly.
- Debug builds: long-press the version line on Profile to open the component gallery.

## Demo data

All data comes from `Tahanan/MockData/JSON/*.json` through repository protocols in `MockData/Repositories.swift`.
Brand, location, TCP, area, amortization and GMI values are copied from `_buyer-logic-reference.js`.
Login accepts any email and password. Every backend call site is marked `// TODO: API`.

## TestFlight

```bash
scripts/testflight.sh
```

## Differences from the prototype

- Navigation uses the prototype's screen state machine with its enter transition (fade, scale, blur) instead of NavigationStack pushes.
- Supabase SDK is not linked yet; `AuthService` has a mock implementation and the session/refresh logic (Keychain, 3-hour refresh, foreground refresh, send to Login on failure) runs against it.
- Email-link verification returns through the `tahanan://auth/verify-email` URL scheme. Universal links need an associated domain.
- Multi-line headline leading is SwiftUI's default for Outfit, slightly looser than CSS `line-height: 1.02`.
- Box shadows with negative spread are approximated with lower opacity.
- The video slide's play button, Notifications bell, "See all", Save (heart), Booking "Edit", Resend, chat attach and the co-borrower / AIF / personal-details CTAs have no destination in the design and do nothing.
- The Profile settings gear opens Account details.
- Project photos are the low-resolution images from the sign-off sheet.
