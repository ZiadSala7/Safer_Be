# 02 — Frontend, Mobile & Admin Integration Guide

**Audience:** Web (React, Next.js, Vue, Angular), Mobile (Flutter, React Native), Admin Dashboard  
**Base URL:** `{APP_URL}/api/v1`  
**Interactive docs (Scribe):** `{APP_URL}/docs`  
**Postman collection:** `Traveling_Safer_API_V1.postman_collection.json` (repo root)  
**Regenerate Postman:** `php scripts/rebuild_postman.php`  
**Source of truth:** Implemented routes in `app/Modules/*/routes.php` — not planning docs or outdated copy

This guide documents **only features that exist in the current backend**. Hierarchy mirrors the latest Postman collection.

---

## Table of contents

1. [Quick start](#1-quick-start)
2. [Global contracts](#2-global-contracts) — headers, responses, errors, pagination
3. [Enums & constants](#3-enums--constants)
4. [Authentication](#4-authentication) — customer Sanctum auth
5. [Localization / Reference Data](#5-localization--reference-data)
6. [Search — Flights](#6-search--flights)
7. [Search — Hotels](#7-search--hotels)
8. [Checkout — Price Lock](#8-checkout--price-lock)
9. [Booking — Flights](#9-booking--flights)
10. [Booking — Hotels](#10-booking--hotels)
11. [Admin](#11-admin)
    - Authentication
    - Access Management (Admin Users, Roles, Permissions)
    - Customers
    - Bookings (Flights, Hotels)
    - Statistics
    - Reports
    - Suppliers
    - Observability
12. [Pricing](#12-pricing)
13. [Frontend integration notes](#13-frontend-integration-notes)
14. [Endpoint index](#14-endpoint-index)

---

## 1. Quick start

### 1.1 Environments

| Variable | Typical value | Purpose |
|----------|---------------|---------|
| `base_url` | `http://localhost:8000` | Host only (no `/api/v1`) |
| `customer_token` | Sanctum PAT from customer login | Mobile / customer web |
| `admin_token` | Sanctum PAT from admin login | Admin dashboard |
| `locale` | `en` or `ar` | Sent as `Accept-Language` |
| `search_id` | UUID from flight/hotel search | Fare quote / checkout context |
| `result_id` / `result_index` | Flight offer key | Fare quote / book |
| `booking_reference` | e.g. `FLT-…` | Post-booking |
| `admin_id`, `role_id`, `permission_id`, `customer_id` | Integers | Admin APIs |

Full path pattern:

```text
{base_url}/api/v1/{resource}
```

### 1.2 Minimal customer flight flow

```text
1. POST /auth/login                          → customer_token
2. GET  /destinations/autocomplete?q=Cairo   → airport codes
3. POST /flights/search                      → search_id + result_index
4. POST /flights/fare-quote                  → revalidate price
5. POST /flights/checkout/initiate           → payment_url + booking_reference
6. Redirect user to payment_url (MyFatoorah)
7. Gateway hits /flights/checkout/callback   → PAID → supplier book → confirmed
8. GET  /flights/booking/{reference}         → status / ticket data
```

### 1.3 Minimal admin flow

```text
1. POST /auth/admin/login                    → admin_token
2. GET  /auth/admin/me                       → user.roles + user.permissions
3. Gate UI by permissions (e.g. booking.view)
4. GET  /admin/bookings/flights              → ops list
5. GET  /admin/customers                     → customer desk
```

### 1.4 Features **not** implemented (do not build UI against them)

There are **no** public APIs for: favorites, notifications inbox, wallet, user booking history list, seat maps, SSR ancillaries, hotel room-type enums beyond supplier room codes, soft-delete restore for admins, or admin settings CRUD. Do not assume these endpoints exist.

---

## 2. Global contracts

### 2.1 Required headers

```http
Accept: application/json
Content-Type: application/json
Accept-Language: en
Authorization: Bearer {customer_token_or_admin_token}
X-Request-Id: {optional-client-uuid}
```

| Header | Required | Notes |
|--------|----------|-------|
| `Accept` | Yes | Prefer `application/json` |
| `Content-Type` | On bodies | `application/json` |
| `Authorization` | When route is protected | `Bearer` + Sanctum plain-text token |
| `Accept-Language` | Recommended | `en` \| `ar` — drives localized names in reference data |
| `X-Request-Id` | Optional | Correlates logs; server may echo as `trace_id` / `X-Trace-Id` |
| `Idempotency-Key` / `X-Idempotency-Key` | Optional | Supported on hotel checkout initiate (and related payment session reuse) |

### 2.2 Authentication model (Sanctum)

- Tokens are **personal access tokens** (PAT), not JWT.
- Send as: `Authorization: Bearer 1|plainTextToken…`
- Login/register **detaches web session cookies** so pure API clients stay bearer-only.
- Customer and admin tokens look the same; admin routes still enforce **Spatie roles/permissions** on the user behind the token.
- Store `customer_token` and `admin_token` separately in the client.

### 2.3 Success responses

Controllers use `ApiResponseTrait`. Success payloads are **flattened** — fields sit next to `success` rather than always wrapping in a single `data` object.

#### Simple success

```json
{
  "success": true,
  "token": "1|…",
  "user": {
    "id": 1,
    "name": "Jane",
    "email": "jane@example.com",
    "phone": null,
    "email_verified_at": "2026-01-01T12:00:00.000000Z",
    "phone_verified_at": null,
    "preferred_locale": "en",
    "roles": ["operations"],
    "permissions": ["booking.view", "customer.view"],
    "created_at": "…"
  }
}
```

#### Created (201)

```json
{
  "success": true,
  "message": "…",
  "data": { }
}
```

#### No content style (204)

HTTP `204` may still return JSON:

```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

#### Length-aware pagination

```json
{
  "success": true,
  "data": [ ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 20,
    "total": 100,
    "from": 1,
    "to": 20
  },
  "links": {
    "first": "https://…?page=1",
    "last": "https://…?page=5",
    "prev": null,
    "next": "https://…?page=2"
  }
}
```

Query params for most lists:

| Param | Default | Notes |
|-------|---------|-------|
| `page` | `1` | 1-based |
| `per_page` | varies (`20` ops, `50` countries, `10` search) | Often capped at `100` |

Some reference/list endpoints use **cursor/limit** instead of Laravel page meta (`cities` when not searching). Flight search meta may omit full `links` but includes `total`, `per_page`, `current_page`, `last_page`, `from`, `to`.

Field meanings:

| Field | Meaning |
|-------|---------|
| `success` | Always `true` on happy path |
| `message` | Human-readable status when present |
| `data` | Primary payload when the controller nests it |
| `meta` | Pagination or count metadata |
| `links` | Page URL helpers when using `successPaginated` |
| Top-level keys (`token`, `search_id`, `booking`, …) | Valid; do not force everything under `data` |

### 2.4 Error responses — two shapes

Clients **must support both**.

#### Shape A — Framework / middleware (`ExceptionRenderer`)

Used for uncaught exceptions, validation via FormRequest, 401/403/404/405/429, etc.

```json
{
  "success": false,
  "error": {
    "code": "validation_error",
    "message": "Validation failed.",
    "details": {
      "email": ["The email field is required."]
    }
  },
  "trace_id": "req_…",
  "status_code": 422
}
```

Header: `X-Trace-Id` mirrors `trace_id`.

| HTTP | Typical `error.code` |
|------|----------------------|
| 401 | `unauthenticated` |
| 403 | `forbidden` |
| 404 | `not_found` |
| 405 | `method_not_allowed` |
| 422 | `validation_error` |
| 429 | `rate_limited` |
| 500 | `server_error` |
| other 4xx | `http_error` |

#### Shape B — Domain / controller (`ApiResponseTrait`)

```json
{
  "success": false,
  "error": "booking_failed",
  "message": "Human readable message",
  "error_code": 30,
  "trace_id": "…"
}
```

`error` is a **string**. Optional extras: `errors` (trait validation helper), `old_price` / `new_price` / `action_required` (fare quote), `supplier`, etc.

#### Client parser (TypeScript)

```ts
type ApiErrorBody = {
  success: false;
  error: string | { code: string; message: string; details: unknown };
  message?: string;
  status_code?: number;
  trace_id?: string;
  error_code?: number;
  action_required?: string;
};

function parseError(body: ApiErrorBody) {
  if (typeof body.error === "object" && body.error !== null) {
    return {
      code: body.error.code,
      message: body.error.message,
      details: body.error.details,
      httpHint: body.status_code,
    };
  }
  return {
    code: body.error,
    message: body.message ?? String(body.error),
    details: null,
    action: body.action_required,
  };
}
```

### 2.5 HTTP status reference

| Status | When |
|--------|------|
| **200** | Standard success |
| **201** | Resource created |
| **204** | Logout / delete-style successes |
| **400** | Bad request (e.g. ticket PDF before ticketed; hotel callback missing `paymentId` as query) |
| **401** | Missing/invalid token; wrong credentials; admin login without admin role |
| **403** | Missing permission; email not verified on customer login; search owner mismatch |
| **404** | Resource missing |
| **409** | Conflict — fare price change, already ticketed, non-releaseable booking, hotel already cancelled, ticketing conflict |
| **410** | Gone — fare/search session expired (`action_required: search_again`) |
| **422** | Validation / business validation (passport, OTP invalid, etc.) |
| **429** | Rate limited (`throttle:search` = 30/min/IP, `throttle:booking` = 10/min/IP, OTP throttles, pricing limits) |
| **500** | Unhandled / payment / generic server |
| **502** | Supplier errors when using `supplierError` helper |
| **503** | Phone provider unavailable; ticket issuance env issues in some cases |

### 2.6 Validation errors (422)

**Renderer path (most FormRequests):**

```json
{
  "success": false,
  "error": {
    "code": "validation_error",
    "message": "Validation failed.",
    "details": {
      "Origin": ["Origin is required."],
      "passengers.0.passport_expiry": ["…"]
    }
  },
  "trace_id": "…",
  "status_code": 422
}
```

**Trait helper path (occasional):**

```json
{
  "success": false,
  "error": "validation_error",
  "message": "…",
  "errors": { "field": ["…"] }
}
```

### 2.7 Filtering, searching, sorting (conventions)

| Domain | Filtering | Search | Sorting |
|--------|-----------|--------|---------|
| Flight search | Body `filters.*` | N/A (criteria are Origin/Destination/dates) | Body `sort` / `Sort` |
| Hotel search | Body filters + price/stars | N/A | Supplier order unless engine applies |
| Admin customers | Query flags/status/dates | `search` → name, email, phone, id | `sort` + `direction` allow-list |
| Admin flight bookings | Rich query filters | `search` → pnr, booking_id, ticket, payment | `sort_by` + `sort_order` allow-list |
| Admin hotel bookings | Rich query filters | reference, hotel, email, payment | `sort_by` + `sort_order` |
| Roles / permissions lists | `module` (permissions) | `search` | Server defaults |
| Reports | date/status/supplier/currency | endpoint-specific | `sort_by` (must be a real column) |
| Observability logs | dates, level, supplier, module, event, endpoint, request_id | request correlation | created order |

Details are under each endpoint section.

### 2.8 Rate limits (named)

| Limiter | Limit | Applied to |
|---------|-------|------------|
| `search` | 30 / min / IP | Flight & hotel search |
| `booking` | 10 / min / IP | Checkout/book/ticket mutators |
| `api` | 60 / min | Default API |
| OTP send | 6 / min | Phone send-otp |
| OTP verify | 12 / min | Phone verify-otp |
| Pricing preview | config (`pricing.preview_rate_limit`, default 30) | preview/breakdown |
| Coupon validate | config (`pricing.coupon_rate_limit`, default 10) | coupon validate |

---

## 3. Enums & constants

### 3.1 Booking status (`BookingStatus`)

String values used in models/APIs:

| Value | Description |
|-------|-------------|
| `pending` | Created; not fully confirmed with supplier |
| `confirmed` | Supplier hold / booking OK |
| `ticketed` | Flight tickets issued |
| `cancelled` | Cancelled |
| `failed` | Failed (may retry to pending) |
| `released` | PNR released (terminal) |
| `refunded` | Refunded (terminal) |

Flights FSM also uses string state `payment_success_booking_failed` (paid but supplier book failed).

Helpers (backend): active = `confirmed` \| `ticketed`; cancellable = `pending` \| `confirmed`; refundable status check = `ticketed` (+ product refundable flag).

### 3.2 Payment status (string column)

| Value | Product |
|-------|---------|
| `PENDING` | Checkout initiated |
| `PAID` | MyFatoorah paid |
| `FAILED` | Payment not completed |
| `PAID_BUT_BOOKING_FAILED` | Hotels (and similar post-pay book fails) |

### 3.3 Journey type (`JourneyType`)

| Int | Meaning |
|-----|---------|
| `1` | One way |
| `2` | Return / round trip |
| `3` | Multi-city |

### 3.4 Cabin class (`CabinClass`)

| Int | Label |
|-----|-------|
| `1` | Economy |
| `2` | Business |
| `3` | First |
| `4` | Premium economy |

Search allows `FlightCabinClass` `0–4` (0 only on search). Filter string form: `economy` \| `business` \| `first` \| `premium_economy`.

### 3.5 Passenger types

| Book body string | Enum int |
|------------------|----------|
| `adult` | 1 |
| `child` | 2 |
| `infant` | 3 |

Gender on book: `"1"` or `"2"` (strings).

Passenger titles: `Mr`, `Mrs`, `Ms`, `Miss`, `Dr`.

### 3.6 Seeded roles

| Role slug | Intent |
|-----------|--------|
| `super_admin` | All permissions (`*`) |
| `admin` | Broad admin without full configure |
| `operations` | Ops + suppliers + pricing create/update |
| `finance` | Reports, pricing, bookings view |

Runtime roles/permissions live in DB (Spatie, guard `web`). Seed file: `database/seeders/data/roles_permissions.php`.

### 3.7 Seeded permission names

Pattern: `{module}.{action}` (dot notation).

| Permission | Module |
|------------|--------|
| `admin.view` `admin.create` `admin.update` `admin.delete` | admin |
| `role.view` `role.create` `role.update` `role.delete` | role |
| `permission.view` `permission.create` `permission.update` `permission.delete` `permission.assign` | permission |
| `pricing.view` `pricing.create` `pricing.update` `pricing.delete` | pricing |
| `supplier.view` `supplier.configure` `supplier.monitor` `supplier.toggle_features` | supplier |
| `api_monitor.view` `api_monitor.manage` | api_monitor |
| `feature_toggle.view` `feature_toggle.manage` | feature_toggle |
| `cache.view` `cache.manage` | cache |
| `metrics.view` | metrics |
| `reports.view` `reports.export` | reports |
| `booking.view` `booking.export` | booking |
| `customer.view` `customer.update` | customer |

### 3.8 Suppliers

Path/identifier set: `tbo`, `tbo_hotels`, `juniper`, `giata`.  
Environments: `sandbox` \| `staging` \| `production`.

---

## 4. Authentication

**Postman folder:** `Authentication`  
**Prefix:** `/api/v1/auth`  
**Customer app only** (admin auth lives under Admin → Authentication).

### 4.1 User resource shape

```json
{
  "id": 1,
  "name": "Mobile User",
  "email": "mobile@example.com",
  "phone": "+201001234567",
  "email_verified_at": null,
  "phone_verified_at": null,
  "preferred_locale": "en",
  "roles": [],
  "permissions": [],
  "created_at": "2026-01-01T00:00:00.000000Z"
}
```

`roles` / `permissions` populate when relations are loaded (especially admin me).

### 4.2 Register

| | |
|---|---|
| **Method / URL** | `POST /api/v1/auth/register` |
| **Auth** | None |
| **Permission** | — |

**Body**

| Field | Rules |
|-------|--------|
| `name` | required, string, max 255 |
| `email` | required, email, unique |
| `password` | required, min 8, confirmed |
| `password_confirmation` | required with password |
| `token_name` | optional, max 255 |

**Success `201`**

```json
{
  "success": true,
  "message": "…",
  "data": {
    "user": { },
    "token": "1|…"
  }
}
```

Email verification notification is sent. Token default name: `auth-token`.

### 4.3 Login (customer)

| | |
|---|---|
| **Method / URL** | `POST /api/v1/auth/login` |
| **Auth** | None |

**Body:** `email` (required), `password` (required), `token_name` (optional).

**Success `200`:** `{ success, user, token }`  

| Error | HTTP | Notes |
|-------|------|-------|
| Invalid credentials | 401 | |
| Email not verified | 403 | Must verify before login |

Persist `token` as `customer_token`.

### 4.4 Current user

`GET /api/v1/auth/user` — Auth: Sanctum → `{ success, user }`.

### 4.5 Update profile

`PUT|PATCH /api/v1/auth/profile` — Auth: Sanctum.

| Field | Rules |
|-------|--------|
| `name` | optional string |
| `email` | optional, unique ignore self |
| `phone` | optional, unique, 8–32, normalized |
| `preferred_locale` | optional, max 5 |

At least one field required. Changing email or phone clears the matching verification timestamp.

**Success:** `{ success, user, email_reverification_required, phone_reverification_required }`.

### 4.6 Token refresh

`POST /api/v1/auth/refresh` — Auth: Sanctum.

**Body (optional):** `{ "token_name": "ios-app" }`

**Success:**

```json
{
  "success": true,
  "token": "2|…",
  "token_type": "Bearer",
  "expires_in": null,
  "user": { }
}
```

Current PAT is revoked and replaced (abilities preserved). **Replace stored token immediately.**  
`expires_in` follows `config('sanctum.expiration')` (often `null` = no expiry).

### 4.7 Sessions

| Method | URL | Behavior |
|--------|-----|----------|
| GET | `/auth/sessions` | List tokens: `id`, `name`, `device_name`, `abilities`, `is_current`, `created_at`, `last_used_at`, `expires_at` + `meta.count` |
| DELETE | `/auth/sessions/all` | Revoke every token |
| DELETE | `/auth/sessions` | Revoke other tokens; keep current |
| DELETE | `/auth/sessions/{tokenId}` | Revoke by id — **cannot** revoke current (`422 cannot_revoke_current_session`) |

### 4.8 Logout

`POST /api/v1/auth/logout` — Auth: Sanctum → **204** `{ success, message }` — revokes **current** token only.

### 4.9 Password flows

| Endpoint | Auth | Body / notes |
|----------|------|--------------|
| `POST /auth/forgot-password` | None | `{ "email" }` — generic success (anti-enumeration) |
| `GET /auth/reset-password/{token}?email=` | None | Validates token → `{ success, valid, email, expires_in_minutes, locale }` |
| `POST /auth/reset-password` | None | `token` (body **or** query), `email`, `password` + confirmation, min 8 → revokes **all** tokens |
| `POST /auth/change-password` | Sanctum | `current_password`, `password`, `password_confirmation` → revokes **other** sessions |
| `POST /auth/confirm-password` | Sanctum | `{ "password" }` → sets confirmation timestamp |

### 4.10 Email verification

| Endpoint | Auth | Notes |
|----------|------|-------|
| `GET /auth/email/verify/{id}/{hash}` | None + **signed** URL | JSON if `Accept: application/json`; else HTML |
| `POST /auth/email/verification-notification` | Sanctum, throttle 6/min | Resend; `422 already_verified` if already done |

### 4.11 Phone OTP

| Endpoint | Throttle | Body |
|----------|----------|------|
| `POST /auth/phone/send-otp` | 6/min | `phone` required 8–32; `purpose` optional `verify`\|`login` (default `verify`) |
| `POST /auth/phone/verify-otp` | 12/min | `phone`, `code` 4–8, optional `purpose` |

**Success verify:** `{ success, data: { verified, phone }, message }`.  
If Sanctum user present and phone matches (or empty), sets `phone_verified_at`.  
Errors: `503 phone_provider_unavailable`, `429`, `422 otp_invalid` / `phone_mismatch`.  
With `PHONE_PROVIDER=fake` (non-production), send may include debug code.

### 4.12 Customer token lifecycle diagram

```text
register/login ──► store Bearer token
       │
       ├── GET /user, PATCH /profile, sessions…
       ├── POST /refresh ──► replace token in storage
       ├── POST /change-password ──► other sessions die
       ├── POST /reset-password ──► all sessions die
       └── POST /logout ──► current token dies → force re-login
```

---

## 5. Localization / Reference Data

**Postman:** `Localization / Reference Data`  
**Auth:** Public  
**Prefix:** `/api/v1`

| Method | Path | Query highlights | Response notes |
|--------|------|------------------|----------------|
| GET | `/countries` | `search`, `locale`, `sort_by` (`sort_order`\|`iso2`\|`iso3`\|`name`), `sort_order`, `page`, `per_page` (≤100, def 50) | Paginated countries + localized name, currency |
| GET | `/cities` | `locale`, `search`/`q`, `country` (ISO2), `limit` (def 20), `per_page`, `cursor` | Search path uses limit; browse uses cursor `meta.has_more` |
| GET | `/cities/{city}/airports` | `locale` | Path = city code/slug; 404 `city_not_found` |
| GET | `/airlines` | `search`, `locale`, `sort_by`, `sort_order`, `page`, `per_page` | Paginated |
| GET | `/airlines/suggest` | `q`/`keyword`, `country`, `page`, `per_page`, `locale`, `low_cost` | Ranked suggest |
| GET | `/airlines/autocomplete` | **`q` required**, `limit`, `locale`, `low_cost`, `country` | `{ data, meta: { count, locale, query } }` |
| GET | `/airports/suggest` | **`q` required**, `limit`, `locale`, `country` | Airport suggest |
| GET | `/destinations/autocomplete` | **`q` required**, `locale`, `limit` | Unified city/airport; Arabic normalization |
| GET | `/currencies` | — | Active currencies + `meta.count` |

Also under flights prefix (reference UX for flight product):

| Method | Path | Notes |
|--------|------|-------|
| GET | `/flights/zones` | Zone list |
| POST | `/flights/detect-zone` | Body may include `lat`, `lng` / `airport_code` / city / country |
| GET | `/flights/airports` | `search` (min length when used), `zone_id`, `limit` |
| GET | `/flights/airports/autocomplete` | **`q`**, `limit`, `zone_id` |
| GET | `/flights/airports/nearby` | **`lat`**, **`lng`**, `radius` 10–500, `limit` ≤50 |
| GET | `/flights/airports/{code}` | IATA code; 404 `airport_not_found` |
| GET | `/flights/flight-types` | Journey / cabin labels for UI |

Hotel reference:

| Method | Path | Query |
|--------|------|-------|
| GET | `/hotels/reference/top-destinations` | `country_code` (default EG) |
| GET | `/hotels/reference/hotels/autocomplete` | `q` min 2, `limit` |
| GET | `/hotels/reference/mappings/city/{cityId}` | Supplier city mapping |
| GET | `/hotels/reference/mappings/country/{countryId}` | Supplier country mapping |

---

## 6. Search — Flights

**Postman:** `Search — Flights`  
**Prefix:** `/api/v1/flights`  
**Auth:** Public  
**Rate limit:** `throttle:search` on search/cheapest/fastest

### 6.1 Search

`POST /api/v1/flights/search`

#### Core body

| Field | Rules |
|-------|--------|
| `JourneyType` | optional `1`\|`2`\|`3` (inferred when possible) |
| `Origin` / `Destination` | IATA 3 chars (simple trips) |
| `DepartureDate` | ≥ today |
| `ReturnDate` | after departure (return) |
| `Segments` | multi-city array: `Origin`, `Destination`, `PreferredDepartureTime`, optional cabin/arrival |
| `AdultCount` | required 1–9 |
| `ChildCount` / `InfantCount` | 0–9 |
| `FlightCabinClass` | 0–4 |
| `PreferredAirlines` | array of IATA2 |
| `currency` / `Currency` | ISO3 |
| `filters` | object (see below) |
| `sort` / `Sort` | sort key |
| `page` | default 1 |
| `per_page` | 1–100, default 10 |
| `supplier` | default `tbo` |

#### Filters (`filters`)

| Field | Purpose |
|-------|---------|
| `airlines` / `marketing_airlines` / `operating_airlines` | IATA2 lists |
| `stops` | e.g. `0`, `1`, `nonstop`, `1stop`, `2plus`, … |
| `direct_flights` / `direct` | boolean nonstop |
| `cabin_class` | `economy`\|`business`\|`first`\|`premium_economy` |
| `departure_time` / `arrival_time` | `early_morning`\|`morning`\|`afternoon`\|`evening`\|`night` |
| `refundable` | bool |
| `min_price` / `max_price` | ≥ 0 |
| `min_duration` / `max_duration` (or `*_journey_duration`) | minutes |
| `min_layover` / `max_layover` (or `*_layover_duration`) | minutes |
| `aircraft`, `connecting_airports`, `origin_airports`, `destination_airports` | codes |
| `has_checked_baggage` / `has_carry_on` / `has_cabin_baggage` | bool |
| `baggage_unit` | PC/PCS/KG |
| `min_checked_pcs` / `min_checked_kg` / `baggage_pcs` / `baggage_kg` | quantities |

#### Sort keys

Canonical: `recommended`, `lowest_price`, `highest_price`, `shortest_duration`, `longest_duration`, `earliest_departure`, `latest_departure`, `earliest_arrival`, `latest_arrival`, `fewest_stops`, `best_value`, `supplier_ranking`.

Aliases: `price_asc`/`price_desc`, `duration_asc`/`duration_desc`, `cheapest`, `fastest`, `value`, `supplier`. Unknown → `recommended`.

#### Success shape

```json
{
  "success": true,
  "data": [ /* flight offers */ ],
  "meta": {
    "total": 120,
    "per_page": 10,
    "current_page": 1,
    "last_page": 12,
    "from": 1,
    "to": 10
  },
  "links": { "first": "…", "last": "…", "prev": null, "next": "…" },
  "supplier": "tbo",
  "journey_type": 1,
  "search_criteria": { },
  "search_id": "uuid",
  "facets": [],
  "sort": "lowest_price"
}
```

**Client must store `search_id` and each offer’s `result_index` (or equivalent).**

Flight item fields commonly include: `id`, `result_index`, `reference_index`, `supplier`, `journey_type`, `legs[]`, `price` (`total`, `currency`, `base_fare`, `taxes`, …), `baggage`, `refundable`, `last_ticket_date`, labels.

### 6.2 Cheapest / fastest

`POST /api/v1/flights/cheapest` · `POST /api/v1/flights/fastest`  
Same validation as search; optional `limit` (default 1).  
Response: `{ success, supplier, journey_type, flights[], total_available, limit, search_id, facets }`.

### 6.3 Fare quote (revalidation)

`POST /api/v1/flights/fare-quote` — public (no search throttle)

| Field | Rules |
|-------|--------|
| `result_index` **or** `reference_index` | one required |
| `search_id` | recommended |
| `currency` | optional |
| `supplier` | optional |

**Success**

```json
{
  "success": true,
  "result_index": "…",
  "result_index_hash": "md5…",
  "flight": { },
  "expires_in": 300
}
```

| Situation | HTTP | Client action |
|-----------|------|---------------|
| Price changed (TBO 15) | **409** | Show `old_price`/`new_price`; `action_required: confirm_new_price` |
| Session/result expired (28) | **410** | `action_required: search_again` |
| No seats (10) | **404** | New search |
| Result not in context | **409** | New search / pick another offer |

### 6.4 Clear search cache

`DELETE /api/v1/flights/cache?origin=&destination=` → `{ success, message }`.

### 6.5 Baggage / seats / SSR

- **Baggage** appears on search results and fare quote/book payload segments — there is **no** separate baggage select API.
- **Seat selection / SSR extras** are **not** exposed as dedicated endpoints in this codebase. Do not invent UI flows against missing APIs.

---

## 7. Search — Hotels

**Postman:** `Search — Hotels`  
**Prefix:** `/api/v1/hotels`  
**Auth:** Public

### 7.1 Search

`POST /api/v1/hotels/search` — `throttle:search`

| Field | Rules |
|-------|--------|
| `city_code` **or** `hotel_code` | one required |
| `check_in` | ≥ today |
| `check_out` | after check_in |
| `adults` | 1–20 (or room-oriented payloads depending on provider mapping) |
| `children` / `child_ages` | children 0–10; ages 0–17 |
| `nationality` | ISO2 |
| `star_rating` | 1–7 |
| `min_price` / `max_price` | optional |
| `currency` | ISO3 |
| `supplier` | `tbo_hotels` \| `juniper` |
| `filters`, `page`, `per_page` | optional |
| `rooms` | used in product booking; search may accept adults or structured rooms |

PascalCase variants are often normalized to snake_case by the request.

**Success (typical):** `{ success, hotels[] or data, total, facets, search_id, session_id?, … }`.

### 7.2 Rooms availability

`POST /api/v1/hotels/{hotelCode}/rooms`

| Field | Rules |
|-------|--------|
| `check_in` / `check_out` | required pair |
| `guests[]` | `adults` ≥ 1, optional `children` |
| `supplier`, `currency` | optional |

**Success:** `{ hotel_code, check_in, check_out, rooms[], total }`.

### 7.3 Guests structure (booking)

Per room guest:

| Field | Rules |
|-------|--------|
| `title` | Mr/Ms/Mrs/Miss/Dr |
| `first_name` / `last_name` | required |
| `age` | optional 0–120 |

---

## 8. Checkout — Price Lock

**Postman:** `Checkout — Price Lock`  
**Recommended production path** for flights and hotels (payment-first).

### 8.1 Flight checkout

```text
Search → Fare quote (optional) → initiate → MyFatoorah payment_url
  → user pays → GET|POST /flights/checkout/callback?paymentId=
  → server sets PAID → supplier book → confirmed
  → optional webhook Event=TransactionsStatusChanged
```

#### Initiate

`POST /api/v1/flights/checkout/initiate` — `throttle:booking`, public (optional logged-in user)

Body: full **BookFlightRequest** (+ optional `callback_url`, `error_url`, idempotency keys).

**Passenger fields (each passenger):**

| Field | Rules |
|-------|--------|
| `title` | Mr,Mrs,Ms,Miss,Dr |
| `first_name` / `last_name` | required max 100 |
| `type` | adult\|child\|infant |
| `date_of_birth` | before today |
| `passport_number` | 6–20 |
| `passport_expiry` | after today **and** ≥ 6 months after first segment departure |
| `nationality` | ISO2 |
| `email` | required |
| `phone` | `+?[0-9]{10,15}` |
| `phone_country_code` | optional |
| `gender` | `"1"` \| `"2"` |
| `is_lead_passenger` | optional bool |
| `address` / `address2` | optional |

Also required: `result_id` (ResultIndex), and either `flight` or `flight_result` with pricing + segments (see FormRequest for camelCase vs snake_case).

**Success**

```json
{
  "success": true,
  "booking_reference": "FLT-…",
  "payment_url": "https://…",
  "message": "Checkout initiated. Please redirect to payment_url."
}
```

Creates **pending** booking + **PENDING** payment + **locked sell price**.

#### Callback / webhook

| Method | Path | Input | Notes |
|--------|------|-------|-------|
| GET\|POST | `/flights/checkout/callback` | `paymentId` request input | 422 if missing |
| POST | `/flights/checkout/webhook` | MyFatoorah event shape | `{ "status": "Webhook received" }` |

### 8.2 Hotel checkout

`POST /api/v1/hotels/checkout/initiate` — `throttle:booking`

**BookHotelRequest highlights:** `hotel_code`, `check_in`/`check_out`, `rooms[]` with `room_code`, `meal_plan`, `guests[]`, optional `email`, `phone`, `nationality`, `supplier`, `client_reference_number`.

**Success:** `{ payment_url, booking_reference, message }`.

| Method | Path | Notes |
|--------|------|-------|
| GET\|POST | `/hotels/checkout/callback` | `paymentId` as **query**; 400 if missing |
| POST | `/hotels/checkout/webhook` | same event pattern |

### 8.3 Booking lifecycle (payment path)

**Flights**

```text
pending + PENDING pay
  → PAID
  → confirmed  (or payment_success_booking_failed / failed)
  → ticketed
  → refunded | cancelled
  ↘ release only from pending → released
```

**Hotels**

```text
pending + PENDING pay
  → PAID → supplier book → confirmed-like status on record
  → cancel API → cancelled
  ↘ PAID_BUT_BOOKING_FAILED if supplier rejects after pay
```

### 8.4 Example initiate body (flights sketch)

```json
{
  "result_id": "{{result_id}}",
  "supplier": "tbo",
  "journey_type": 1,
  "flight": {
    "resultIndex": "{{result_id}}",
    "airlineCode": "MS",
    "airlineName": "EgyptAir",
    "totalPrice": 450,
    "baseFare": 400,
    "tax": 50,
    "currency": "USD",
    "isRefundable": false,
    "segments": [
      {
        "origin": { "code": "CAI", "name": "Cairo", "city": "Cairo", "country": "EG" },
        "destination": { "code": "DXB", "name": "Dubai", "city": "Dubai", "country": "AE" },
        "airlineCode": "MS",
        "airlineName": "EgyptAir",
        "flightNumber": "914",
        "departureTime": "2026-09-01T08:00:00",
        "arrivalTime": "2026-09-01T12:00:00",
        "duration": 240,
        "cabinClass": 1,
        "baggage": "23KG"
      }
    ]
  },
  "passengers": [
    {
      "title": "Mr",
      "first_name": "John",
      "last_name": "Doe",
      "type": "adult",
      "date_of_birth": "1990-01-15",
      "passport_number": "A1234567",
      "passport_expiry": "2030-01-01",
      "nationality": "EG",
      "email": "john@example.com",
      "phone": "+201001234567",
      "gender": "1",
      "is_lead_passenger": true
    }
  ]
}
```

---

## 9. Booking — Flights

**Postman:** `Booking — Flights`  
**Prefix:** `/api/v1/flights`  
Mutations under `throttle:booking` unless noted.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/book` | Public | **Legacy** book without MyFatoorah (still price-locks when prices present) — prefer checkout |
| POST | `/ticket` | Public | Body: `pnr` and/or `booking_reference` / `booking_id` |
| POST | `/booking/{reference}/release` | Public | Only **pending** + not ticketed → `released` |
| POST | `/booking/{reference}/refund` | Public | Ticketed + refundable; optional `amount`, `reason` |
| GET | `/booking/{reference}` | Public | DB booking or supplier fallback |
| GET | `/booking/{reference}/invoice` | Public | PDF invoice |
| GET | `/booking/{reference}/ticket` | Public | PDF ticket; **400** if not ticketed |

**Legacy book success (`201`):**

```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "booking_reference": "…",
    "pnr": "…",
    "status": "confirmed",
    "total_price": 0,
    "currency": "SAR",
    "passengers": [],
    "segments": []
  }
}
```

**Get details:**

```json
{
  "success": true,
  "source": "database",
  "booking": {
    "pnr": "…",
    "booking_reference": "…",
    "status": "ticketed",
    "total_price": 450,
    "currency": "USD",
    "ticket_number": "…",
    "passengers": [],
    "flight_details": {}
  }
}
```

**Notable errors:** 410 expired fare; 422 passport; 409 already ticketed / non-refundable / non-releaseable.

---

## 10. Booking — Hotels

**Postman:** `Booking — Hotels`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/hotels/book` | Legacy immediate supplier book (no gateway) |
| POST | `/hotels/booking/{reference}/cancel` | Optional body `{ "reason" }` max 500; 409 if already cancelled |
| GET | `/hotels/booking/{reference}` | `{ booking }` details |

Booking fields commonly: `booking_reference`, `supplier_booking_id`, `hotel_code`, `hotel_name`, `check_in`/`check_out`, `rooms`, `total_price`, `currency`, `status`, `guest_details`, `confirmation_number`, cancellation fields.

---

## 11. Admin

**Postman folder:** `Admin`  
All protected routes: `Authorization: Bearer {{admin_token}}` + required permission.

Authorization middleware: `permission:{name}` → OR across listed names; Spatie `hasPermissionTo` on guard `web`.  
Missing auth → 401. Missing permission → 403 (trait/renderer).

### 11.1 Admin → Authentication

**Postman:** `Admin / Authentication`  
**Prefix:** `/api/v1/auth/admin`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/login` | None | Admin login |
| GET | `/me` | Sanctum | Current admin profile |
| POST | `/logout` | Sanctum | Revoke current admin token |

**Login body:** `email`, `password`, optional `token_name`.

**Success:**

```json
{
  "success": true,
  "user": { "roles": ["admin"], "permissions": ["booking.view", "…"] },
  "token": "1|…",
  "token_type": "Bearer"
}
```

User must have role **`admin` or `super_admin`** (otherwise 401 “Admin access required.”).  
Default token name: `admin-token`. There is **no** separate admin refresh endpoint — use customer-style `/auth/refresh` only if the same user token was issued there; store and rotate the admin token from login responses.

**Recommended admin auth UX**

1. Login → store `admin_token` + permissions list from `user.permissions`.
2. Call `/me` on app boot to rehydrate gates.
3. On 401 → clear token and send to admin login.
4. On 403 → hide route / show forbidden (permission missing).

---

### 11.2 Admin → Access Management

**Postman:**

```text
Admin
└── Access Management
    ├── Admin Users
    ├── Roles
    └── Permissions
```

#### Authorization flow

```text
Bearer admin_token
  → Sanctum authenticates User
  → permission middleware checks Spatie permissions
  → AdminPolicy extra rules on admin user CRUD (super_admin protections)
  → Controller executes
```

Permission **naming:** `{resource}.{action}` e.g. `role.view`, `permission.assign`.

#### Admin Users — `/api/v1/admin/admins`

| Method | Path | Permission | Notes |
|--------|------|------------|-------|
| GET | `/` | `admin.view` | Paginated users that have **any** role; `per_page` (def 20) |
| POST | `/` | `admin.create` | Create admin user |
| GET | `/{admin}` | `admin.view` | Show |
| PUT | `/{admin}` | `admin.update` | Update |
| DELETE | `/{admin}` | `admin.delete` | Soft delete not restore API — hard delete after clearing roles; **super_admin cannot be deleted** |

**Create body**

| Field | Rules |
|-------|--------|
| `name` | required |
| `email` | required unique |
| `password` | min 8 confirmed |
| `roles` | required array min 1 (or BC `role`) — must exist |
| `permissions` | optional; requires caller `permission.assign` |

**Success create:** `201` via `created()` (payload nested under `data`).  
**List:** `{ success, data: UserResource[], meta }` (meta may be page fields).

#### Roles — `/api/v1/admin/roles`

| Method | Path | Permission | Body / query |
|--------|------|------------|--------------|
| GET | `/` | `role.view` | `per_page` 1–100 (def 50), `search` |
| POST | `/` | `role.create` | `slug` (or `name`), optional `description`, `parent_id`, `permissions[]` |
| GET | `/{role}` | `role.view` | numeric id |
| PUT | `/{role}` | `role.update` | partial fields + optional permissions |
| DELETE | `/{role}` | `role.delete` | cannot delete `super_admin` |
| POST | `/{role}/permissions` | `permission.assign` | `{ "permissions": ["booking.view"] }` — **assign (union)** |
| DELETE | `/{role}/permissions` | `permission.assign` | remove listed |
| PUT | `/{role}/permissions` | `permission.assign` | **sync** full direct set (array may be empty) |

**Role object (service):** `id`, `name`, `slug`, `description`, `guard_name`, `parent_id`, `parent`, `children`, `direct_permissions`, `inherited_permissions`, `permissions` (effective), timestamps.

Slug regex: `^[a-z0-9_.-]+$`.

#### Permissions — `/api/v1/admin/permissions`

| Method | Path | Permission | Notes |
|--------|------|------------|-------|
| GET | `/` | `permission.view` | `search`, `module`, `per_page`; `grouped=true` → map by module |
| POST | `/` | `permission.create` | slug/name + module/description |
| GET | `/{permission}` | `permission.view` | |
| PUT | `/{permission}` | `permission.update` | |
| DELETE | `/{permission}` | `permission.delete` | re-syncs super_admin |

**Permission object:** `id`, `name`, `slug`, `module`, `description`, `guard_name`, timestamps.

There is **no** separate “assign permission to role” under Permissions folder — assignment lives on **Roles** (`assign` / `remove` / `sync`).

---

### 11.3 Admin → Customers

**Postman:** `Admin / Customers`  
**Prefix:** `/api/v1/admin/customers`  
Staff users (`admin`, `super_admin`) excluded from customer desk lists/ops.

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/` | `customer.view` | List/filter customers |
| GET | `/{id}` | `customer.view` | Profile + stats + tokens |
| PUT\|PATCH | `/{id}` | `customer.update` | Profile fields only |
| POST | `/{id}/reset-password` | `customer.update` | New password + revoke all tokens |
| GET | `/{id}/bookings` | `customer.view` | `limit` def 50 |
| GET | `/{id}/timeline` | `customer.view` | Activity timeline |
| GET | `/{id}/statistics` | `customer.view` | Spend/counts |
| GET | `/{id}/tokens` | `customer.view` | Session list (no secrets) |
| DELETE | `/{id}/tokens/{tokenId}` | `customer.update` | Revoke one |
| POST | `/{id}/revoke-all-tokens` | `customer.update` | Force logout all devices |
| POST | `/{id}/force-logout` | `customer.update` | BC alias of revoke-all |

#### List query filters

| Param | Meaning |
|-------|---------|
| `search` | name, email, phone, exact id |
| `status` | `verified` \| `unverified` \| `phone_verified` \| `phone_unverified` |
| `email_verified` / `phone_verified` | boolean-like filters |
| `date_from` / `date_to` | `users.created_at` |
| `with_bookings` | default **true** — only users with flight/hotel bookings |
| `sort` | `id`(def), `name`, `email`, `phone`, `created_at`, `email_verified_at`, `phone_verified_at`, `last_login` |
| `direction` | `asc` \| `desc` (def desc) |
| `page`, `per_page` | 1–100, def 20 |

#### Update body (`UpdateCustomerRequest`)

Optional: `name`, `email` (unique), `phone` (8–32 unique), `preferred_locale`, `email_verified` bool, `phone_verified` bool. **No roles/password** on this endpoint.

#### Reset password body

`password` min 8 + `password_confirmation` → hashes password, revokes all Sanctum tokens.

---

### 11.4 Admin → Bookings

**Postman:** `Admin / Bookings / Flights|Hotels`  
**Prefix:** `/api/v1/admin/bookings`  
Permission: `booking.view` (export: `booking.export`).

#### Flights

| Method | Path | Notes |
|--------|------|-------|
| GET | `/flights` | Filtered paginated list |
| GET | `/flights/export` | CSV stream (row cap ≈ config) |
| GET | `/flights/{id}` | Full detail + passengers, fare_rules, pricing_snapshot, workflow, timeline, payments |
| GET | `/flights/{id}/timeline` | Events |
| GET | `/flights/{id}/payments` | Payment block |
| GET | `/flights/{id}/history` | Alias of timeline |

**Flight list filters (query):**  
`user_id`, `supplier`, `status` (string or array), `pnr`, `booking_id`, `date_from`/`date_to` (booking_date), `currency`, `ticketed`, `cancelled`, `refundable`, `payment_status`, `airline`, `origin`, `destination`, `travel_date`, `travel_date_from`/`to`, `search` (pnr, booking_id, ticket_number, payment_id).

**Sort:** `sort_by` ∈ `id`, `booking_date`(def), `total_price`, `status`, `created_at`, `ticketed_at`, `pnr` + `sort_order`.

**Pagination:** `page`, `per_page` 1–100.

List amount display prefers **locked sell price** coalesce.

#### Hotels

| Method | Path | Notes |
|--------|------|-------|
| GET | `/hotels` | List |
| GET | `/hotels/export` | CSV |
| GET | `/hotels/{id}` | Detail + rooms/guests/policies snapshot fields |
| GET | `/hotels/{id}/timeline` | Events |
| GET | `/hotels/{id}/payments` | Payments |
| GET | `/hotels/{id}/history` | Timeline |

**Hotel list filters:**  
`user_id`, `supplier`, `status`, `pnr` or `booking_id`, `date_from`/`date_to` (created_at), `travel_date` / `_from` / `_to` (check_in), `currency`, `cancelled`, `destination`, `payment_status`, `search` (reference, hotel_name, confirmation, guest_email, payment_id).

**Sort:** `sort_by` ∈ `id`, `created_at`(def), `total_price`, `status`, `check_in`, `check_out`.

---

### 11.5 Admin → Statistics

**Postman:** `Admin / Statistics`

#### Operations KPIs — `/api/v1/admin/operations/statistics*`

Common: `date_from`, `date_to`, `limit` (def 10; dashboard tops often fixed at 5).

| Method | Path | Permission | Purpose |
|--------|------|------------|---------|
| GET | `/admin/operations/statistics` | `booking.view` | Combined dashboard (rates, monthly revenue, tops) |
| GET | `…/top-customers` | `customer.view` | Ranking |
| GET | `…/top-airlines` | `booking.view` | Ranking |
| GET | `…/top-destinations` | `booking.view` | Ranking |
| GET | `…/top-suppliers` | `booking.view` | Ranking |
| GET | `…/monthly-revenue` | `booking.view` | Monthly series (default ~12 months) |
| GET | `…/rates` | `booking.view` | Success/refund/cancel rates |

#### Global metrics — `/api/v1/admin/statistics/*`

Permission: **`metrics.view`**. Query: `date_from`, `date_to`, `supplier` (defaults ~30 days).

| Path | Purpose |
|------|---------|
| `/dashboard` | Cards, charts, KPIs, tops |
| `/bookings` | by_status, by_type, trend |
| `/revenue` | totals, by_date, growth |
| `/performance` | search_time, supplier latency, reliability |
| `/top` | airlines, hotels, destinations, suppliers |

---

### 11.6 Admin → Reports

**Postman:** `Admin / Reports`  
**Prefix:** `/api/v1/admin/reports`  
Permission: `reports.view` (export: `reports.export`).

Shared query (`ReportIndexRequest`): `date_from`, `date_to` (default last 30 days), `status`, `supplier`, `currency` (3), `search`, `sort_by`, `sort_order`, `page`, `per_page` (1–100). Ranking endpoints accept `limit`.

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/flight-bookings` | Paginated + **summary** |
| GET | `/hotel-bookings` | Paginated + summary |
| GET | `/revenue` | Time series + totals |
| GET | `/profit` | Markup/discount/tax/profit |
| GET | `/refunds` | Paginated refund rows + summary |
| GET | `/coupons` | Coupon usage report |
| GET | `/taxes` | Tax aggregates |
| GET | `/fees` | Fee aggregates |
| GET | `/commission` | Commission aggregates |
| GET | `/top-airlines` | Rankings |
| GET | `/top-hotels` | Rankings |
| GET | `/top-destinations` | Rankings |
| GET | `/customers` | Customer report |
| GET | `/search-analytics` | Search analytics |
| GET | `/export` | CSV; require `report` ∈ allowed set; `format=csv` |

Paginated report responses may attach `summary` alongside `data`/`meta`/`links`.

---

### 11.7 Admin → Suppliers

**Postman:** `Admin / Suppliers`  
**Prefix:** `/api/v1/admin/suppliers`  
`{supplier}` ∈ `tbo` \| `tbo_hotels` \| `juniper` \| `giata`

| Method | Path | Permission |
|--------|------|------------|
| GET | `/` | `supplier.view` |
| GET | `/{supplier}/configuration` | `supplier.view` |
| PUT | `/{supplier}/configuration` | `supplier.configure` |
| GET | `/{supplier}/features` | `supplier.view` |
| PUT | `/{supplier}/features` | `supplier.toggle_features` |
| POST | `/{supplier}/test-connection` | `supplier.view` |

**Update configuration body (typical):** `is_enabled` / `enabled`, `environment` (`sandbox`\|`staging`\|`production`), `settings` object (secrets masked on read).

**Features body:** `{ "features": { "flight.search": true, … } }` map of capabilities.

Capabilities include: `flight.search|.fare_quote|.book|.cancel|.ticket|.refund`, `hotel.search|.pre_book|.book|.cancel|.booking_details|.content`, `car.search|.book|.cancel`.

---

### 11.8 Admin → Observability

**Postman:** `Admin / Observability`  
**Prefix:** `/api/v1/admin/observability`  
Permission: **`api_monitor.view`** (local log tables — not external ELK).

| Method | Path | Filters |
|--------|------|---------|
| GET | `/logs` | `date_from`, `date_to`, `level` (info\|warning\|error\|critical\|debug), `supplier`, `module`, `event`, `endpoint`, `request_id`, `correlation` (alias of request_id), `per_page` 1–100 |
| GET | `/logs/{id}` | single log |
| GET | `/requests/{requestId}` | full request trace |
| GET | `/summary/daily` | analytics filters |
| GET | `/analytics/errors` | analytics |
| GET | `/analytics/suppliers` | analytics |
| GET | `/analytics/events` | analytics |
| GET | `/analytics/endpoints` | analytics |

**Log resource:** `id`, `event`, `level`, `supplier`, `module`, `endpoint`, `request_id`, `context`, `created_at`.

---

## 12. Pricing

**Postman:** `Pricing` (mixed public + admin)  
**Prefix:** `/api/v1/pricing`

### 12.1 Public

| Method | Path | Auth | Rate |
|--------|------|------|------|
| POST | `/preview` | None | preview limiter |
| POST | `/breakdown` | None | same computation as preview (non-persisting) |
| POST | `/coupons/validate` | None (optional user for usage limits) | coupon limiter |

**Preview body (`PricePreviewRequest` highlights):**  
`product_type` (`flight`\|`hotel`), `base_price`, optional `supplier_tax`/`supplier_fees`, `currency`, airline/route/country codes, `departure_date` or `check_in`, `customer_tier`, `channel`, `coupon_code`.  
(Postman samples may use `base_fare` aliases — follow FormRequest field names in client code.)

**Success data:** supplier components, markup breakdown, margin_guard, taxes, fees, discount, `grand_total`, profit, margin_percentage.

**Validate coupon body:** `code` required; amount/total field per request class; `422 coupon_invalid` when invalid.

### 12.2 Admin (Sanctum + permissions)

| Method | Path | Permission |
|--------|------|------------|
| GET | `/rules` | `pricing.view` |
| POST | `/rules` | `pricing.create` |
| GET | `/rules/{rule}` | `pricing.view` |
| PUT\|PATCH | `/rules/{rule}` | `pricing.update` |
| DELETE | `/rules/{rule}` | `pricing.delete` |
| GET | `/coupons` | `pricing.view` |
| POST | `/coupons` | `pricing.create` |
| GET | `/coupons/{coupon}` | `pricing.view` |
| PUT\|PATCH | `/coupons/{coupon}` | `pricing.update` |
| DELETE | `/coupons/{coupon}` | `pricing.delete` |
| GET | `/analytics/logs` | `pricing.view` |
| GET | `/analytics/summary` | `pricing.view` |

**Rule types (create):** `airline_markup`, `route_markup`, `seasonal`, `customer_tier`, `peak_time`, `hotel_markup`, `weekend_surge`, `advance_purchase`, `last_minute`.

**Coupon types:** `percentage` \| `fixed` (code uppercased on create).

---

## 13. Frontend integration notes

### 13.1 Token storage

| Platform | Recommendation |
|----------|----------------|
| Flutter | Secure storage (Keychain/Keystore); separate keys for customer vs admin |
| Web SPA | Prefer memory + httpOnly cookie only if you introduce a BFF; pure SPA → secure storage (never `localStorage` for high-privilege admin if XSS risk is high) |
| Both | Never log Authorization headers |

### 13.2 Automatic logout

Force re-auth when:

- HTTP **401** on any authed call
- Logout success
- Password reset success (all tokens revoked)
- Customer reset-password from admin

Do **not** treat all **403** as logout — that is missing permission.

### 13.3 Refresh

Customer: `POST /auth/refresh` with current bearer → atomically swap token.  
Serialize refresh (single-flight mutex) so parallel 401s don’t thrash.

### 13.4 Loading & retry

| Scenario | Strategy |
|----------|----------|
| Search | Full-screen loader; disable double-submit; respect 429 `Retry-After` if present |
| Fare quote / book | Block payment button once |
| Safe GET | Soft retry 1–2× on network blips only — **never** auto-retry book/ticket |
| Idempotent checkout | Reuse same body + idempotency key |

### 13.5 Error UX mapping

| Code / status | UX |
|---------------|-----|
| 422 validation | Inline field errors from `error.details` |
| 409 confirm_new_price | Confirm dialog → re-quote / accept |
| 410 search_again | Reset search form |
| 429 | Backoff toast |
| 403 | Hide control or show “no permission” |
| 401 | Re-login |
| supplier / 5xx | Generic error + show `trace_id` for support |

### 13.6 Pagination & infinite scroll

- Use `meta.current_page` / `last_page` / `total`.
- Infinite scroll: next page while `meta.current_page < meta.last_page` or `links.next != null`.
- Flight search: page through offers with `page`/`per_page` on the **same** search criteria; keep `search_id`.

### 13.7 Debounced search

Debounce autocomplete (`destinations`, airlines, hotels, airports) by **300–400 ms**. Require min length where API expects it (often 2 chars).

### 13.8 Dates & timezones

- Send search dates as `Y-m-d` calendar dates unless the API requires datetime.
- Segment times are provider local times; display in the airport local zone — do not force a single app timezone onto itineraries without disclosing it.
- Admin date_from/to filters are server-defined field-specific (booking_date vs created_at vs check_in) — document labels in UI accordingly.

### 13.9 Currency formatting

- Prefer amount **+ currency code** from API (`USD`, `SAR`, …).
- Do not hardcode symbols for locked sell prices — use API currency.
- Hotel checkout may lock a specific currency depending on path (implementation uses SAR on payment path in places).

### 13.10 RBAC UI

```text
After admin login/me:
  permissions = Set(user.permissions)
  showMenu("Bookings") if permissions.has("booking.view")
  showExport if permissions.has("booking.export")
  showAccessMgmt if any of admin.*, role.*, permission.*
```

Never rely on role slug alone for feature flags when `permissions[]` is available.

### 13.11 Localization

Send `Accept-Language: ar|en` on every request that shows places/airlines. Combine with query `locale` when the endpoint supports it.

### 13.12 Flutter / React quick client sketch

```ts
const api = axios.create({
  baseURL: `${BASE_URL}/api/v1`,
  headers: {
    Accept: "application/json",
    "Content-Type": "application/json",
    "Accept-Language": locale,
  },
});

api.interceptors.request.use((config) => {
  const token = isAdminRoute(config.url) ? adminToken : customerToken;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});
```

---

## 14. Endpoint index

### Authentication (customer)

| Method | Path | Auth |
|--------|------|------|
| POST | `/auth/register` | — |
| POST | `/auth/login` | — |
| POST | `/auth/refresh` | Sanctum |
| GET | `/auth/user` | Sanctum |
| PUT\|PATCH | `/auth/profile` | Sanctum |
| POST | `/auth/phone/send-otp` | — |
| POST | `/auth/phone/verify-otp` | optional |
| POST | `/auth/logout` | Sanctum |
| GET | `/auth/sessions` | Sanctum |
| DELETE | `/auth/sessions/all` | Sanctum |
| DELETE | `/auth/sessions` | Sanctum |
| DELETE | `/auth/sessions/{tokenId}` | Sanctum |
| POST | `/auth/forgot-password` | — |
| GET | `/auth/reset-password/{token}` | — |
| POST | `/auth/reset-password` | — |
| POST | `/auth/change-password` | Sanctum |
| POST | `/auth/confirm-password` | Sanctum |
| POST | `/auth/email/verification-notification` | Sanctum |
| GET | `/auth/email/verify/{id}/{hash}` | signed |

### Localization / reference

| Method | Path |
|--------|------|
| GET | `/countries` |
| GET | `/cities` |
| GET | `/cities/{city}/airports` |
| GET | `/airlines` |
| GET | `/airlines/suggest` |
| GET | `/airlines/autocomplete` |
| GET | `/airports/suggest` |
| GET | `/destinations/autocomplete` |
| GET | `/currencies` |
| GET | `/flights/zones` |
| POST | `/flights/detect-zone` |
| GET | `/flights/airports` |
| GET | `/flights/airports/autocomplete` |
| GET | `/flights/airports/nearby` |
| GET | `/flights/airports/{code}` |
| GET | `/flights/flight-types` |
| GET | `/hotels/reference/top-destinations` |
| GET | `/hotels/reference/hotels/autocomplete` |
| GET | `/hotels/reference/mappings/city/{cityId}` |
| GET | `/hotels/reference/mappings/country/{countryId}` |

### Flights product

| Method | Path | Notes |
|--------|------|-------|
| POST | `/flights/search` | throttle:search |
| POST | `/flights/cheapest` | throttle:search |
| POST | `/flights/fastest` | throttle:search |
| POST | `/flights/fare-quote` | 409/410 critical |
| DELETE | `/flights/cache` | |
| POST | `/flights/checkout/initiate` | throttle:booking |
| GET\|POST | `/flights/checkout/callback` | paymentId |
| POST | `/flights/checkout/webhook` | |
| POST | `/flights/book` | legacy |
| POST | `/flights/ticket` | |
| POST | `/flights/booking/{reference}/release` | |
| POST | `/flights/booking/{reference}/refund` | |
| GET | `/flights/booking/{reference}` | |
| GET | `/flights/booking/{reference}/invoice` | |
| GET | `/flights/booking/{reference}/ticket` | PDF |

### Hotels product

| Method | Path | Notes |
|--------|------|-------|
| POST | `/hotels/search` | throttle:search |
| POST | `/hotels/{hotelCode}/rooms` | |
| POST | `/hotels/checkout/initiate` | throttle:booking |
| GET\|POST | `/hotels/checkout/callback` | |
| POST | `/hotels/checkout/webhook` | |
| POST | `/hotels/book` | legacy |
| POST | `/hotels/booking/{reference}/cancel` | |
| GET | `/hotels/booking/{reference}` | |

### Admin

| Method | Path | Permission |
|--------|------|------------|
| POST | `/auth/admin/login` | — |
| GET | `/auth/admin/me` | Sanctum |
| POST | `/auth/admin/logout` | Sanctum |
| * | `/admin/admins`… | `admin.*` |
| * | `/admin/roles`… | `role.*` / `permission.assign` |
| * | `/admin/permissions`… | `permission.*` |
| * | `/admin/customers`… | `customer.view` / `customer.update` |
| * | `/admin/bookings/flights`… | `booking.view` / `booking.export` |
| * | `/admin/bookings/hotels`… | `booking.view` / `booking.export` |
| * | `/admin/operations/statistics`… | `booking.view` / `customer.view` |
| * | `/admin/statistics`… | `metrics.view` |
| * | `/admin/reports`… | `reports.view` / `reports.export` |
| * | `/admin/suppliers`… | `supplier.*` |
| * | `/admin/observability`… | `api_monitor.view` |

### Pricing

| Method | Path | Auth |
|--------|------|------|
| POST | `/pricing/preview` | — |
| POST | `/pricing/breakdown` | — |
| POST | `/pricing/coupons/validate` | — |
| * | `/pricing/rules`… | admin + `pricing.*` |
| * | `/pricing/coupons`… | admin + `pricing.*` |
| * | `/pricing/analytics`… | admin + `pricing.view` |

---

## Maintenance

| Artifact | Command / path |
|----------|----------------|
| Routes | `php artisan route:list --path=api/v1` |
| Postman rebuild | `php scripts/rebuild_postman.php` |
| Permission seed | `database/seeders/data/roles_permissions.php` |
| Modules | `app/Modules/{Auth,Flights,Hotels,Operations,Reports,Pricing,SupplierPlatform,Observability,TravelCore}` |

When routes or FormRequests change, update this guide and re-run the Postman builder so all three stay aligned.

---

*Generated against the implemented V1 API. Planned features are intentionally omitted.*
