# Safer-Be Flights API — Frontend Integration Guide

**Status:** E2E CERTIFIED (Search → Fare Quote → Price Lock → Promo → Checkout initiate) with known limitations  
**Base path:** `/api/v1`  
**Audience:** Angular / Mobile engineers integrating customer flights **and** Admin Pricing / Offers  
**Source of truth:** Live Laravel routes, FormRequests, Resources, automated suites (2026-09-16)  
**Companion reports:** `docs/FLIGHT_E2E_CERTIFICATION_REPORT.md`, `docs/frontend/PROMOTIONS.md`, `docs/FRONTEND_PRICING_API_GUIDE.md`

This document contains **confirmed** contracts only. It does not include supplier credentials. Public flight Search/Fare Quote expose **sell** prices only. Admin Pricing analytics may include commercial audit fields for authorized staff.

Do **not** hard-code UI authorization from role names alone. Use the `permissions` array returned on Admin login / `GET /auth/admin/me`.

---

## Complete customer flow (authoritative)

```text
1. POST /flights/search
      → display price.total (sell)
      → keep search_id + data[].reference_index
2. POST /flights/fare-quote  (reference_index + search_id)
      → display flight.total_price (sell, rechecked)
3. POST /flights/checkout/initiate  (auth; result_id; optional promo_code)
      → server Fare Quote again
      → Price Lock (Pricing sell)
      → Offers (auto or promo_code)
      → locked_sell_price = final payable
      → MyFatoorah invoice for that amount
      → response: booking_reference + payment_url
4. Redirect customer to payment_url
5. Gateway callback/webhook → payment_status PAID|FAILED
6. Assisted fulfillment (ops) — NOT auto supplier book
```

**There is no public Price Lock endpoint.** Lock happens only inside checkout initiate.

**Frontend never calculates:** markup, promo discount amount, or payable total. Display server sell / redirect with server `payment_url`.

---

## 1. Base URL & Authentication

| Item | Value |
|------|--------|
| Base URL | `{{base_url}}/api/v1` (host only in Postman `base_url`) |
| Public search / fare-quote | No bearer token |
| Customer checkout initiate | `Authorization: Bearer {{customer_token}}` (Sanctum) when `CHECKOUT_REQUIRES_AUTH=true` (default) |
| Admin Pricing / Rules / Analytics | `Authorization: Bearer {{admin_token}}` (Sanctum) + permission middleware |
| Booking mutation (ticket/release/refund) | Sanctum customer (or staff with permission) |
| Booking details / ticket / invoice PDF | Owner Sanctum **or** guest challenge (`email` + `last_name` query/body per access rules) |

### Common headers

```http
Accept: application/json
Content-Type: application/json
Accept-Language: {{locale}}
X-Request-Id: {{uuid}}
```

### Admin authentication (confirmed)

| Method | Endpoint | Auth |
|--------|----------|------|
| `POST` | `/api/v1/auth/admin/login` | Public credentials |
| `GET` | `/api/v1/auth/admin/me` | Bearer admin token |
| `POST` | `/api/v1/auth/admin/logout` | Bearer admin token |

Login requires the user to have **at least one staff role** assigned. After login, **permissions** are authoritative for Pricing UI actions.

Login / me payload includes (when `roles` are loaded):

```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "...",
    "email": "...",
    "roles": ["finance"],
    "permissions": ["pricing.view", "pricing.create", "pricing.update", "pricing.delete"]
  },
  "token": "...",
  "token_type": "Bearer"
}
```

`permissions` is the effective set from Spatie (`getAllPermissions()`), not role names.
---

## 2. API Conventions

### Success (Flights search / fare-quote)

```json
{
  "success": true,
  "...payload fields flattened at top level..."
}
```

Search pagination uses:

```json
{
  "success": true,
  "data": [ /* flight cards */ ],
  "meta": {
    "total": 34,
    "per_page": 10,
    "current_page": 1,
    "last_page": 4,
    "from": 1,
    "to": 10
  },
  "links": { "first": "...", "last": "...", "prev": null, "next": "..." },
  "supplier": "tbo",
  "journey_type": "1",
  "search_id": "flight_search_...",
  "currency": "USD"
}
```

### Error

```json
{
  "success": false,
  "error": "validation_error",
  "message": "...",
  "errors": {}
}
```

Some gateways return `error` as an object (`code`, `message`, `details`) — always read both shapes.

### JourneyType values

| Value | Meaning |
|------:|---------|
| `1` | One Way |
| `2` | Return / Round Trip |
| `3` | Multi City |

---

## 3. Search

### Method / Endpoint

| Field | Value |
|-------|--------|
| Method | `POST` |
| Endpoint | `/api/v1/flights/search` |
| Auth | Public |
| Rate limit | `throttle:search` |

Related convenience endpoints (same request body):

- `POST /api/v1/flights/cheapest`
- `POST /api/v1/flights/fastest`

### 3.1 One Way

**Status:** CERTIFIED (live CAI→DXB, 34 results)

#### Request

```json
{
  "JourneyType": 1,
  "Origin": "CAI",
  "Destination": "DXB",
  "DepartureDate": "2026-10-16",
  "AdultCount": 1,
  "ChildCount": 0,
  "InfantCount": 0,
  "FlightCabinClass": 1,
  "currency": "USD",
  "page": 1,
  "per_page": 10
}
```

**Required:** `AdultCount`; plus either flat OD/date fields **or** exactly one `Segments[]` item.  
**Optional:** cabin, children/infants, filters, sort, currency, `page`, `per_page`, `supplier`.

#### Response (sanitized confirmed sample)

```json
{
  "success": true,
  "data": [
    {
      "id": "9dbf4280e476e1b70a8ea986631072e2c0afe8ab",
      "result_index": 0,
      "reference_index": "OB9[TBO]…",
      "supplier": "tbo",
      "journey_type": "one_way",
      "legs": [
        {
          "origin_code": "CAI",
          "origin_name": "Cairo Int'l",
          "destination_code": "RUH",
          "destination_name": "King Khaled Int'l",
          "departure_time": "2026-10-16T11:40:00",
          "arrival_time": "2026-10-16T14:25:00",
          "duration_minutes": 165,
          "stops_count": 0,
          "airline_code": "SV",
          "airline_name": "Saudia",
          "flight_number": "310",
          "cabin_class": "Business",
          "segments": [ /* same shape */ ]
        }
      ],
      "price": {
        "total": 353.41,
        "currency": "USD",
        "base_fare": 234.95,
        "taxes": 118.46,
        "other_charges": 0,
        "breakdown": [
          { "code": "BASE", "label": "Base Fare", "amount": 234.95 },
          { "code": "TAX", "label": "Taxes & Fees", "amount": 118.46 },
          { "code": "OTHER", "label": "Other Charges", "amount": 0 },
          { "code": "TOTAL", "label": "Total", "amount": 353.41 }
        ],
        "pricing": {
          "applied": true
        }
      },
      "baggage": {
        "checked": "1 PC(s)",
        "cabin": "1 PC(s)",
        "description": "Checked: 1 PC(s) | Cabin: 1 PC(s)"
      },
      "refundable": true,
      "fare_policy": {
        "refundable": true,
        "penalties": {
          "cancellation_text": "INR 10155*",
          "reissue_text": "INR 6345*"
        },
        "mini_rules": [
          {
            "type": "Cancellation",
            "details": "INR 10155*",
            "online_refund_allowed": true,
            "online_reissue_allowed": false,
            "journey_points": "CAI-RUH-DXB"
          },
          {
            "type": "Reissue",
            "details": "INR 6345*",
            "online_refund_allowed": false,
            "online_reissue_allowed": true,
            "journey_points": "CAI-RUH-DXB"
          }
        ],
        "ticket_advisory": "TICKETS ARE NON REFUNDABLE AFTER DEPARTURE\nLAST TKT DTE 25OCT26 - DATE OF ORIGIN",
        "details_availability": "partial"
      },
      "last_ticket_date": "16OCT26",
      "best_deal_labels": []
    }
  ],
  "meta": { "total": 34, "per_page": 10, "current_page": 1 },
  "search_id": "flight_search_…",
  "supplier": "tbo",
  "journey_type": "1",
  "currency": "USD"
}
```

