# Backend integration

The app is ready to talk to a REST API. Every screen already reads data from repository interfaces in
`lib/data/repositories.dart`, and each interface has an HTTP implementation that calls the endpoints below. To
connect the backend:

1. Implement (or map) the endpoints in this document on the server. JSON field names must match the models in
   `lib/models/models.dart`. The files in `assets/data/` are complete sample responses.
2. Run the app with the API switched on:

   ```sh
   flutter run --dart-define-from-file=env/dev.json
   # or
   flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=https://host/api/v1
   ```

3. Fill in the remaining `// TODO: API` items listed at the end. These are behaviours the design doesn't cover
   yet, such as persistent token storage and the payment provider hand-off.

`test/api_test.dart` serves the sample files through a fake server and checks the whole HTTP layer: parsing, the
bearer token, the `{ "data": … }` envelope, error messages, and refresh-then-retry on 401. Run it after any
contract change.

## Conventions

| Topic | Contract |
| --- | --- |
| Base URL | `API_BASE_URL`, e.g. `https://cms.example.com/api/v1`. Paths below are relative to it. |
| Format | JSON, UTF-8. Responses may be the bare payload **or** wrapped as `{ "data": <payload> }`. Both work. |
| Auth | `Authorization: Bearer <accessToken>` on every call after sign-in. |
| Errors | Non-2xx with `{ "error": { "message": "…" } }`, `{ "error": "…" }` or `{ "message": "…" }`. The message is shown to the buyer as a toast, so keep it human-readable. |
| 401 | The client calls `POST /auth/refresh` once, then retries the request. If the refresh fails, the session is cleared. |
| Money | Catalog prices (`from`, `tcp`, `monthly`, `gmi`) are **numbers in PHP** and the app formats them. Buyer-side display strings (transactions, unit) are preformatted strings, as in the samples. |
| Images and video | Absolute `https` URLs. Brand `image` may be a URL. Bundled names such as `brands/terraces` are only used by the mock data. |
| Timeouts | 20 s per request (`ApiConfig.timeout`). |

## Endpoints

### Auth: `AuthRepository`

| Method | Path | Body | Response |
| --- | --- | --- | --- |
| POST | `/auth/sign-in` | `{ email, password }` | `{ accessToken, refreshToken }` |
| POST | `/auth/sign-up` | `{ name, email, mobile }` (new users are saved as Leads) | `{ accessToken, refreshToken }` |
| POST | `/auth/refresh` | `{ refreshToken }` | `{ accessToken, refreshToken? }` |
| POST | `/auth/sign-out` | — | 204 |
| POST | `/auth/password-reset` | `{ email }`. Email contains a link to `tahanan://auth/reset` | 204 |
| POST | `/me/password` | `{ currentPassword, newPassword }` | 204 |
| POST | `/me/email` | `{ email }`. Sends a code and a link to the new address | 204 |
| POST | `/me/email/verification-link` | —. Link returns via `tahanan://auth/verify-email` | 204 |
| POST | `/me/mobile` | `{ mobile }`. Sends an SMS OTP | 204 |
| POST | `/me/avatar` | multipart `file` (JPEG) | 204 or the profile |

Deep links already handled by the app (`lib/app/root_view.dart`): `tahanan://auth/verify-email` and
`tahanan://auth/reset`. The `tahanan` URL scheme is registered on iOS and Android.

### Catalog: `ProjectRepository` (public, no token needed)

| Method | Path | Response |
| --- | --- | --- |
| GET | `/brands` | `Brand[]`. Sample: `assets/data/brands.json` |

```jsonc
// Brand
{
  "id": "ph",
  "name": "Pasinaya Homes",
  "type": "RH 2-storey LOFT",          // product type line on the catalog card
  "group": "Rowhouse",                  // Rowhouse | Duplex | Condo | Cluster  (catalog filter chips)
  "from": 750000,                       // lowest TCP, PHP
  "projects": 4,                        // project/location count
  "image": "https://…/pasinaya-homes.jpg",
  "shots": [],                          // optional extra exterior photos (mock gallery only)
  "locations": [Location]               // optional; omit while the spreadsheet hasn't named them → "pending" UI
}
// Location
{
  "name": "PH Naic",
  "area": "Naic, Cavite",               // optional
  "from": 750000,
  "products": [Product],                // optional; omit and send "productCount" when only the count is known
  "productCount": 2,
  "media": [Media],                     // optional project gallery
  "info": ProjectInfo                   // optional → the page hides each missing section
}
// ProjectInfo (location page: About, availability, How to get there, Homeowner stories). Every field is optional.
{
  "description": "Pasinaya Homes is an exclusive gated community…",
  "highlights": ["0 equity", "No downpayment", "Gated community"],
  "sold": 100, "remaining": 50,         // both needed for the availability bar
  "address": "Naic, Cavite",
  "travel": [{ "value": "30 min", "label": "From Manila" }],
  "mapUrl": "https://maps.google.com/?q=…",   // "Open in Maps"
  "guideUrl": "https://youtu.be/…",           // "Route video"
  "stories": [{ "name": "Juan Carlos Santos", "quote": "…", "since": "2023", "rating": 5 }]
}
// Product
{
  "name": "1 Bedroom",
  "code": "1BR.i",                      // source spreadsheet name, optional
  "floors": 1,                          // storeys (sample floor plan), optional
  "floor": "28 sqm", "lot": "N/A",      // optional
  "tcp": 3600000,
  "financing": {                        // optional → "Financing pending" UI
    "monthly": 26943.84, "gmi": 89813, "program": "REM", "term": "30 years",
    "note": "Insurance inclusion in monthly amortization is not specified."
  },
  "fees": {                             // optional
    "title": "Consultation & down payment",
    "rows": [["Consultation", "₱10,000"], ["Total down payment (DP)", "₱180,000 · 5% of TCP"]],
    "highlight": ["Monthly down payment", "₱28,333.33 × 6 months"],   // optional
    "note": "…"
  },
  "media": [Media]                      // optional product gallery
}
// Media (CMS uploads; when absent the app shows labelled sample media)
{
  "category": "Facade",                 // Project video | Project map | Facade | Amenities | Nearby destinations
                                        // Product video | Floor plan | Interior shots
  "caption": "Main facade",
  "type": "photo",                      // photo | video
  "url": "https://…/facade.jpg",
  "poster": "https://…/poster.jpg"      // videos, optional
}
```

