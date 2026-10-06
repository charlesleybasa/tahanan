# Tahanan — Exact UI Design Tokens

Extracted from `native_ios_backup/Tahanan/DesignSystem/` (the shipped SwiftUI app), which was built from
`tahanan-design/` (the approved HTML prototype). Every value below is copied from source, not estimated.
The Flutter design system in `lib/theme/` must reproduce these values one-to-one.

Units: **pt** in iOS = **logical px** in Flutter (1:1). Design frame is **390 × 844** with a 54 pt status bar area.

---

## 1. Color

### 1.1 Appearance modes

| Mode  | Status | Notes |
|-------|--------|-------|
| Dark  | **Only mode.** | Native app forces `.preferredColorScheme(.dark)` at the root; `UIUserInterfaceStyle = Dark` in Info.plist. |
| Light | **Not designed.** | No light values exist in the design or the native app. Flutter ships `ThemeMode.dark` only. A light theme requires new designer-provided values; none are invented here. |

### 1.2 Brand

| Token    | Hex       | RGB              | Use |
|----------|-----------|------------------|-----|
| `night`  | `#08142A` | 8, 20, 42        | App ground, scaffold background |
| `navy`   | `#16305B` | 22, 48, 91       | Avatar gradient end, secondary surfaces |
| `blue`   | `#2E6BE6` | 46, 107, 230     | Roof arch, submitted tone, glow |
| `yellow` | `#FFC42E` | 255, 196, 46     | **Only** primary-action color, accents, focus |
| `orange` | `#F2622E` | 242, 98, 46      | Door, to-do tone, badges |
| `green`  | `#2FA96B` | 47, 169, 107     | Bush, accepted tone, toggles on |

### 1.3 Text

| Token         | Hex       | Use |
|---------------|-----------|-----|
| `text`        | `#F3F6FC` | Primary text, toast ground |
| `muted`       | `#A2B2CE` | Body copy, chevrons |
| `subtle`      | `#8C9DBC` | Secondary labels, counts, overlines |
| `label`       | `#AAB9D3` | Field labels, muted pill text |
| `placeholder` | `#7F91B2` | Input placeholders, version line |
| `soft`        | `#C9D4E8` | Segmented idle text, hero location |
| `softer`      | `#E2E8F3` | Filter chip idle text |
| `dim`         | `#6F82A6` | Tertiary |
| `tabIdle`     | `#8C9BB8` | Tab bar idle item |
| `ringIdle`    | `#5C6F93` | Idle progress dot |

### 1.4 Grounds

| Token       | Hex       | Use |
|-------------|-----------|-----|
| `ink`       | `#0B1A33` | Text/icons on yellow, chips on yellow |
| `deep`      | `#050D1C` | Deepest ground |
| `splash`    | `#071226` | Launch / splash background |
| `panel`     | `#0F2142` | Bottom sheet, card under photo |
| `panelDeep` | `#10223F` | Progress ring inner disc |
| `scanGround`| `#02060E` | Scanner ground, sheet scrim base |
| `navyLight` | `#1D3B6E` | Avatar gradient end |
| `tabGlass`  | `#0D1C38` @ 0.80 | Tab bar tint over blur |
| `checkboxIdleBorder` | `#767676` | Unchecked checkbox border |

### 1.5 Status pills (background / foreground)

| Tone        | Background            | Foreground |
|-------------|-----------------------|------------|
| `accepted`  | green @ 0.18          | `#62D69C` |
| `reviewed`  | yellow @ 0.16         | `#FFC94A` |
| `submitted` | blue @ 0.24           | `#93B4FF` |
| `todo`      | orange @ 0.17         | `#FF9468` |
| `muted`     | white @ 0.08          | `label` `#AAB9D3` |

### 1.6 White alphas (translucency scale)

| Alpha | Use |
|-------|-----|
| 0.055 | Glass fill |
| 0.06  | Field fill, ghost button fill, +63 box |
| 0.07  | Icon button fill, row divider, neutral icon tile |
| 0.08  | Summary line divider, muted pill |
| 0.09  | Glass border |
| 0.10  | Tab bar border, progress track |
| 0.12  | Icon button border, sheet top stroke |
| 0.13  | Field border |
| 0.14  | Ghost border, chip idle border, card hairline |
| 0.18  | Toggle off track |
| 0.20  | Sheet handle |
| 0.22  | Journey card arch highlight |