`price.*` values are **customer sell prices** (server pricing already applied). Supplier cost is not returned.

#### Search pricing fields

| Field | Meaning |
|-------|---------|
| `price.total` | **Final customer sell price** (use this on cards / sort) |
| `price.base_fare` | **Sell-side base** after server Pricing (markup already included in this component) |
| `price.taxes` / `price.other_charges` | Sell-side tax / other components |
| `price.breakdown[]` | Display lines: `BASE` / `TAX` / `OTHER` / `TOTAL` only (no `PRICING` line) |
| `price.pricing.applied` | `true` when the server Pricing Engine is enabled for Search |

Frontend **must not** calculate markup. No `supplier_base`, `adjustment_amount`, margin, or rule IDs are returned on Search.

#### Search fare policy

| Field | Meaning |
|-------|---------|
| `refundable` | Backward-compatible top-level boolean from TBO `IsRefundable` |
| `fare_policy.refundable` | Same refundable flag |
| `fare_policy.penalties` | Opaque supplier text (`cancellation_text` / `reissue_text`) when TBO provides `PenaltyCharges` or MiniFareRules details; otherwise `null` |
| `fare_policy.mini_rules` | Mapped TBO `MiniFareRules` when present; otherwise `null` |
| `fare_policy.ticket_advisory` | Free-text `TicketAdvisory` when present |
| `fare_policy.details_availability` | `partial` \| `flag_only` \| `unavailable` |

**Important semantics (do not invent):**
- Missing penalty ≠ no penalty.
- `refundable=true` ≠ free refund.
- Absence of a `changeable` field ≠ non-changeable (Search does not expose `changeable`).
- Detailed fare-rule text often requires Fare Quote / Recheck; Search may only have a flag or opaque penalty strings.

---

### 3.2 Return

**Status:** CERTIFIED (live DXB↔DEL, 150 flattened results after OD-filter fix)

#### Request

```json
{
  "JourneyType": 2,
  "Origin": "CAI",
  "Destination": "DXB",
  "DepartureDate": "2026-10-16",
  "ReturnDate": "2026-10-23",
  "AdultCount": 1,
  "FlightCabinClass": 1,
  "currency": "USD"
}
```

`ReturnDate` is required unless you send exactly two `Segments`.

#### Important behavior (confirmed)

- The API accepts Return searches.
- The backend currently searches **each leg as One Way** and returns a **flattened list**.
- Each card is labeled `"journey_type": "return"` and still has its own `reference_index`.
- Frontend must **not** assume a single combined TBO round-trip quote object.

---

### 3.3 Multi City

**Status:** CERTIFIED (live CAI→DXB→BKK→CAI, 143 flattened results)

#### Request

```json
{
  "JourneyType": 3,
  "AdultCount": 1,
  "FlightCabinClass": 1,
  "currency": "USD",
  "Segments": [
    {
      "Origin": "CAI",
      "Destination": "DXB",
      "PreferredDepartureTime": "2026-10-16",
      "FlightCabinClass": 1
    },
    {
      "Origin": "DXB",
      "Destination": "BKK",
      "PreferredDepartureTime": "2026-10-19",
      "FlightCabinClass": 1
    },
    {
      "Origin": "BKK",
      "Destination": "CAI",
      "PreferredDepartureTime": "2026-10-26",
      "FlightCabinClass": 1
    }
  ]
}
```

**Rules:** 2–6 segments; each requires `Origin`, `Destination`, `PreferredDepartureTime`.

#### Important behavior (confirmed)

- Each leg is searched as One Way and results are flattened.
- Multi-city results are **not cached**.
- Each selectable row has its own `reference_index` for Fare Quote.

---

## 4. Search Result Contract

### Fields the frontend must preserve

| Field | Meaning | Required later for |
|-------|---------|--------------------|
| `reference_index` | Opaque supplier ResultIndex | Fare Quote, Checkout `result_id` |
| `search_id` | Server search context id | Fare Quote (recommended), checkout continuity |
| `supplier` | e.g. `tbo` | Fare Quote / checkout (optional; defaults to `tbo`) |
| `price.total` / currency | Display only | Do **not** treat as authoritative booking price |
| `id` | Stable card id | UI only |

### Do **not** send to Fare Quote

| Field | Why |
|-------|-----|
| `result_index` (integer list rank) | Not the supplier ResultIndex |
| Client-edited `price.*` | Server recomputes / locks |

### Mapping: Search → Fare Quote

```text
search_id                 → fare-quote.search_id
data[n].reference_index   → fare-quote.reference_index  (preferred)
                            or fare-quote.result_index   (alias)
data[n].supplier          → fare-quote.supplier (optional)
```

### Mapping: Fare Quote → Checkout / Booking

```text
fare-quote.result_index / flight.result_index  → checkout.result_id
fare-quote.flight (segments + sell display)    → checkout.flight / flight_result
fare-quote.supplier                            → checkout.supplier
search_id                                      → checkout.search_id (recommended)
```

There is **no** separate public “price lock” endpoint. Lock is created server-side during `POST /flights/checkout/initiate`.

---

## 5. Fare Quote

| Field | Value |
|-------|--------|
| Method | `POST` |
| Endpoint | `/api/v1/flights/fare-quote` |
| Auth | Public |
| Status | CERTIFIED (live) |

### Request

```json
{
  "reference_index": "{{from search data[].reference_index}}",
  "search_id": "{{search_id}}",
  "currency": "USD"
}
```

Validation: `reference_index` **or** `result_index` required; `search_id` optional; `currency` optional (3 letters).

### Response (confirmed public shape)