The affordability check on the product page compares `financing.gmi` with the buyer's
`profile.grossMonthlyIncome`.

### Buyer: `BuyerRepository`

| Method | Path | Body | Response (sample) |
| --- | --- | --- | --- |
| GET | `/me` | — | `BuyerProfile` (`assets/data/profile.json`) |
| GET | `/me/transactions` | — | `Transaction[]` (`transactions.json`) |
| GET | `/me/application` | — | `ApplicationSection[]` (`application.json`) |
| POST | `/me/link-account` | `{ homefulId }`. Sends an OTP | 204 |
| POST | `/me/link-account/verify` | `{ homefulId, otp }` | 204 |
| PATCH | `/me/application` | Customer Information Form answers, `{ "<fieldId>": "value" }` (ids in `application_form.dart`) | 204 · **not wired yet** |
| PUT | `/me/application/spouse` | spouse fields, see `SpouseFlowModel.toJson()` | 204 |
| POST | `/me/application/spouse/invite` | `{ name, mobile }`. SMS link for the spouse to fill in | 204 |

Enumerations used in the samples: transaction `tone` = `acc | sub | mut` and `icon` = `wallet | home | calendar`.

### Requirements: `RequirementsRepository`

| Method | Path | Body | Response |
| --- | --- | --- | --- |
| GET | `/me/requirements` | — | `Requirement[]` (`requirements.json`); `status` = `acc \| rev \| sub \| todo` |
| POST | `/me/requirements/{id}/files` | multipart `file` (pdf, jpg, png, heic) | 204 |

### Support: `TicketRepository`

| Method | Path | Body | Response |
| --- | --- | --- | --- |
| GET | `/me/tickets` | — | `Ticket[]` (`tickets.json` → `tickets`) |
| GET | `/ticket-categories` | — | `string[]` (`tickets.json` → `categories`) |
| POST | `/me/tickets` | `{ category, subject, message }` | 201 |
| POST | `/me/tickets/{id}/messages` | `{ text }` | 201 |

Ticket `status` = `open | progress | resolved`; message `kind` = `sys | me | them`. Agent replies currently
appear through a demo timer in `AppState.send`/`createTicket`. Replace it with polling or a realtime subscription
(for example, Supabase Realtime) and call `notifyListeners()`.

### Payments: `PaymentRepository`

| Method | Path | Body | Response |
| --- | --- | --- | --- |
| POST | `/me/payments/consultation` | `{ unitCode, method }`. `method` = the selected option id on the payment screen | `{ checkoutUrl? }` |

## Remaining `// TODO: API` items

Search the code for `TODO: API`. Each one is an explicit gap with no hidden mocks:

- **Token persistence**: `MemoryTokenStore` keeps the session in memory. Swap in Keychain/Keystore storage (for
  example, `flutter_secure_storage`) and refresh the session every 3 h and on app foreground.
- **Payment hand-off**: open `checkoutUrl` or the provider SDK, then show the receipt after the provider confirms
  (by webhook or deep link). The InstaPay view should render the QR Ph payload the provider returns. File:
  `lib/features/booking/booking_flow.dart`.
- **Seller QR payload**: the real format comes from the Funnel/Seller app (for example, a signed URL). Parse it in
  `booking_screens.dart` and open that unit (`ScannedUnitScreen` in `product_screen.dart` currently resolves the
  buyer's profile unit).
- **Customer Information Form**: save answers with `PATCH /me/application`
  (`application_edit_screen.dart`), and cascade Region → Province → City → Barangay from PSGC data
  (`application_form.dart`).
- **Terms & Privacy text** for the booking prompt: `booking_flow.dart`.
- **Live ticket replies and attachments**: `lib/app/app_state.dart` and `lib/features/help/help_screens.dart`.
- **Legal copy** (privacy policy and terms) from the CMS: `lib/features/profile/profile_screens.dart`.
- **Destinations not in the design yet**: notifications inbox, full transaction history and the AIF form.

## Where to look

| Need | File |
| --- | --- |
| Add or change an endpoint | `lib/data/repositories.dart` (interface, then the mock and HTTP implementations) |
| HTTP behaviour (headers, errors, refresh) | `lib/data/api/api_client.dart` |
| JSON ↔ model mapping | `lib/models/models.dart` (`fromJson`) |
| How screens call the backend | `AppState.run`, `AppState.refresh`, `AppState.signIn`/`signUp`/`signOut` |
| Sample payloads | `assets/data/*.json` |