### 1.7 Gradients

| Name | Definition |
|------|------------|
| Roof gradient | `linear-gradient(160deg, #4A85F5 0%, #2E6BE6 45%, #2459C9 100%)` — begin (0.329, 0.03), end (0.671, 0.97) in unit space |
| Avatar gradient | `linear-gradient(135deg, #3D7BF0, #1D3B6E)` topLeft → bottomRight |
| App background | Base `#08142A` + `radial-gradient(70% 40% at -10% 105%, yellow@.09 → transparent 60%)` + `radial-gradient(110% 55% at 85% -8%, blue@.34 → transparent 62%)` (elliptical; radii are fractions of width/height) |
| Brand card scrim | night @ 0 at 30% → night @ .55 at 55% → night @ .96 at 100%, top → bottom |
| Brand hero scrim | night @ .45 at 0% → @ 0 at 26% → @ .2 at 55% → @ 1 at 100% |
| Bottom CTA fade | night @ 0 at 0% → night at 35% |
| Progress stripes | `repeating-linear-gradient(-45deg, ink@.95 0 6px, ink@.72 6px 12px)` |

---

## 2. Typography

Bundled fonts (OFL): **Outfit** (headlines, numbers), **Manrope** (UI, body), **JetBrains Mono** (codes).

| Family | Weights bundled |
|--------|-----------------|
| Outfit | 400 Regular, 500 Medium, 600 SemiBold, 700 Bold (800 → 700) |
| Manrope | 400, 500, 600, 700, 800 ExtraBold |
| JetBrains Mono | 500 Medium (regular/medium), 600 SemiBold (semibold and up) |

Letter-spacing is CSS `em` × size (points). SwiftUI `lineSpacing` adds extra leading; Flutter `height` = (size + lineSpacing) / size measured against the font's natural line height — the Flutter port uses the explicit `height` given below.

### 2.1 Named styles

| Style | Family / weight | Size | Tracking | Line height | Color |
|-------|-----------------|------|----------|-------------|-------|
| `h1(size)` | Outfit 600 | per screen: 32, 34, 42, 44 | −0.035em | 1.02 (CSS); native uses font default | `text` |
| `eyebrow` | Manrope 800, UPPERCASE | 12 | +0.16em (1.92) | default | `yellow` |
| `sectionTitle` | Outfit 600 | 20 | −0.015em (−0.3) | default | `text` |
| `fieldLabel` | Manrope 700 | 13 | 0 | default | `label` |
| `mutedBody` | Manrope 400 | 15 | 0 | 1.55 (lineSpacing = 0.3 × size) | `muted` |
| `overline` | Manrope 800, UPPERCASE | 12 | +0.1em (1.2) | default | `subtle` |
| Row title | Manrope 800 | 15 (14 compact) | 0 | default | `text` |
| Row subtitle | Manrope 400 | 13 (12 compact) | 0 | default | `muted` / `subtle` |
| Row overline | Manrope 700 | 12 | 0 | default | `subtle` |
| Status pill | Manrope 800 | 12 | 0 | — | per tone |
| Pill mono | JetBrains Mono 600 | 12 | 0 | — | per tone |
| Primary button | Manrope 800 | 16 | 0 | — | `ink` |
| Ghost button | Manrope 700 | 15 | 0 | — | `text` |
| Link button | Manrope 700 | 14 | 0 | — | `yellow` |
| Field input | Manrope 400 | 16 | 0 | — | `text` |
| Field input mono | JetBrains Mono 500 | 16 | 0 | — | `text` |
| OTP digit | JetBrains Mono 600 (fixed) | 24 | 0 | — | `text` |
| Filter chip | Manrope 700 | 14 | 0 | — | `softer` / `ink` |
| Segmented | Manrope 800 | 14 | 0 | — | `soft` / `ink` |
| Tab item | Manrope 800 | 11 | 0 | — | `tabIdle` / `yellow` |
| Toast | Manrope 800 | 14 | 0 | — | `ink` |
| Lockup wordmark | Outfit 700 | 20 | −0.02em | — | `text` |
| Summary key / value | Manrope 400 / 800 | 14 | 0 | — | `muted` / `text` |