```json
{
  "success": true,
  "result_index": "OB9[TBO]…",
  "flight": {
    "result_index": "OB9[TBO]…",
    "airline_code": "SV",
    "airline_name": "Saudia",
    "total_price": 353.41,
    "base_fare": 234.95,
    "tax": 118.46,
    "other_charges": 0,
    "currency": "USD",
    "is_refundable": true,
    "segments": [ /* SegmentDTO */ ],
    "last_ticket_date": "16OCT26"
  },
  "expires_in": 300,
  "supplier": "tbo",
  "currency": "USD",
  "requested_currency": "USD",
  "currency_converted": false
}
```

**Not returned (by design):** supplier cost, markup, `price_breakdown`, `pricing_context`, raw supplier payload.

`expires_in` is seconds (config default **300**).

---

## 6. Price Lock

| Question | Confirmed answer |
|----------|------------------|
| When locked? | At `POST /flights/checkout/initiate` (server-side) |
| What stored? | Locked sell + supplier snapshot on booking (`locked_sell_*`, supplier originals) |
| Can FE change price? | **No** — client financial fields are ignored |
| Supplier price change? | Variance may be recorded; customer locked sell is not auto-rewritten |
| Public lock endpoint? | **None** — lock is an internal checkout step |

Checkout success response (controller):

```json
{
  "success": true,
  "booking_reference": "…",
  "payment_url": "https://…",
  "message": "Checkout initiated. Please redirect to payment_url."
}
```

---

## 7. Pricing Behavior (Flights UI summary)

