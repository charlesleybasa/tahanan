# Tahanan Buyers App — design handoff

This folder is the approved design for the Tahanan buyers app (by Raemulan Lands / Homeful) and its admin dashboard.
Build the real app to match it. The design files are the source of truth for layout, copy, colors, spacing and motion.

## Start here: the runnable prototype

`prototype/index.html` opens every screen in a normal browser, with the exact markup, CSS and animations from the design canvas (React renders the same templates; no build step). `prototype/Main.html` plays the whole buyer app from the splash. Use these as the visual and motion reference: when you build a screen, open the matching prototype page side by side and match it — timing, easing, spacing and copy. Serve the folder with any static server (e.g. `npx serve prototype`) or open the files directly; fonts load from Google Fonts.

## What's in here

- `design/Main.dc.html` — the full buyer app as one interactive prototype (splash → onboarding → auth → home → slides → scan → booking → payment → docs → profile → help). It needs the design runtime to play, so read it as HTML + a `class Component` at the bottom whose `renderVals()` holds all state, data and flow logic.
- `design/buyer/B01–B30` — the same prototype opened on one screen each (the `start` value in each file's script says which).
- `design/buyer/Onboarding-Cinematic.dc.html` — the morphing onboarding (the 5 logo shapes morph between scenes; geometry per scene is in the `GEO` object).
- `design/buyer/S00–S08` — Complete spouse details flow (scan ID → 4 steps → review → done, or invite spouse).
- `design/admin/` — admin web dashboard (users, roles, tickets + chat, project knowledge editor, requirements).
- `design/brand/App-Icon-Motion.dc.html` — app icon, splash storyboard, tokens.
- `assets/` — project facade photos taken from the client's sign-off sheet.

Markup notes: `{{x}}` = value from `renderVals()`, `<sc-if value>` = conditional, `<sc-for list as>` = loop, `[[...]]` macros are already expanded. Inline styles hold the exact values — copy them, don't round.

## Design tokens

- Colors: Night `#08142A` (app ground), Navy `#16305B`, Blue `#2E6BE6`, Yellow `#FFC42E` (the only primary-action color), Orange `#F2622E`, Green `#2FA96B`. Text `#F3F6FC`, muted `#A2B2CE`, subtle `#8C9DBC`.
- Glass card: `rgba(255,255,255,.055)` + 1px `rgba(255,255,255,.09)` border + 18px backdrop blur.
- Fonts: Outfit (headlines, numbers), Manrope (UI/body), JetBrains Mono (codes like `CAV-PHC-03-B12-L07`, IDs, references).
- Radii: buttons 999, cards 22–28, inputs 16, arch images `W/2 W/2 18–28 18–28` (the brand arch motif).
- Status colors: Submitted blue, Reviewed yellow, Accepted green, To upload / Needs remedy orange.
- Touch targets ≥ 44px. No fake status bar — leave ~54px top safe area.

## Motion

- Screen enter: fade + scale 1.035→1 + blur 10→0, 750ms, cubic-bezier(.2,.8,.2,1).
- Content "rise": translateY 26px + blur 6px → 0, staggered 70ms.
- Photos: slow Ken Burns zoom (14–16s alternate).
- Splash (4.4s): roof arch scales up from bottom → sun rises behind → door + bush pop → "Tahanan" letters rise → blur-out. Timings in the `.sp-*` CSS in Main.
- Onboarding morph: shared elements animate left/top/size/radius over 1.25s cubic-bezier(.77,0,.175,1), staggered per shape; headline words rise from behind a mask.
- Project slides: story-style, auto-advance every 6s with a yellow progress bar.

## Requirements to implement (from the brief)

Buyer app: Supabase Auth login, forgot password (email OTP/link + reset), API token that expires every 3 hours (silent refresh), sign-up (name, email, mobile → saved as a Lead), Home (project knowledge slides, link existing account, transactions), QR scan from Funnel/Seller app → Booking page or Payment page, personal info (personal, spouse, co-borrower, AIF), requirements upload + statuses (Submitted / Reviewed / Accepted), profile (selfie, email, mobile, Homeful ID), security (change/forgot password, biometric login toggle), email verification with deep-link callback, change email/mobile with verification, About Homeful (privacy, terms), tickets with categories and chat.

Admin: auth + role-based access, users (count, add, edit, delete, activate/deactivate), ticket categories + tickets + chat, project knowledge (Brand → Locations → per-location slides and gallery), requirements, requirement types, statuses.

## Real project data

Brands, locations, TCP, floor/lot area, amortization and GMI are in the `BRANDS` array in `_buyer-logic-reference.js` (from the client sheet). Names like Maria Santos, tickets and admin user counts are sample data.