### 2.2 Home screen specifics

| Element | Font | Size | Tracking |
|---------|------|------|----------|
| Greeting "Magandang umaga," | Manrope 600 | 13 | 0 · `muted` |
| First name | Outfit 600 | 19 | −0.19 |
| Headline "Find your / tahanan." | `h1` | 42 | −1.47 · second line `yellow` |
| Brand count | Manrope 700 | 13 | `subtle` |
| Brand card name | Outfit 600 | 24 | −0.48 |
| "STARTS AT" | Manrope 700 | 11 | `muted` |
| Brand price | Outfit 700 | 20 | `yellow` |
| Journey eyebrow | Manrope 800 | 12 | +1.2 |
| Journey unit code | JetBrains Mono 600 | 11 | — |
| Journey title | Outfit 600 | 27 | −0.675 |
| Journey subtitle | Manrope 600 | 13 | opacity .78 |
| Journey stage labels | Manrope 800, UPPERCASE | 10 | +0.4 · opacity .7 |
| Journey CTA | Manrope 800 | 14 | `text` |
| "See all" | Manrope 800 | 13 | `yellow` |
| Transaction amount | Outfit 700 | 15 | `text` |

### 2.3 Dynamic Type

Native scales every text style with Dynamic Type (capped at `xxxLarge`) using these anchors:
≥34 largeTitle · 26–33 title · 20–25 title3 · 16–19 body · 14–15 subheadline · 12–13 footnote · <12 caption.
Splash and onboarding canvases use **fixed** sizes. Flutter: honour `MediaQuery.textScaler`, clamped to 1.35 (≈ xxxLarge), and use unscaled text inside the 390 × 844 canvas screens.

---

## 3. Layout

### 3.1 Spacing

| Token | Value |
|-------|-------|
| Gutter (most screens) | 20 |
| Auth gutter | 24 |
| Below status bar (content top inset inside safe area) | 2 |
| Tab bar clearance (scroll bottom padding) | 96 (+ bottom safe area) |
| Default scroll bottom padding | 40 |
| Minimum touch target | 44 |
| Section spacing on Home | 26 (headline, section titles), 22 (journey), 14 (carousel, link row), 6 (transactions card) |

### 3.2 Corner radii

| Token | Value | Shape |
|-------|-------|-------|
| input | 16 | Fields, +63 box |
| OTP box | 14 | |
| icon tile | 14 | 42 × 42 |
| card | 22 | Glass cards, link row |
| cardLarge | 26 | |
| hero / journey | 28 | Journey card (continuous) |
| sheet | 32 | Top corners only |
| tab bar | 37 | 74 tall pill |
| segmented | 27 | 54 tall pill |
| capsule | height / 2 | Buttons, pills, chips |
| Arch | top corners = width / 2 (full semicircle), bottom = 18 default (28 on brand card, 12 on location thumb, 0 on journey highlight) | |

iOS `.continuous` (squircle) corners are used on glass cards, tab bar and journey card. Flutter equivalent: `RoundedSuperellipseBorder` / `ClipRSuperellipse`, which Flutter built to match iOS continuous corners (`squircle()` in `lib/theme/shapes.dart`). `ContinuousRectangleBorder` does **not** match.

### 3.3 Component dimensions