Full contract: **[Pricing Module API Contract](#pricing-module-api-contract)** below.

### What the flights UI needs

Search and Fare Quote already return **sell** prices. Frontend does **not** calculate markup and normally does **not** need Pricing APIs to show flight prices.

### Server formula (confirmed from `PricingIntegrationService::priceFlight`)

```text
supplier_base                          ← markup basis (NOT base+tax)
        ↓
matching Pricing Rules (priority ASC, then id ASC; cumulative)
        ↓
margin guard
        ↓
tax_on_markup (tax configs apply to markup amount only)
        ↓
sell_total = sell_base + supplier_tax + supplier_fees + tax_on_markup
```

**Concrete certified example** (`supplier_markup` 10% on TBO; margin/tax-on-markup ≈ 0):

| Input | Value |
|-------|------:|
| Supplier base | 100 |
| Supplier tax | 50 |
| Markup 10% of **base only** | 10 |
| **Search sell (`price.total`)** | **160** |
| Fare Quote / recheck sell | **160** (no compound) |

Display field on Search: **`price.total`** (already includes markup). Do not use preview `supplier_price` on flight cards.

### Public preview vs booking

`POST /pricing/preview` and `/pricing/breakdown` are **public** (throttle only). They expose `supplier_price` for tools — **not** booking authority. See contract section below.

---

## 8. Booking

### Assisted fulfillment path (current product)

```text
Fare Quote
  → POST /flights/checkout/initiate   (auth)
  → redirect payment_url
  → payment callback/webhook (gateway)
  → fulfillment execution (ops)
  → GET /flights/booking/{reference}
```

### Legacy direct book

| Method | Endpoint | Auth | Status |
|--------|----------|------|--------|
| `POST` | `/api/v1/flights/book` | Sanctum | **410** `legacy_booking_disabled` |

Unauthenticated callers hit **401** before the 410 body (auth middleware).

### Checkout initiate

| Field | Value |
|-------|--------|
| Method | `POST` |
| Endpoint | `/api/v1/flights/checkout/initiate` |
| Auth | Customer Sanctum when `CHECKOUT_REQUIRES_AUTH=true` (default) |
| Body | `BookFlightRequest` |

**Frontend sends (required highlights):**

| Field | Rules | Notes |
|-------|--------|-------|
| `result_id` | required string | Opaque supplier ResultIndex (= Search `reference_index` / FQ `result_index`) |
| `passengers[]` | 1–9 | title `Mr\|Mrs\|Ms\|Miss\|Dr`; type `adult\|child\|infant`; gender `1\|2`; passport; email; phone |
| `flight` or `flight_result` | segments required with | For validation; financial fields ignored |
| `search_id` | optional string | Sticky supplier / context |
| `supplier` | optional `tbo\|amadeus` | Sticky preferred |
| `currency` | optional ISO 3 | Display preference |
| `promo_code` | optional string max 50 | Normalized uppercase; see Offers |
| `points_to_redeem` | optional int ≥ 0 | Loyalty; separate from Offers |

**Backend calculates (never trust client):**

- Fare Quote + Pricing sell
- Price Lock (`locked_sell_*`)
- Offer / promo discount
- Final `payment_amount` sent to MyFatoorah

**Success response (controller — public):**

```json
{
  "success": true,
  "booking_reference": "FLT-…",
  "payment_url": "https://…",
  "message": "Checkout initiated. Please redirect to payment_url."
}
```

`locked_sell_price` is **not** returned on initiate success (internal + booking details later). Redirect using `payment_url` only.

**Invalid promo:** HTTP **422**, `promo_code` field errors — **no** silent fallback to another Offer.

### Booking details

`GET /api/v1/flights/booking/{reference}` — owner or guest challenge.

### Live supplier Book

**Not live-certified** in this environment (no safe automated TBO Book). Automated coverage exists for lock/tamper/410/persistence.

---

## 8b. Offers / Promo Codes (Flight checkout)

Feature flag: `OFFERS_ENABLED` → `config('promotions.enabled')` (default **false**). When disabled, `promo_code` is ignored for auto-offers and code apply returns unavailable.

Full Admin contract: [`docs/frontend/PROMOTIONS.md`](./frontend/PROMOTIONS.md).

### Automatic Offers (no `promo_code`)

Server picks highest-priority eligible Offer (`matchBest`). Stacking is not supported.

### Promo Codes (`promo_code` present)

Server resolves **that** Offer by normalized code (`RAMADAN10` ≡ `ramadan10`). Must pass eligibility. Invalid codes → **422** — do **not** fall back to another Offer.

### Supported scopes (map to Offer `type`)

| Scope | `type` | Condition | Example |
|-------|--------|-----------|---------|
| All Flights | `global` | none | `FLIGHT10` |
| Airline | `airline` | `condition_type=airline`, value `EK` | `EMIRATES10` |
| Route (directional) | `route` | `condition_type=route`, value `CAI-DXB` | `CAIDXB15` |

`CAI-DXB` ≠ `DXB-CAI`.

### Order with Pricing (certified)

```text
Supplier base → Pricing markup → Customer sell (Search/FQ)
→ Price Lock (sell)
→ Promo %/fixed on sell
→ Final locked_sell_price = MyFatoorah amount
```

Certified numeric example (margin/tax-on-markup = 0):

| Step | Amount (SAR) |
|------|-------------:|
| Supplier base | 1000 |
| Supplier tax | 100 |
| Pricing 10% on **base** | +100 → sell base 1100 |
| Sell total | **1200** |
| Promo `SELL10` 10% on sell | −120 |
| **Final payable** | **1080** |

Frontend displays Search/FQ sell; after checkout, payment is for the **server** discounted amount (not recalculated in UI).

### Discount types

`percentage` | `fixed` — plus optional `max_discount`. Discount never exceeds sell.

---

## 9. Error Handling

Statuses / codes confirmed in flights/pricing paths:

| HTTP | Error code / meaning | Frontend action |
|-----:|----------------------|-----------------|
| 401 | `unauthenticated` (ExceptionRenderer) or `unauthorized` (`CheckPermission` / ApiResponseTrait) | Re-auth / refresh token |
| 403 | `forbidden` | Hide action; show not-authorized message |
| 404 | `not_found` | Booking/rule missing |
| 410 | `legacy_booking_disabled` | Use checkout initiate |
| 422 | `validation_error` | Map field errors to form — including `promo_code` |
| 409 | payment reconciliation conflicts / fare price change | Show payment retry / confirm new price / re-search |
| 410 | fare quote expired / legacy book | Re-search; use checkout initiate |
| 429 | rate limited | Back off |
| 4xx/5xx supplier | `search_failed` / `fare_quote_failed` / `supplier_error` / etc. | Show message; for fare-quote expiry re-search |

### Promo / Offer errors (checkout)

| Scenario | HTTP | Behavior | Frontend |
|----------|-----:|----------|----------|
| Unknown / inactive / expired / exhausted promo | 422 | `promo_code` errors | Show message; clear code |
| Airline / route mismatch | 422 | not valid for selected flight | Clear code or change flight |
| Valid promo | 200 | discounted MF amount | Redirect `payment_url` |
| No `promo_code` | 200 | optional auto Offer | Unchanged UX |
### Validation error contract (ExceptionRenderer — authoritative for FormRequest / ValidationException)

HTTP **422**:

```json
{
  "success": false,
  "error": {
    "code": "validation_error",
    "message": "Validation failed",
    "details": {
      "configuration.supplier_codes": [
        "At least one supplier code is required."
      ],
      "name": [
        "The name field is required."
      ]
    }
  },
  "trace_id": "req_…",
  "status_code": 422
}
```

Map `error.details` keys to form fields (including dotted keys such as `configuration.adjustment_value`). Multiple messages per field are arrays.

Confirmed public Pricing preview example: missing `product_type` / `base_price` → `error.code = validation_error` with `error.details.product_type` / `error.details.base_price`.

### Authorization contracts

**Unauthenticated** (no/invalid bearer on permission middleware):

```json
{
  "success": false,
  "error": "unauthorized",
  "message": "Unauthorized"
}
```

HTTP **401**.

**Authenticated but missing permission** (`CheckPermission`):

```json
{
  "success": false,
  "error": "forbidden",
  "message": "You do not have the required permission."
}
```

HTTP **403**.

Frontend must gate UI from `user.permissions`, but must still handle 403 if permissions change server-side.
---

## 10. Complete Booking Flow

```text
1. (Optional) Customer login → customer_token
2. POST /flights/search
3. Display data[].price (sell) + legs/baggage
4. User selects a card
5. Keep search_id + reference_index (+ supplier)
6. POST /flights/fare-quote
7. Show confirmed sell price (flight.total_price); note expires_in
8. Collect passengers
9. POST /flights/checkout/initiate (Bearer)
10. Redirect to payment_url
11. Poll/open GET /flights/booking/{reference} after payment/fulfillment
```

---

## 11. Endpoint Certification Matrix

| Area | Endpoint | Scenario | Pricing | Supplier Markup | Result | Status |
|------|----------|----------|---------|-----------------|--------|--------|
| Search | `POST /flights/search` | One Way CAI→DXB | ✓ sell | ✓ server-side | 34 results | **CERTIFIED** |
| Search | `POST /flights/search` | Return DXB↔DEL | ✓ | ✓ | 150 results | **CERTIFIED** |
| Search | `POST /flights/search` | Multi City 3 legs | ✓ | ✓ | 143 results | **CERTIFIED** |
| Fare Quote | `POST /flights/fare-quote` | Selected OW result | ✓ | ✓ once | sell retained | **CERTIFIED** |
| Price Lock | via checkout initiate | Server lock | ✓ | ✓ | ignore client $ | **CERTIFIED** (automated) |
| Pricing preview | `POST /pricing/preview` | Optional FE tool | ✓ | ✓ | exposes breakdown | **CERTIFIED** (automated) |
| Booking | `POST /flights/book` | Legacy | n/a | n/a | 410 | **CERTIFIED** (disabled) |
| Booking | `POST /flights/checkout/initiate` | Assisted path | ✓ | ✓ | payment_url | **TEST CERTIFIED** / live Book blocked |
| Live TBO Book | fulfillment | Live supplier Book | — | — | — | **BLOCKED** |

---

## 12. Known Limitations

1. **Return / Multi City** are accepted APIs, but inventory is currently assembled from **per-leg One Way** searches (flattened list), not a single native combined TBO JourneyType=2/3 quote.
2. **Multi City** search results are not cached.
3. **Live TBO Book** is not executed in automated certification (no safe test booking environment). Product path is checkout → payment → fulfillment.
4. Cold TBO authentication can take ~40–90s; searches may be slow on cold cache.
5. Public Pricing preview exposes commercial breakdown (`supplier_price`, markup) — use only for tools/admin preview UIs, not as booking authority.
6. Fare Quote public resource shape differs from Search card shape (`flight.total_price` vs `price.total`).

---

## 13. Frontend Integration Checklist

- [ ] Use `reference_index` (not list `result_index`) for Fare Quote
- [ ] Pass `search_id` when available
- [ ] Display Search/Fare Quote sell prices; never trust client-edited totals at checkout
- [ ] Handle Return/Multi City as flattened selectable legs unless product UX builds its own pairing
- [ ] Call Fare Quote before checkout
- [ ] Use `POST /flights/checkout/initiate` (not `/flights/book`)
- [ ] Redirect to `payment_url`
- [ ] Load booking via `GET /flights/booking/{reference}` with ownership/guest rules
- [ ] Do not store supplier credentials or expect supplier cost in public flight cards
- [ ] Handle 410 on legacy book and 401 on missing auth
- [ ] Account for slow supplier responses / empty inventory (`data: []` with `success: true`)

---

## Reference helpers (public)

| Method | Endpoint |
|--------|----------|
| GET | `/api/v1/flights/airports` |
| GET | `/api/v1/flights/airports/autocomplete` |
| GET | `/api/v1/flights/airports/nearby` |
| GET | `/api/v1/flights/airports/{code}` |
| GET | `/api/v1/flights/zones` |
| POST | `/api/v1/flights/detect-zone` |
| GET | `/api/v1/flights/flight-types` |

---

# Pricing Module API Contract

Source of truth: `app/Modules/Pricing/routes.php`, controllers, `PricePreviewRequest`, `PricingRuleConfigurationValidator`, `PricingIntegrationService`, `RuleMatcherService`, `SupplierMarkupStrategy`, `FlightSearchResultMapper`, seed `roles_permissions.php`, certification evidence `tmp/flights_api_certification_evidence.json`.

**Frontend integration rule**

```text
Frontend does not calculate pricing.
Frontend sends search / booking / admin rule requests.
Backend applies Pricing Rules.
Backend returns the resulting sell price.
Frontend displays the backend price.
```

Admin Pricing screens: client may do basic input checks; **backend validation, authorization, and calculation remain authoritative**.

---

## Pricing Module Overview

| Concern | Owner |
|---------|--------|
| Supplier base / tax / fees | Supplier + normalization (`supplier*` on internal DTO) |
| Rule matching & markup | Pricing Module (`RuleMatcherService` + strategies) |
| Margin guard / tax-on-markup | Pricing Module |
| Customer sell price | Pricing Module → Search/Fare Quote resources |
| Price lock | Checkout / `BookingPriceLockService` (server) |

`PRICING_ENGINE_ENABLED` (`config('pricing.enabled')`) must be true or Search/Fare Quote skip pricing and keep supplier totals as-is.

Search caching is **pricing-state aware**: when Admin creates/updates/deletes/activates Pricing Rules, subsequent identical Searches use the **current** rules (stale priced cache entries are version-busted). Frontend always displays the returned sell price (`data[].price.total`) and never recalculates markup.

Coupon controllers exist in the module but are **not** registered on `/api/v1/pricing/*` routes — not part of this public contract.

---

## Pricing Endpoints

| Method | Endpoint | Purpose | Auth | Middleware | Permission | Status |
|--------|----------|---------|------|------------|------------|--------|
| `POST` | `/api/v1/pricing/preview` | Non-persisting price preview | **None** | `api` + `throttle:{preview_rate_limit},1` (default 30/min) | **None** | Live |
| `POST` | `/api/v1/pricing/breakdown` | Same as preview (`PricingPreviewService::preview`) | **None** | `api` + same throttle | **None** | Live |
| `GET` | `/api/v1/pricing/rules` | List rules (paginated) | Sanctum | `api` + `auth:sanctum` + `permission:pricing.view` | `pricing.view` | Live |
| `POST` | `/api/v1/pricing/rules` | Create rule | Sanctum | `api` + `auth:sanctum` + `permission:pricing.create` | `pricing.create` | Live |
| `GET` | `/api/v1/pricing/rules/{rule}` | Show rule | Sanctum | `api` + `auth:sanctum` + `permission:pricing.view` | `pricing.view` | Live |
| `PUT\|PATCH` | `/api/v1/pricing/rules/{rule}` | Update / enable-disable | Sanctum | `api` + `auth:sanctum` + `permission:pricing.update` | `pricing.update` | Live |
| `DELETE` | `/api/v1/pricing/rules/{rule}` | Delete rule | Sanctum | `api` + `auth:sanctum` + `permission:pricing.delete` | `pricing.delete` | Live |
| `GET` | `/api/v1/pricing/analytics/logs` | Pricing logs | Sanctum | `api` + `auth:sanctum` + `permission:pricing.view` | `pricing.view` | Live |
| `GET` | `/api/v1/pricing/analytics/summary` | Summary metrics | Sanctum | `api` + `auth:sanctum` + `permission:pricing.view` | `pricing.view` | Live |

`{rule}` is the numeric PricingRule id (route parameter name `rule`).

---

## Endpoint Middleware & Permissions

### Authentication / Authorization (per endpoint)

| Endpoint | Authentication | Authorization | Other |
|----------|----------------|---------------|-------|
| `POST …/preview` | None | None | Throttle only |
| `POST …/breakdown` | None | None | Throttle only |
| `GET/POST …/rules*` admin | `auth:sanctum` | `CheckPermission` via `permission:pricing.*` | — |
| `GET …/analytics/*` | `auth:sanctum` | `permission:pricing.view` | — |

Permission middleware alias resolves to `App\Http\Middleware\CheckPermission` (OR of listed permissions).

### Permission table

| Endpoint | Permission |
|----------|------------|
| `GET /pricing/rules` | `pricing.view` |
| `POST /pricing/rules` | `pricing.create` |
| `GET /pricing/rules/{rule}` | `pricing.view` |
| `PUT\|PATCH /pricing/rules/{rule}` | `pricing.update` |
| `DELETE /pricing/rules/{rule}` | `pricing.delete` |
| `GET /pricing/analytics/logs` | `pricing.view` |
| `GET /pricing/analytics/summary` | `pricing.view` |
| `POST /pricing/preview` | **NONE** |
| `POST /pricing/breakdown` | **NONE** |

Obtain permissions from Admin login / `GET /auth/admin/me` → `user.permissions[]` (Spatie `getAllPermissions()`). There is no Pricing-only permissions endpoint.

---

## Public / Unprotected Pricing Endpoints

> These endpoints have **no** Sanctum auth and **no** permission middleware. They must **not** be treated as Admin-only.

### `POST /api/v1/pricing/preview`

| | |
|--|--|
| Authentication | None |
| Authorization | None |
| Other | `throttle` (default 30/minute, `config('pricing.preview_rate_limit')`) |
| Why it exists | Non-persisting calculator / tool for what-if pricing |
| Exposes | `supplier_price`, markup breakdown, `profit`, `margin_percentage`, `grand_total` |
| Intended use | Internal/admin **tools** and diagnostics |
| **Not** for | Customer flight cards, checkout totals, booking authority |

### `POST /api/v1/pricing/breakdown`

Identical service path and response shape as preview (`PricingPreviewController::breakdown` → same `preview()`).

---

## Pricing Rules CRUD

Validator classes:

- Top-level: inline `$request->validate(...)` in `PricingRuleController` (no FormRequest)
- Configuration: `PricingRuleConfigurationValidator::normalize()` (also on model `saving`)

### List — `GET /pricing/rules`

| Field | Required | Type | Validation | Example |
|-------|---------:|------|------------|---------|
| `per_page` | no | int | controller default `20` (no explicit max in controller) | `20` |

**Success:** `200` `{ success, data[], meta, links }`.

### Show — `GET /pricing/rules/{rule}`

**Success:** `200` rule array. **404** if missing.

### Create — `POST /pricing/rules`

| Field | Required | Type | Validation | Allowed / notes | Example |
|-------|---------:|------|------------|-----------------|---------|
| `name` | yes | string | max 255 | — | `"TBO supplier 10%"` |
| `description` | no | string | nullable | — | `"…"` |
| `type` | yes | string | `in:` 10 types below | see Enums | `"supplier_markup"` |
| `priority` | no | int | min 0 max 9999 | default `0`; **lower runs first** | `10` |
| `configuration` | yes | array | normalized by validator | type-specific | see below |
| `is_active` | no | bool | nullable | default `true` | `true` |
| `starts_at` | no | date | nullable | active scope uses it | `null` |
| `ends_at` | no | date | `after_or_equal:starts_at` | | `null` |

**Success:** `201` `{ success, message: "Pricing rule created successfully", data: rule }`.

### Update — `PUT|PATCH /pricing/rules/{rule}`

Same fields with `sometimes` / nullable as in controller. Toggle enable via `"is_active": false`. Re-normalizes configuration when `type` and/or `configuration` present.

### Delete — `DELETE /pricing/rules/{rule}`

**Success:** HTTP **204** body via `noContent()`: `{ success, message: "Pricing rule deleted successfully" }`.

### Analytics

**Logs query** (`PricingAnalyticsController`):

| Field | Required | Type | Validation |
|-------|---------:|------|------------|
| `priceable_type` | no | string | max 100 |
| `product_type` | no | string | `flight\|hotel\|flight_result\|hotel_room` |
| `priceable_id` | no | string | max 255 |
| `supplier` | no | string | max 80 |
| `currency` | no | string | size 3 |
| `rule_id` | no | int | min 1 |
| `from` / `to` | no | date | `to` after_or_equal `from` |
| `per_page` | no | int | 1–100 (default 20) |

**Summary response fields:** `total_rules_applied`, `avg_markup_24h`, `recent_logs_24h`.

---

## Enums & Metadata

No dedicated PHP Enum classes for Pricing API fields. Allowed values come from validation `in:` / validator constants / config.

| Key | Type | Allowed values | Meaning |
|-----|------|----------------|---------|
| `type` (rule) | string enum | `airline_markup`, `route_markup`, `seasonal`, `customer_tier`, `peak_time`, `hotel_markup`, `supplier_markup`, `weekend_surge`, `advance_purchase`, `last_minute` | Rule strategy key |
| `adjustment_type` / `markup_type` | string enum | `percentage`, `fixed`, `multiplier` (`flat` → `fixed`) | How adjustment is computed |
| `product_type` (preview / scope) | string enum | `flight`, `hotel` | Product category |
| `currency` / `supplier_currency` | string | `USD,EGP,SAR,AED,EUR,GBP,KWD,QAR,OMR,BHD` (`config/currency.php`) | ISO-like codes |
| `is_active` | boolean | true/false | Rule enabled |
| `channel` (preview) | string | free text max 20; default in service `b2c` if omitted | Channel condition matching |
| `customer_tier` (preview) | — | **prohibited** on preview request | — |

### Configuration / metadata keys frontend may send (rules)

| Key | Where | Notes |
|-----|-------|-------|
| `adjustment_type`, `adjustment_value` | configuration | Primary; aliases `markup_type` / `markup_value` / `surge_percentage` / `discount_percentage` accepted by validator |
| `currency` | configuration | Required when `adjustment_type=fixed` |
| `supplier_codes` / `suppliers` | configuration / conditions / scope | Required for `supplier_markup` |
| `airline_codes` | configuration | Required for `airline_markup` |
| `routes` or `origin`+`destination` | configuration | Required for `route_markup` |
| `hotel_codes` or `product_type=hotel` | configuration | Required for `hotel_markup` |
| `customer_tiers` / `tiers` | configuration | Required for `customer_tier` |
| `months` | configuration | Required for `seasonal` (1–12) |
| `days` / `time_ranges` | configuration | `peak_time` / `weekend_surge` |
| `scope.product_type` | configuration.scope | Optional filter `flight\|hotel` |
| `limits.*` | configuration.limits | Optional non-negative bounds |
| `conditions.*` | configuration.conditions | Optional date/channel/tier/supplier filters |
| `priority`, `is_active`, `starts_at`, `ends_at` | top-level | Scheduling / order |

---

## Pricing Rule Configuration

### Adjustment rules (`PricingRuleConfigurationValidator`)

| Field | Required | Type | Min | Max | Notes |
|-------|---------:|------|-----|-----|-------|
| `adjustment_type` | yes* | string | — | — | *except some tiered forms that default |
| `adjustment_value` | yes* | number | see below | see below | *tiered `advance_purchase` / `customer_tier` / some `last_minute` may omit |
| percentage | — | — | 0 (or −100 for tier/last_minute) | 100 | |
| fixed / multiplier | — | — | 0 (or −99999999.99 for tier/last_minute) | no max in validator | |
| `currency` | if fixed | string | — | — | must be supported |

### Type-specific required scopes

| Type | Extra required |
|------|----------------|
| `airline_markup` | non-empty `airline_codes` |
| `route_markup` | `routes[]` **or** origin+destination |
| `hotel_markup` | `hotel_codes` **or** `product_type=hotel` |
| `supplier_markup` | non-empty `supplier_codes` |
| `customer_tier` | `customer_tiers` or `tiers` |
| `seasonal` | `months` 1–12 |
| `peak_time` | `days` and/or `time_ranges` (hours 0–23) |
| `weekend_surge` | if `days` present → non-empty |
| `advance_purchase` | if `tiers` present → each needs `min_days`, `max_days`, `multiplier` |

### `supplier_markup` example (create body)

```json
{
  "name": "TBO supplier 10%",
  "description": "Supplier-level markup for TBO",
  "type": "supplier_markup",
  "priority": 10,
  "configuration": {
    "adjustment_type": "percentage",
    "adjustment_value": 10,
    "supplier_codes": ["tbo"],
    "scope": { "product_type": "flight" }
  },
  "is_active": true
}
```

- `supplier_codes`: array of strings; empty/null items filtered; **no** existence check; duplicates allowed; match is **case-insensitive** at apply time.
- Percentage applies to **supplier base only** (see Search flow).

---

## Pricing Preview

### Request (`PricePreviewRequest`)

| Field | Required | Type | Validation | Allowed | Example |
|-------|---------:|------|------------|---------|---------|
| `product_type` | yes | string | `in:flight,hotel` | flight, hotel | `"flight"` |
| `base_price` | yes | number | min 0 max 99999999.99 | — | `400` |
| `supplier_tax` | no | number | min 0 max 99999999.99 | default 0 | `50` |
| `supplier_fees` | no | number | min 0 max 99999999.99 | default 0 | `0` |
| `currency` | no | string | size 3, supported list | default USD in service | `"SAR"` |
| `supplier_currency` | no | string | size 3, supported | defaults to `currency` | `"SAR"` |
| `airline_code` | no | string | max 2 | — | `"GF"` |
| `origin` / `destination` | no | string | max 3 | — | `"CAI"` / `"DXB"` |
| `origin_country_code` / `destination_country_code` | no | string | size 2 | — | |
| `departure_date` / `check_in` | no | date | `Y-m-d` | — | |
| `channel` | no | string | max 20 | — | `"b2c"` |
| `customer_tier` | **no — prohibited** | — | must not be sent | — | |

**Critical meanings**

| Request field | Meaning |
|---------------|---------|
| `base_price` | **Supplier base** (markup calculation basis). **Not** sell price. **Not** base+tax. |
| `supplier_tax` | Supplier tax/fees-like tax amount **added after** markup (not inside % base). |
| `supplier_fees` | Extra supplier fees **added after** markup. |

Controller passes **`$request->validated()` only**. Fields **not** in the FormRequest (e.g. `supplier`, `supplier_code`, `metadata`) are **dropped**. Therefore **`supplier_markup` rules will not match** on public preview/breakdown as implemented (context supplier stays empty). Use Search/Fare Quote or Admin tooling that prices with a real supplier context to verify `supplier_markup`.

### Response fields (`PricingPreviewService::preview`)

Wrapped as `{ success: true, data: { …preview… } }` (controller puts result under `data`).

| Field | Source | Meaning | Frontend usage | Internal/diagnostic |
|-------|--------|---------|----------------|---------------------|
| `supplier_price` | converted `base_price` | Supplier **base** after FX | Tools only — **not** Search card | Yes (cost) |
| `supplier_tax` / `supplier_fees` | request | Pass-through after FX | Tools | Yes |
| `markup.total` / `markup.breakdown` | rules engine | Applied markup | Tools | Yes |
| `margin_guard` | MarginGuardService | Min margin / whether adjusted | Tools | Yes |
| `net_price` | base after markup+guard | Before adding tax/fees/tax-on-markup | Tools | Yes |
| `tax.total` | TaxCalculator on **markup** | Tax-on-markup | Tools | Yes |
| `grand_total` | net + supplier_tax + fees + tax_on_markup | Preview sell-like total | Tools comparison only | Not booking authority |
| `profit` / `margin_percentage` | derived | Commercial metrics | **Admin/tools only** | Yes |

**Preview math (mirrors Search):**

```text
markup_basis = base_price (supplier base, after FX)
sell_like = (basis + markups + margin_guard) + supplier_tax + supplier_fees + tax_on_markup
         = grand_total
```

Example if a **10%** rule matched basis `400` and tax `50` (no tax-on-markup): `grand_total = 440 + 50 = 490`.  
With **no** matching rule: `grand_total = 400 + 50 = 450`.

---

## Pricing Rule Matching

Active rules: `is_active=true` and `starts_at`/`ends_at` window (`PricingRule::scopeActive`), cached as `pricing:rules:active`, ordered by **`priority` ASC, then `id` ASC**.

Common gates (`RuleMatcherService::matchesScopeAndConditions`) then strategy `supports()`:

| Dimension | Field | Optional? | Behavior |
|-----------|-------|-----------|----------|
| Product | `scope.product_type` vs context `metadata.product_type` | yes | Mismatch → skip |
| Base limits | `limits.minimum/maximum_base_price` | yes | Out of range → skip |
| Departure window | `conditions.departure_date_from/to` | yes | |
| Booking window | `conditions.booking_date_from/to` | yes | Requires booking_date in metadata |
| Channel | `conditions.channels[]` | yes | |
| Customer tiers | `conditions.customer_tiers[]` | yes | |
| Supplier list | `conditions|scope.supplier_codes` | yes | Case-insensitive; empty context supplier → skip |
| Fixed currency | rule `currency` vs pricing currency | when fixed | Mismatch → error |
| Type-specific | e.g. `supplier_codes` in `SupplierMarkupStrategy` | — | Must include context supplier |

**No matching rule:** markup amount 0; sell ≈ supplier base + tax + fees (still margin/tax stages).  
**Multiple rules:** all matching strategies apply **cumulatively** in priority order (not winner-takes-all).

---

## Pricing → Flight Search

### Pipeline (actual)

```text
POST /api/v1/flights/search
        ↓
TBO Search (supplier inventory)
        ↓
Normalize → FlightResultDTO (supplierBaseFare / supplierTax / supplierTotalPrice preserved)
        ↓
SupplierNormalizer::flightItem(supplierCode, …)  → metadata.supplier = e.g. "tbo"
        ↓
PricingIntegrationService::priceFlight  (if pricing.enabled)
        ↓
Markup on supplier BASE only → margin guard → tax_on_markup
        ↓
sell_total = sell_base + supplier_tax + supplier_fees + tax_on_markup
        ↓
FlightSearchResultMapper::buildPrice  (exposes SELL only; no supplier_* fields)
        ↓
HTTP Search response data[].price.*
```

Search request **must not** send markup / sell_price / supplier_cost — those fields are not part of the Search FormRequest contract. Pricing is server-authoritative.

### What happens for a One Way Search

Given:

```json
{
  "JourneyType": 1,
  "Origin": "CAI",
  "Destination": "DXB",
  "DepartureDate": "…",
  "AdultCount": 1,
  "ChildCount": 0,
  "InfantCount": 0,
  "FlightCabinClass": 1,
  "currency": "USD",
  "page": 1,
  "per_page": 10
}
```

```text
TBO supplier base + tax (+ fees)
        ↓
Pricing Module (active rules for product_type=flight, supplier=tbo, …)
        ↓
e.g. supplier_markup 10% of BASE
        ↓
Final sell total
        ↓
Response field: data[].price.total   ← frontend displays this
```

Certified controlled flight: base `100`, tax `50`, TBO `supplier_markup` 10% → **`price.total = 160`**.

---

## Search Price Response

Public mapper: `FlightSearchPriceDTO` / `FlightSearchResultMapper::buildPrice`.

Representative shape (certified OW sample; amounts vary by inventory):

```json
"price": {
  "total": 353.41,
  "currency": "USD",
  "base_fare": 234.95,
  "taxes": 118.46,
  "other_charges": 0,
  "breakdown": [
    { "code": "BASE", "label": "Base Fare", "amount": 234.95 },
    { "code": "TAX", "label": "Taxes & Fees", "amount": 118.46 },
    { "code": "OTHER", "label": "Other Charges", "amount": 0 },
    { "code": "TOTAL", "label": "Total", "amount": 353.41 },
    { "code": "PER_PASSENGER", "label": "…", "passengers": [/* sell-oriented */] }
  ],
  "pricing": { "applied": true }
}
```

| Search Field | Meaning | Includes Markup? | Frontend Should Use? |
|--------------|---------|-----------------:|---------------------:|
| `price.total` | Customer **sell** total | **Yes** (after Pricing Module) | **Yes — primary display / sort** |
| `price.currency` | Sell currency | n/a | **Yes** |
| `price.base_fare` | Sell base (supplier base + markup after margin) | Yes (in base) | Optional breakdown |
| `price.taxes` | Supplier tax (passthrough) | No | Optional breakdown |
| `price.other_charges` | Supplier other + any tax_on_markup | Tax-on-markup only | Optional |
| `price.breakdown[]` | Display lines for above (`BASE`/`TAX`/`OTHER`/`TOTAL`) | TOTAL line = sell | Optional UI |
| `price.pricing.applied` | Server Pricing Engine enabled for this Search | n/a | Optional badge / debug |
| `supplier_price` / cost / markup amount | — | — | **Not present** on Search |

Supplier cost remains on internal `FlightResultDTO.supplier*` only and is **not** mapped to the public Search card. There is **no** public `PRICING` breakdown line and **no** `adjustment_amount`.

### Search Fare Policy Response

```json
"refundable": true,
"fare_policy": {
  "refundable": true,
  "penalties": { "cancellation_text": "INR 10155*", "reissue_text": "INR 6345*" },
  "mini_rules": [ /* TBO MiniFareRules when present */ ],
  "ticket_advisory": "…",
  "details_availability": "partial"
}
```

| Field | Notes |
|-------|-------|
| `refundable` | Keep using for filters/badges; same as `fare_policy.refundable` |
| `fare_policy.penalties` | Opaque supplier text — do **not** convert currency or treat as sell amounts |
| `fare_policy.mini_rules` | Preserve `online_refund_allowed` / `online_reissue_allowed` as supplier flags (not “fully refundable” / “changeable”) |
| `details_availability` | `partial` (penalties/mini-rules/advisory), `flag_only` (boolean only), `unavailable` |

Missing MiniFareRules → `mini_rules: null` (no fake rules). Detailed fare text may still require Fare Quote.

---

## Fare Quote / Recheck Pricing

`FlightSearchService` fare-quote path calls `priceFlight` again on the **fresh supplier** quote amounts (supplier components), then `PublicFareQuoteResource` exposes:

| Field | Use |
|-------|-----|
| `flight.total_price` | **Primary confirmed sell** |
| `flight.base_fare` / `tax` / `other_charges` | Optional breakdown |
| `currency` | Yes |

No public `supplier_price` on Fare Quote resource.

**Double-markup:** Recheck uses preserved/fresh **supplier** base — not previous sell — so markup is **not** compounded. Certified: sell `160` → recheck `160`.

Frontend must **not** add markup again after Search or Fare Quote.

---

## Price Lock

No public `/pricing/lock` endpoint. Lock happens inside checkout initiate (`BookingPriceLockService`) using server Pricing. Client-sent totals are not authoritative.

---

## Admin Roles & Permissions

| Layer | Location |
|-------|----------|
| Seed | `database/seeders/data/roles_permissions.php` |
| Runtime | Spatie + `permission:…` middleware |

| Permission | Description |
|------------|-------------|
| `pricing.view` | List/show rules + analytics |
| `pricing.create` | Create rules (incl. supplier_markup) |
| `pricing.update` | Update / `is_active` toggle |
| `pricing.delete` | Delete rules |

No separate `pricing.enable` permission.

### Role → endpoint matrix (seed)

| Endpoint | super_admin | admin | operations | finance | devops | Permission |
|----------|:-----------:|:----:|:----------:|:-------:|:------:|------------|
| `GET /pricing/rules` | ✓ | ✗ | ✓ | ✓ | ✗ | `pricing.view` |
| `POST /pricing/rules` | ✓ | ✗ | ✓ | ✓ | ✗ | `pricing.create` |
| `GET /pricing/rules/{id}` | ✓ | ✗ | ✓ | ✓ | ✗ | `pricing.view` |
| `PUT\|PATCH /pricing/rules/{id}` | ✓ | ✗ | ✓ | ✓ | ✗ | `pricing.update` |
| `DELETE /pricing/rules/{id}` | ✓ | ✗ | ✗ | ✓ | ✗ | `pricing.delete` |
| `GET /pricing/analytics/*` | ✓ | ✗ | ✓ | ✓ | ✗ | `pricing.view` |
| `POST /pricing/preview` | public | public | public | public | public | **None** |
| `POST /pricing/breakdown` | public | public | public | public | public | **None** |

Seeded **`admin` excludes `pricing.*`**. Gate UI from `user.permissions`, not role name.

### Permission-Based UI

| Frontend Action | Required Permission | UI Behavior |
|-----------------|---------------------|-------------|
| Open Pricing / list | `pricing.view` | Show page |
| Create | `pricing.create` | Show Create |
| Edit / toggle active | `pricing.update` | Show Edit / toggle |
| Delete | `pricing.delete` | Show Delete |
| Analytics | `pricing.view` | Show analytics |

---

## Frontend Validation Responsibilities

**Client (recommended):** required fields, enums, % 0–100, non-empty `supplier_codes` for supplier_markup, priority 0–9999, dates order.

**Backend-authoritative:** permissions, full configuration normalize, rule match at search time, FX, margin/tax, sell price, price lock, supplier existence for applicability.

Passing client validation ≠ guaranteed success.

---

## Error Handling (Pricing)

| HTTP | When | Body (authoritative) |
|-----:|------|----------------------|
| 401 | No/invalid token on protected routes (`CheckPermission`) | `{ success:false, error:"unauthorized", message:"Unauthorized" }` |
| 403 | Missing permission | `{ success:false, error:"forbidden", message:"You do not have the required permission." }` |
| 422 | ValidationException / FormRequest | ExceptionRenderer: `error.code=validation_error`, `error.details` field map, message `Validation failed` |
| 404 | Missing rule | not_found envelope |

Map `error.details` keys (including `configuration.supplier_codes`) to form fields.

---

## Security / data exposure

| Surface | Supplier cost | Markup | Sell |
|---------|---------------|--------|------|
| Search / Fare Quote | Hidden | Hidden | Shown (`price.total` / `flight.total_price`) |
| Public preview/breakdown | Shown (`supplier_price`) + profit | Shown | `grand_total` (tool only) |
| Admin rules | N/A | Config JSON | N/A |
| Analytics logs | May include commercial fields | Applied rules | original/final |

---

## Search → Fare Quote → Checkout (reminder)

```text
1. POST /flights/search → display price.total (sell)
2. Keep search_id + reference_index (NOT list-rank result_index)
3. POST /flights/fare-quote → display flight.total_price
4. POST /flights/checkout/initiate
     - result_id = opaque index
     - optional promo_code (normalized uppercase)
     - server lock + offer → MyFatoorah amount
5. Redirect payment_url → callback → fulfillment (ops)
```

### Angular / mobile pseudo-flow

1. Call Search; render `price.total`; store `search_id` + `reference_index`.
2. On select → Fare Quote with those IDs; show `flight.total_price`.
3. Optional promo field → send as `promo_code` on checkout only (not Search).
4. Checkout initiate (Sanctum); on 422 promo errors show field message.
5. Open `payment_url`; do **not** mark paid locally.
6. After return, refresh booking details / status from API.
7. Never compute markup or discount client-side for payable.

Legacy `/flights/book` = **410**. Live TBO Book **not** certified. Financial ledger / webhook signature = **deferred**.

---

### Frontend-facing enums (quick reference)

| Domain | Field | Values |
|--------|-------|--------|
| Search | `JourneyType` | `1` One Way, `2` Return, `3` Multi City |
| Search | `FlightCabinClass` | `0` all, `1` Economy, `2` Business, `3` First, `4` Premium Economy |
| Passengers | `type` | `adult`, `child`, `infant` |
| Passengers | `gender` | `1`, `2` |
| Booking | `status` | `pending`, `confirmed`, `ticketed`, `cancelled`, `failed`, `released`, `refunded` |
| Payment | `payment_status` | `PENDING`, `PAID`, `FAILED`, `REFUNDED` |
| Offers | `type` | `global`, `destination`, `airline`, `route` |
| Offers | `discount_type` | `percentage`, `fixed` |
| Offers | `status` | `draft`, `active`, `disabled` |
| Offers | condition | `airline`, `destination`, `route`, `min_amount` |

---

*Pricing contract generated from Laravel Pricing module routes/services. Flights E2E certification: `docs/FLIGHT_E2E_CERTIFICATION_REPORT.md`. RBAC: `database/seeders/data/roles_permissions.php`.*