| Component | Size / padding |
|-----------|----------------|
| Primary button | height 56, leading pad 24, trailing pad (56−44)/2 = 6, chip 44 Ø, icon 20 |
| Ghost button | height 52, icon 18, gap 10 |
| Icon button | 44 Ø, icon 20 |
| Field | height 56, horizontal pad 16 (12 after leading icon), label gap 8 |
| Focus ring | 4 pt outer ring, yellow @ .12, radius + 4 |
| OTP box | 46 × 58, gap 8 |
| Checkbox | 22, radius 4, touch 44 |
| Toggle | 52 × 32 track, 26 thumb, 3 inset |
| Status pill | height 26 (22 compact), horizontal pad 10, icon 13, gap 6 |
| Icon tile | 42, radius 14, icon 20 |
| Row | min height 64, padding 12 vertical / 16 horizontal, gap 14 |
| Row divider | 1 pt, white .07, inset 16 |
| Filter chip | height 40, horizontal pad 16 |
| Segmented pill | height 54, inner pad 5, gap 4, badge min 20 |
| Avatar (Home) | 46 Ø, 2 pt yellow @ .8 ring, initials Outfit 700 16 |
| Notification dot | 8 Ø yellow, 2 pt `panel` stroke, inset top 10 / right 11 |
| Brand arch card | 252 × 340, gap 14, pill top 74, content pad 20 / bottom 18, chip 44 |
| Journey card | padding 20, end caps 46 Ø (icon 22), track height 12, dots 8, labels inset 50, CTA 52 tall (chip 40) |
| Journey arch highlight | 170 × 200, offset (+40, −60) from top-right, white .22 |
| Tab bar | height 74, outer inset 14, bottom 20, inner pad 8, item 62 × 58, icon 22, gap 4 |
| Scan button | 66 Ø, 5 pt ink border, raised −20, pulse ring 76 Ø |
| Toast | top 56 (2 below safe area), pad 12 / 18 / 12, icon disc 28 (icon 16), gap 10 |
| Bottom sheet | handle 44 × 5 (+18 below), pad top 12 / horizontal 22 / bottom 34 |
| Tahanan mark grid | 104 × 100: sun (50,0) 54²; roof (0,18) 70 × 82 r 35/5; door (22,62) 26 × 38 r 13/0; bush (81,77) 19 × 23 r 9.5/3 |

### 3.4 Shadows

SwiftUI `shadow(radius: r)` is a Gaussian with σ ≈ r/2; Flutter `BoxShadow.blurRadius` is 2σ. **Flutter blurRadius = SwiftUI radius**, offset copied as-is.

| Element | Color | Blur | Offset (x, y) |
|---------|-------|------|---------------|
| Primary button | yellow @ .45 | 12 | (0, 14) |
| Tab bar | black @ .60 | 22 | (0, 24) |
| Scan button | yellow @ .50 | 12 | (0, 14) |
| Brand arch card | black @ .60 | 24 | (0, 30) |
| Toast | black @ .50 | 16 | (0, 20) |
| Toggle thumb | black @ .30 | 3 | (0, 2) |
| Profile avatar | blue @ .60 | 20 | (0, 20) |
| Scan line | yellow @ .65 blur 11, yellow @ .40 blur 5.5 | | (0, 0) |

### 3.5 Blur (materials)

| Surface | Native | Flutter |
|---------|--------|---------|
| Tab bar | `.ultraThinMaterial` (dark) + `#0D1C38` @ .8 | `BackdropFilter(sigma 20)` + same tint |
| Brand card location pill | `.ultraThinMaterial` + night @ .6 | `BackdropFilter(sigma 20)` + same tint |
| Icon button `blur: true` | `.ultraThinMaterial` + fill | `BackdropFilter(sigma 20)` + fill |
| Sheet scrim | `#02060E` @ .62 + material @ .35 | scrim + `BackdropFilter(sigma 6)` |

---

## 4. Motion

### 4.1 Curves (CSS cubic-bezier)

| Name | Control points | Use |
|------|----------------|-----|
| standard | (.2, .8, .2, 1) | Screen enter, rise, toast |
| sheet | (.2, .9, .2, 1) | Bottom sheet slide-up |
| pop | (.2, .9, .3, 1.35) | Pop-in scale (overshoots) |
| morph | (.77, 0, .175, 1) | Onboarding morph |
| upbar | (.4, 0, .2, 1) | Journey progress fill |
| ease-in-out | (.42, 0, .58, 1) | Ambient loops |
| ease | (.25, .1, .25, 1) | |
| ease-out | (0, 0, .58, 1) | Pulse ring |

### 4.2 Durations and transitions

| Interaction | Spec |
|-------------|------|
| Screen enter (`.scr`) | 0.75 s standard: opacity 0 → 1, scale 1.035 → 1, blur 10 → 0. Outgoing screen removed immediately. |
| Tab → tab switch | 0.18 s ease-out opacity on incoming; outgoing removed immediately; **no** rise replay. Same-tab tap is a no-op. |
| Plain-enter screens | splash, location story, forgot password — no screen transition (they animate their own content). |
| Rise (`.rise.dN`) | 0.85 s standard: translateY 26 → 0, blur 6 → 0, opacity 0 → 1. Stagger delays d0–d8: 0, .07, .14, .21, .28, .36, .44, .52, .60 s. Disabled by Reduce Motion (offset/blur), opacity still fades. |
| Fade in | 0.4 s ease-in-out |
| Pop | 0.7 s pop curve, scale 0 → 1 + opacity |
| Press (`.press:active`) | scale 0.97, 0.15 s ease-out |
| Primary dimmed | opacity .55, 0.3 s ease-in-out |
| Field focus | 0.2 s ease-in-out (border, fill yellow @ .05, ring) |
| Chip selection | 0.2 s ease-in-out |
| Segmented selection | 0.3 s ease-in-out |
| Tab item color | 0.25 s ease-in-out |
| Toggle | 0.25 s ease-in-out |
| Bottom sheet | scrim 0.4 s ease-in-out; panel 0.55 s sheet curve from +900; drag > 80 dismisses |
| Toast (`toastA`) | 2.4 s: 0–12% drop in (y −16 → 0, opacity 0 → 1, standard); hold to 82%; fade up (y 0 → −10, opacity → 0). Auto-dismiss at 2.5 s. |
| Ken Burns | 16 s ease-in-out, alternate forever: scale 1.06 → 1.22 at anchor (0.6, 0.4), translate −2% × scale |
| Float | 6 s period, translateY 0 → −12 → 0, ease-in-out per half |
| Glow pulse | 2.5 s ease-in-out alternate: opacity .75 ↔ 1, scale 1 ↔ 1.08 |
| Pulse ring | 2.2 s ease-out loop: scale .92 → 1.55, opacity .8 → 0 |
| Spinner | 0.9 s linear rotation; head = top quarter arc (trim .625–.875) |
| Caret | 1 s steps blink (0.5 s on/off), 2 × 26 yellow |
| Scan line | 2.4 s ease-in-out ping-pong between 8% and 88% height, inset 18, thickness 3 |
| Corner breathing | 1.2 s ease-in-out alternate, scale 1 ↔ .96 |
| Journey progress | width 0 → 38%, 1.6 s upbar curve, 0.6 s delay |
| Agent reply (demo) | 1.8 s after send; 2.2 s after new ticket |

### 4.3 Haptics

Success haptic on payment success (`PaidView`). Selection changes use system defaults.

---

## 5. Iconography

44 line icons, 24 × 24 viewBox, stroke 1.8, round caps, round joins, `currentColor`. `play` is filled.
Exact SVG path data lives in `lib/theme/icons.dart` (copied verbatim from `Icons.swift`). Stroke scales with icon size (1.8 × size / 24). No Material or SF Symbols substitutes.

## 6. Imagery

Photos: `photoPH`, `photoPP`, `photoHTS`, `photoPV`, `photoRow`, `photoInterior` — `object-fit: cover`.
App icon 1024², launch background `#071226`.

## 7. Platform notes for the Flutter port

- Text line height: SwiftUI uses each font's own metrics (Outfit 1.26, Manrope 1.366, JetBrains Mono 1.32 × size).
  Flutter matches this only when `height` is null **and** nothing inherited sets it — the root `DefaultTextStyle`
  uses `inherit: false` because Material's default body style carries `height: 1.43`.
- Scroll feel: bouncing physics, no overscroll glow, no scrollbars on both platforms.
- Upgrade from the native app: same bundle ID, so iOS restores the SwiftUI scene session. The Flutter
  `AppDelegate` replaces it (requires `UIApplicationSupportsMultipleScenes = true` and iOS 17).
