# Mobile Developer Guide (Customer)

**Audience:** Android and iOS developers integrating the Safer-Be customer app.  
**Inventory:** Phase 1 **173 LOCAL VERIFIED** HTTP-tested `/api/v1` routes. This guide documents the **customer / public** subset only.  
**Verification:** **LOCAL VERIFIED** unless marked otherwise. Staging / live FCM / Twilio Verify / TBO / MyFatoorah: **STAGING PENDING**.  
**Do not invent endpoints.** If a path is missing here, it is **NOT VERIFIED** or admin-only — see [`../frontend/API_ENDPOINT_INDEX.md`](../frontend/API_ENDPOINT_INDEX.md).

Canonical field-level contracts live in Phase 2 frontend docs. This guide is the mobile integration narrative. **Do not duplicate those files** — follow the **Doc** links.

| Concern | Canonical doc |
| --- | --- |
| Endpoint inventory | [`../frontend/API_ENDPOINT_INDEX.md`](../frontend/API_ENDPOINT_INDEX.md) |
| Auth / profile / OTP / locale | [`../frontend/AUTH.md`](../frontend/AUTH.md) |
| Device tokens / push / consent | [`../frontend/NOTIFICATIONS.md`](../frontend/NOTIFICATIONS.md) |
| Flights | [`../frontend/FLIGHTS.md`](../frontend/FLIGHTS.md) |
| Hotels | [`../frontend/HOTELS.md`](../frontend/HOTELS.md) |
| Bookings / statuses | [`../frontend/BOOKINGS.md`](../frontend/BOOKINGS.md) |
| Fulfillment status / approvals | [`../frontend/FULFILLMENT.md`](../frontend/FULFILLMENT.md) |
| Offers | [`../frontend/PROMOTIONS.md`](../frontend/PROMOTIONS.md) |
| Sell price / FX lock | [`../frontend/PRICING.md`](../frontend/PRICING.md) |
| Success envelopes | [`../frontend/RESPONSE_CONTRACTS.md`](../frontend/RESPONSE_CONTRACTS.md) |
| Errors | [`../frontend/ERROR_HANDLING.md`](../frontend/ERROR_HANDLING.md) |
| Cross-cutting UX | [`../frontend/UX_GUIDANCE.md`](../frontend/UX_GUIDANCE.md) |
| Firebase / APNs / package IDs | [`CONFIGURATION.md`](./CONFIGURATION.md) |

Push integration (FCM, consent, payload, samples): [`PUSH_NOTIFICATIONS_INTEGRATION.md`](./PUSH_NOTIFICATIONS_INTEGRATION.md). Field contracts: [`NOTIFICATIONS.md`](../frontend/NOTIFICATIONS.md) · [`CONFIGURATION.md`](./CONFIGURATION.md).

---

## Table of contents

1. [Overview](#section-1--overview)
2. [Authentication](#section-2--authentication)
3. [Profile](#section-3--profile)
4. [Notifications](#section-4--notifications)
5. [Search flights](#section-5--search-flights)
6. [Search hotels](#section-6--search-hotels)
7. [Bookings](#section-7--bookings)
8. [Offers](#section-8--offers)
9. [Loyalty points](#section-9--loyalty-points)
10. [Reference data](#section-10--reference-data)
11. [Error handling](#section-11--error-handling)
12. [Rate limiting](#section-12--rate-limiting)
13. [Idempotency](#section-13--idempotency)
14. [Testing checklist](#section-14--testing-checklist)
15. [Cross-references](#section-15--cross-references)

---

## Quick start (first 3 endpoints)

Use a local/staging `APP_URL`. Never embed Firebase **server** keys or supplier credentials in the app.

### 1. Register (no token)

`POST /api/v1/auth/register` · **PUBLIC** · **LOCAL VERIFIED** · `AuthTest`

```json
{ "name": "Ada Lovelace", "email": "ada@example.com", "password": "secret123", "password_confirmation": "secret123" }
```

Success `201`: `{ "success": true, "message": "Registration successful. Please verify your email.", "data": { "user": { "...UserResource..." } } }` — **no** Sanctum token.

### 2. Login (after email verify)

`POST /api/v1/auth/login` · **PUBLIC** · `login.throttle` · **LOCAL VERIFIED** · `AuthTest`

```json
{ "email": "ada@example.com", "password": "secret123" }
```

Success `200`: `{ "success": true, "user": { "...UserResource..." }, "token": "..." }`. Store the Bearer PAT. Default expiry **1440 minutes (24h)** (`SANCTUM_EXPIRATION`).

### 3. Search flights (public)

`POST /api/v1/flights/search` · **PUBLIC** · `throttle:search` · **LOCAL VERIFIED** · `FlightSearchRejectPropagationTest` / search feature tests

Send `AdultCount` plus origin/destination/dates (see [§5.1](#51-search)). Display sell `price.total` only. Do **not** checkout from search — call fare quote first.

Then: Fare Quote → Sanctum checkout → open `payment_url` → poll booking status.

---

## Section 1 — Overview

### Purpose

Integrate the customer mobile app against HTTP-tested Safer-Be APIs: register/login, profile, consents, FCM device tokens, flight/hotel search, checkout, my bookings, offers, and points.

### Audience

Android and iOS engineers. Admin SPA contracts are in [`../admin/ADMIN_DASHBOARD_GUIDE.md`](../admin/ADMIN_DASHBOARD_GUIDE.md) — **do not** call admin routes from the customer app.

### API base URL

- Prefix: `/api/v1`
- Full base: `{APP_URL}/api/v1` (deployment-specific; **REQUIRES MOBILE CONFIG**)
- Headers: `Accept: application/json` and `Content-Type: application/json` on JSON bodies
- Authenticated: `Authorization: Bearer {token}`

### Auth model (Sanctum)

Laravel Sanctum **personal access tokens** (Bearer). This is **not** OAuth2.  
`POST /auth/refresh` **rotates** the current PAT (new token, old revoked).  
Default expiration: `SANCTUM_EXPIRATION` = **1440 minutes**. Details: [`AUTH.md`](../frontend/AUTH.md).

### Rate limits

| Limiter | Value | Evidence |
| --- | --- | --- |
| `api` | 60 / minute / IP | `AppServiceProvider` |
| `search` | 30 / minute / IP | flights/hotels search |
| `booking` | 10 / minute / IP | checkout, booking reads, cancel |
| `login.throttle` | 5 failures / 15 minutes per email+IP | customer + admin login |
| OTP send | `6,1` | `send-otp` |
| OTP verify | `12,1` | `verify-otp` |
| Email resend | `6,1` | verification-notification |

`429` includes `retry_after` on login (`rate_limited`). See [§12](#section-12--rate-limiting).

### Response envelope

Multiple success patterns exist. Do **not** assume every payload is wrapped in `data`.  
[`RESPONSE_CONTRACTS.md`](../frontend/RESPONSE_CONTRACTS.md): Pattern A (root keys), B (`201` + `data`), C (`successPaginated`).

### Error handling

Two+ error shapes. Branch on `typeof error === 'string'` vs `error.code`.  
[`ERROR_HANDLING.md`](../frontend/ERROR_HANDLING.md). Surface `trace_id` / `X-Trace-Id`.  
`PRICING_FAILED` is HTTP **422** — do not invent a sell price.

### Access classes (mobile)

| Class | Meaning |
| --- | --- |
| **PUBLIC** | No token (search, reference, offers list, register/login) |
| **CUSTOMER_AUTHENTICATED** | Sanctum customer |
| **Challenge** | Owner Sanctum **or** guest `email` + `last_name` (never reference alone) |
| **INTERNAL** | Payment callback/webhook — **not** a mobile API |
| **DEPRECATED** | `POST .../book` → **410** — do not call |
| **ADMIN_*** | Staff only — out of scope |

---

## Section 2 — Authentication

**Controller / routes:** `app/Modules/Auth` · `AuthTest`, `AuthSecurityHardeningTest`, `PhoneVerificationApiTest`, `SetLocaleApiTest`  
**Doc:** [`AUTH.md`](../frontend/AUTH.md)

### 2.1 Register

| | |
| --- | --- |
| Method + path | `POST /api/v1/auth/register` |
| Auth / permission | none / — |
| Status | **LOCAL VERIFIED** · PUBLIC |
| Test | `AuthTest` |
| Controller | `RegisterController@register` · `RegisterRequest` |

**Request**

| Field | Required | Validation |
| --- | --- | --- |
| `name` | yes | string, max 255 |
| `email` | yes | unique |
| `password` | yes | min 8, confirmed |
| `password_confirmation` | yes | |

Phone and locale are **not** accepted on register.

**Response `201`**

```json
{
  "success": true,
  "message": "Registration successful. Please verify your email.",
  "data": { "user": { "...UserResource..." } }
}
```

**No token.** User must verify email, then login (or use the token issued on first successful signed verify — [§2.5](#25-email-verification)).

**Errors:** `422` unique email / validation. Duplicate register → unique email `422`.

### 2.2 Login

| | |
| --- | --- |
| Method + path | `POST /api/v1/auth/login` |
| Auth | none · `login.throttle` |
| Status | **LOCAL VERIFIED** · PUBLIC |
| Test | `AuthTest`, `AuthSecurityHardeningTest` |

**Request:** `email` (required), `password` (required), `token_name` (optional, max 255).

**Response `200`:** `{ "success": true, "user": { "...UserResource..." }, "token": "..." }`

**Errors**

| HTTP | When |
| --- | --- |
| 401 | Bad credentials or unverified email (read the body) |
| 403 | `account_status=suspended` — locked account, not retry |
| 429 | 5 failures / 15 min · `rate_limited` + `retry_after` |

Successful login clears the lockout counter.

### 2.3 Token refresh

| | |
| --- | --- |
| Method + path | `POST /api/v1/auth/refresh` |
| Auth | sanctum (current PAT) |
| Status | **LOCAL VERIFIED** |
| Test | `AuthTest` / session tests |
| Controller | `TokenController@refresh` |

Optional body: `{ "token_name": "ios" }`.

**Rotation:** issues a new PAT and **revokes the previous**. Store the new `token`. Not an OAuth `refresh_token` grant.

**Response:** `{ "success": true, "token": "...", "token_type": "Bearer", "expires_in": <sanctum.expiration>, "user": { ... } }`

`expires_in` is `config('sanctum.expiration')` (minutes; often `1440`).

### 2.4 Logout

| | |
| --- | --- |
| Method + path | `POST /api/v1/auth/logout` |
| Auth | sanctum |
| Status | **LOCAL VERIFIED** |
| Test | `AuthTest` |

Revokes the **current** token. On logout also `DELETE /customer/devices/{id}` for this device ([§4.3](#43-unregister-device)).

### 2.5 Email verification

| | |
| --- | --- |
| Method + path | `GET /api/v1/auth/email/verify/{id}/{hash}` |
| Auth | **signed** URL (`verification.verify`) |
| Status | **LOCAL VERIFIED** |
| Test | `AuthTest` |

Unsigned GET → **403**. Invalid hash / missing user → **404**.

**First verify `200`:**

```json
{
  "success": true,
  "message": "Email verified successfully.",
  "user": { "...UserResource..." },
  "token": "...",
  "token_type": "Bearer",
  "expires_in": 120
}
```

Already verified: `200` `{ "success": true, "message": "Email already verified." }` (no new token).

Resend (Sanctum, throttle `6,1`): `POST /api/v1/auth/email/verification-notification` · **LOCAL VERIFIED**.

### 2.6 Phone verification (OTP)

Phone is **optional**. No phone-number login. Registration does not accept phone.

| Method + path | Auth | Throttle | Status | Test |
| --- | --- | --- | --- | --- |
| `POST /api/v1/auth/phone/send-otp` | none | `6,1` | **LOCAL VERIFIED** | `PhoneVerificationApiTest` |
| `POST /api/v1/auth/phone/verify-otp` | none; attach-to-profile only when Sanctum | `12,1` | **LOCAL VERIFIED** | `PhoneVerificationApiTest` |

**Request:** `phone` (required, string 8–32). Verify also requires `code` (4–8 chars). Optional `purpose`: `verify` \| `login`.

**E.164:** Backend normalizes by stripping non-digits except `+` and prefixing `+` if missing (`E164Phone`). Tests use values such as `+201001234567`. Send E.164 from the client.

**Send success `200`:** `{ "success": true, "data": { "sent": true, ... }, "message": "..." }`  
Local **fake** provider may include `debug_code`. That field is **not** a production contract. Never display or persist a debug OTP in a store build.

**Errors**

| HTTP | `error` | When |
| --- | --- | --- |
| 429 | `otp_not_sent` | Cooldown / not sent |
| 503 | `phone_provider_unavailable` | Twilio Verify not configured |
| 422 | `otp_invalid` | Bad / expired code |
| 422 | `phone_mismatch` | Authenticated user already has a different phone |
| 422 | `phone_taken` | Number verified on another account |

Production OTP is Twilio Verify (`PHONE_PROVIDER=twilio` + server env). Fake driver is **blocked in production**. Live SMS: **STAGING PENDING** / **EXTERNAL BLOCKED** until credentials exist.

### 2.7 Password reset

| Method + path | Auth | Status | Test |
| --- | --- | --- | --- |
| `POST /api/v1/auth/forgot-password` | none | **LOCAL VERIFIED** | `AuthTest` |
| `GET /api/v1/auth/reset-password/{token}?email=` | none | **LOCAL VERIFIED** | `AuthTest` |
| `POST /api/v1/auth/reset-password` | none | **LOCAL VERIFIED** | `AuthTest` |

Forgot body: `{ "email": "..." }` (`ForgotPasswordRequest`).  
Validate token query: `email` required. Success: `{ "valid": true, "email": "...", "expires_in_minutes": 60, "locale": "..." }`. Invalid: `422` `invalid_reset_token`.  
Reset body (`ResetPasswordRequest`): `token`, `email`, `password`, `password_confirmation` (min 8). Reset **revokes all** Sanctum tokens — force re-login.

Also **LOCAL VERIFIED:** `POST /api/v1/auth/change-password` (Sanctum) — `current_password`, `password`, `password_confirmation`.

`POST /api/v1/auth/confirm-password` — **NOT VERIFIED** (no HTTP test). Skip.

### Additional verified session APIs

| Method | Path | Purpose | Status |
| --- | --- | --- | --- |
| GET | `/api/v1/auth/sessions` | List own sessions | **LOCAL VERIFIED** |
| DELETE | `/api/v1/auth/sessions/all` | Revoke all | **LOCAL VERIFIED** |
| DELETE | `/api/v1/auth/sessions/{tokenId}` | Revoke one | **LOCAL VERIFIED** |
| DELETE | `/api/v1/auth/sessions` | Revoke others | **LOCAL VERIFIED** |

### UX Guidance (auth)

Full template: [`AUTH.md` UX](../frontend/AUTH.md#ux-guidance) · [`UX_GUIDANCE.md`](../frontend/UX_GUIDANCE.md#auth-and-account)

- After register, show “verify your email” — no auto-login.
- Hide phone as required on registration.
- After 5 failed passwords, show `429` countdown from `retry_after`.
- Two independent toggles later: marketing vs push ([§3](#section-3--profile)).
- Touch targets ≥ 44×44 on Login / Verify / Consent.

---

## Section 3 — Profile

**Doc:** [`AUTH.md`](../frontend/AUTH.md) · Tests: `AuthTest`, `ProfilePhoneUpdateTest`, `PushNotificationConsentTest`

### 3.1 Get current user

| | |
| --- | --- |
| Method + path | `GET /api/v1/auth/user` |
| Auth | sanctum |
| Status | **LOCAL VERIFIED** |
| Response | `{ "success": true, "user": { "...UserResource..." } }` |

**`UserResource` fields (customer-visible):** `id`, `name`, `email`, `phone`, `email_verified_at`, `phone_verified_at`, `preferred_locale`, `account_status` (`active` \| `suspended`), `marketing_consent`, `marketing_consent_at`, `push_notification_consent` (default `false`), `push_notification_consent_at`, `roles`, `permissions`, `created_at`, `updated_at`.  
`suspended_at` / `suspended_reason` are for admin viewers.

### 3.2 Update profile

| | |
| --- | --- |
| Method + path | `PUT` or `PATCH /api/v1/auth/profile` |
| Auth | sanctum |
| Status | **LOCAL VERIFIED** |
| Request | `UpdateProfileRequest` |

**Editable:** `name`, `email`, `phone` (nullable, unique, 8–32), `preferred_locale` (max 5). All `sometimes`.

**Forbidden on this endpoint** (422): `id`, `role(s)`, `permissions`, `password*`, verification timestamps, `account_status`, both consent flags, `suspended_*`.

Success may include `email_reverification_required`, `phone_reverification_required`.

### 3.3 Marketing consent

| | |
| --- | --- |
| Method + path | `POST /api/v1/auth/marketing-consent` |
| Auth | sanctum |
| Status | **LOCAL VERIFIED** |
| Body | `{ "marketing_consent": true }` or `false` |

Marketing **email** only. Independent of push.

### 3.4 Push notification consent

| | |
| --- | --- |
| Method + path | `POST /api/v1/auth/push-notification-consent` |
| Auth | sanctum |
| Status | **LOCAL VERIFIED** |
| Test | `PushNotificationConsentTest` |
| Body | `{ "push_notification_consent": true }` or `false` |

Does **not** register an FCM token. Default is `false`.  
`PATCH /api/v1/customer/notification-preferences` **does not exist**.

---

## Section 4 — Notifications

**Doc:** [`PUSH_NOTIFICATIONS_INTEGRATION.md`](./PUSH_NOTIFICATIONS_INTEGRATION.md) · [`NOTIFICATIONS.md`](../frontend/NOTIFICATIONS.md) · [`CONFIGURATION.md`](./CONFIGURATION.md)  
**Tests:** `DeviceTokenApiTest`, `PushNotificationEventTest`, `OfferActivatedPushTest`  
**Controller:** `DeviceTokenController` · `RegisterDeviceTokenRequest`

Consent, marketing, and device tokens are **independent**. Push jobs are not dispatched when `push_notification_consent` is false, even if tokens exist.

### 4.1 Device token registration

| | |
| --- | --- |
| Method + path | `POST /api/v1/customer/devices` |
| Auth | sanctum |
| Status | **LOCAL VERIFIED** |
| HTTP | `201` if created, `200` if upsert |

**Request**

```json
{
  "token": "fcm_registration_token",
  "platform": "android",
  "device_id": "optional-stable-device-id",
  "app_version": "1.0.0"
}
```

| Field | Required | Validation |
| --- | --- | --- |
| `token` | yes | string, 8–512 |
| `platform` | yes | `android` \| `ios` only (`web` → `422`) |
| `device_id` | no | max 191 |
| `app_version` | no | max 32 |

Same FCM token is upserted. Token previously tied to another user is reassigned. Full token is **never** returned.

**Response `data`:** `id`, `platform`, `device_id`, `app_version`, `token_hint`, `last_used_at`, `created_at`.

**Token refresh:** if FCM rotates the token, `POST` again with the new token.

### 4.2 List devices

`GET /api/v1/customer/devices` · Sanctum · **LOCAL VERIFIED** · own devices only · `{ "success": true, "data": [ ... ] }`

### 4.3 Unregister device

`DELETE /api/v1/customer/devices/{device}` · Sanctum · **LOCAL VERIFIED**  
`{device}` is numeric `id` (`whereNumber`), **not** the FCM string. Other user’s id → **404**.

On logout: unregister this device, then `POST /auth/logout`.

### 4.4 Push notification payload

Title/body are display strings. `data` is **string-only**:

| Key | Meaning |
| --- | --- |
| `type` | `booking.request_confirmed`, `booking.confirmed`, `fulfillment.failed`, `refund.completed`, `customer.approval_required`, `offer.activated` |
| `booking_reference` | Transactional types |
| `product_type` | `flight` or `hotel` when known |
| `offer_id` | String numeric id (`offer.activated`) |
| `offer_type` | `global` \| `destination` \| `airline` \| `route` |
| `deep_link` | Optional; **omitted** until product defines a URL scheme |

Do not put payment credentials, PII dumps, or Firebase keys in `data`.

Live FCM requires server `NOTIFICATIONS_ENABLED`, `NOTIFICATIONS_PUSH_ENABLED`, `FIREBASE_ENABLED`, plus consent + tokens. Tests use LogOnly (`FIREBASE_ENABLED=false`). Delivery: **STAGING PENDING**.

### 4.5 Deep link handling

| Topic | Current behavior |
| --- | --- |
| URL scheme | **Not defined** by this backend. `deep_link` is omitted. |
| Route mapping | Use `data.type` + `booking_reference` / `offer_id`. |
| Cold vs warm start | **MOBILE CONFIG REQUIRED** — OS responsibility. |

**UX recommendation:** `offer.activated` → public offers list or offer id. `customer.approval_required` → status screen. `booking.*` → booking detail.

### 4.6 Cross-reference

- [`PUSH_NOTIFICATIONS_INTEGRATION.md`](./PUSH_NOTIFICATIONS_INTEGRATION.md) — FCM setup, token flow, payload, Kotlin/Swift samples
- [`NOTIFICATIONS.md`](../frontend/NOTIFICATIONS.md)
- [`CONFIGURATION.md`](./CONFIGURATION.md) (Android package / iOS bundle / APNs: **REQUIRES MOBILE CONFIG**)

### UX Guidance (notifications)

[`NOTIFICATIONS.md` UX](../frontend/NOTIFICATIONS.md#ux-guidance)

1. OS permission (Android 13+) → `POST` push consent `true` → obtain FCM → `POST /devices`.
2. Disable: consent `false`. Unregister device on logout (does not change consent).
3. Empty device list after login is valid.

---

## Section 5 — Search flights

**Doc:** [`FLIGHTS.md`](../frontend/FLIGHTS.md) · [`PRICING.md`](../frontend/PRICING.md)  
**Tests:** `FlightCheapestFastestApiTest`, `FlightSearchRejectPropagationTest`, fare-quote / search feature tests

```text
Search / cheapest / fastest  →  Fare Quote  →  Checkout (Sanctum)  →  payment_url
```

`POST /api/v1/flights/book` → **410** `legacy_booking_disabled`. **Do not call.**

### 5.1 Search

| | |
| --- | --- |
| Method + path | `POST /api/v1/flights/search` |
| Auth | none · `throttle:search` (30/min/IP) |
| Status | **LOCAL VERIFIED** · PUBLIC |
| Request | `SearchFlightRequest` |

**Core body (PascalCase TBO-style supported)**

| Field | Required | Notes |
| --- | --- | --- |
| `AdultCount` | **yes** | 1–9 |
| `Origin` / `Destination` | conditional | size 3 when `Segments` omitted |
| `DepartureDate` | conditional | ≥ today |
| `ReturnDate` | no | after DepartureDate |
| `JourneyType` | no | `1` OW, `2` RT, `3` multi-city |
| `ChildCount` / `InfantCount` | no | 0–9 |
| `Segments` | conditional | multi-city |
| `FlightCabinClass` | no | 0–4 |
| `currency` / `Currency` | no | size 3 |
| `PreferredAirlines` | no | IATA size 2 |
| `filters` | no | airlines, stops, price, baggage |
| `page` / `per_page` | controller | pagination slice |

**Response:** Pattern C plus search keys (`supplier`, `journey_type`, `flights` / results, `search_id`, `facets`, …). Use returned `result_index` / `reference_index` / `id`. **Search price is not payment authority.**

### 5.2 Cheapest

`POST /api/v1/flights/cheapest` · same `SearchFlightRequest` · sort by `price.total` ascending · `limit` default **1** · **LOCAL VERIFIED** · `FlightCheapestFastestApiTest`  
Success: `supplier`, `journey_type`, `flights`, `total_available`, `limit`, `search_id`, `facets`. Empty body → `422`.

### 5.3 Fastest

`POST /api/v1/flights/fastest` · same request · sort by sum of `legs[].duration_minutes` · `limit` default **1** · **LOCAL VERIFIED**.

### 5.4 Fare quote

`POST /api/v1/flights/fare-quote` · **PUBLIC** · **LOCAL VERIFIED**

**Body (`FareQuoteRequest`):** `result_index` XOR `reference_index`; optional `search_id`, `currency` (size 3).

**Response (`PublicFareQuoteResource`):** `result_index`, `flight` (`total_price`, `base_fare`, `tax`, `other_charges`, `currency`, `is_refundable`, `segments`, …), `expires_in`, `supplier`, FX fields, `price_changed`.

- Send fare-quote `result_index` as checkout `result_id`.
- FX lock default **30 minutes** (`price.locked_until`). Cache hit does not take a new snapshot.
- `price_changed`: `true` when fare-quote sell ≠ persisted search sell (tolerance 0.01) — stale-price protection, not a second markup.

**Errors:** `409` price change (`confirm_new_price`); `410` expired (`search_again`); `422` `PRICING_FAILED`. See [`ERROR_HANDLING.md`](../frontend/ERROR_HANDLING.md).

### 5.5 Price shape

Public sell object ([`PRICING.md`](../frontend/PRICING.md)):

```json
{
  "total": 1514,
  "currency": "USD",
  "base_fare": 1100,
  "taxes": 300,
  "supplier_charges": 100,
  "other_charges": 100,
  "markup_amount": 100,
  "tax_on_markup": 14,
  "locked_until": "2026-09-19T12:00:00+00:00",
  "fx_rate_used": 1.0,
  "fx_rate_timestamp": "2026-09-19T11:30:00+00:00"
}
```

Identity: `total = base_fare + taxes + supplier_charges + markup_amount + tax_on_markup`.  
`other_charges` aliases `supplier_charges`. Display as returned. **Do not** convert FX locally. **Do not** compute markup.

### 5.6 UX Guidance (flights)

[`FLIGHTS.md` UX](../frontend/FLIGHTS.md#ux-guidance)

| State | Guidance |
| --- | --- |
| Loading | Disable Search while in flight. Orchestration can exceed 30s — keep wait visible; do not double-submit. |
| Empty | `flights: []` can still be `200`. Reset filters. Do not call cheapest/fastest as a “fix”. |
| `PRICING_FAILED` | 422 + `support_code` (`PRC-{YYYY}-{seq}`). New search. Never checkout. |
| Fare quote | If `price_changed`, replace the card total. |
| Auth | Checkout `401` → login, then initiate (new idempotency key if the first never created a booking). |

---

## Section 6 — Search hotels

**Doc:** [`HOTELS.md`](../frontend/HOTELS.md) · Tests: `HotelRoomsApiTest`, hotel search/pricing tests  
Supplier codes: `tbo_hotels`, `juniper`.

`POST /api/v1/hotels/book` → **410**. **Do not call.**

### 6.1 Search

`POST /api/v1/hotels/search` · **PUBLIC** · `throttle:search` · **LOCAL VERIFIED** · `SearchHotelRequest`

| Field | Required | Notes |
| --- | --- | --- |
| `check_in` / `check_out` | **yes** | check_in ≥ today; check_out after check_in |
| `city_code` | required without `hotel_code` | |
| `adults` | no | 1–20 |
| `children` | no | 0–10 |
| `child_ages` | no | 0–17 |
| `nationality` | no | size 2 |
| `currency` / `supplier` / `filters` | no | |
| `page` / `per_page` | no | per_page ≤ 100 |

**Response:** `hotels`, `total`; may include `facets`, `search_id`, `supplier`.  
Hotel-level `min_price` is a **starting display**, not checkout authority (not passed through `applyPricingToHotels`). Nested `rooms[]` are typically **absent** on the list. Card schema is supplier-dependent (**UNCERTAIN** for one rigid schema).

### 6.2 Rooms

`POST /api/v1/hotels/{hotelCode}/rooms` · **PUBLIC** · **LOCAL VERIFIED** · `HotelRoomsApiTest` · `GetHotelRoomsRequest`

**Body:** `check_in` / `check_out` (yes), `guests` (yes; `guests[].adults` required), optional `supplier`, `currency`, `nationality`, `search_id`.

**Success:** `hotel_code`, `check_in`, `check_out`, `rooms`, `total`. Empty body → `422`. `total: 0` is a valid `200`.

**Preserve identity:** `room_id` / `room_code`, `room_type_code`, `rate_plan_code` (critical for Juniper), `room_index`. Do **not** invent identifiers.

| Case | Backend | Client |
| --- | --- | --- |
| Identity cannot rematch | Abort | Re-fetch rooms |
| Price differs, identity matches | **LOG-ONLY** today | Do not invent failure UI unless API errors |

### 6.3 UX Guidance (hotels)

[`HOTELS.md` UX](../frontend/HOTELS.md#ux-guidance)

List → Rooms → pick rate (keep identity in client state) → Sanctum checkout.  
Show rooms `total_price` as sell. Do not treat list `min_price` as payable.  
Live TBO rooms: **STAGING PENDING**.

Also **LOCAL VERIFIED:** `GET /api/v1/hotels/reference/top-destinations` (optional `country_code`, default EG).

---

## Section 7 — Bookings

**Docs:** [`FLIGHTS.md`](../frontend/FLIGHTS.md) · [`HOTELS.md`](../frontend/HOTELS.md) · [`BOOKINGS.md`](../frontend/BOOKINGS.md) · [`FULFILLMENT.md`](../frontend/FULFILLMENT.md)

Default: `CHECKOUT_REQUIRES_AUTH=true`. Checkout initiate is `auth:sanctum` + `throttle:booking`.

### 7.1 Flight checkout

`POST /api/v1/flights/checkout/initiate` · Sanctum · **LOCAL VERIFIED** · `BookFlightRequest`

**Body (summary):** `result_id` (yes — fare-quote `result_index`), `passengers` (yes, 1–9; `gender` **`1` or `2` only**), optional `supplier`, `currency`, `flight` / `flight_result`, `journey_type`, `promo_code` (max 50), `points_to_redeem` (≥0). Passport expiry ≥ departure + 6 months.

**Idempotency:** header `Idempotency-Key` or `X-Idempotency-Key`, or body `idempotency_key` (max 128). Unique per authenticated user. See [§13](#section-13--idempotency).

Do **not** send `callback_url` / `error_url` — ignored. Server owns MyFatoorah return URLs.

**Success**

```json
{ "success": true, "booking_reference": "...", "payment_url": "https://...", "message": "..." }
```

Backend owns price lock, promo (if `OFFERS_ENABLED`), MyFatoorah amount. Client `flight.totalPrice` is **not** payment authority.

### 7.2 Hotel checkout

`POST /api/v1/hotels/checkout/initiate` · Sanctum · `throttle:booking` · **LOCAL VERIFIED** · `BookHotelRequest`

**Body (summary):** `hotel_code`, `check_in`, `check_out`, `rooms` (min 1) with `room_code`, `meal_plan`, `guests`; pass `room_type_code` / `rate_plan_code` / `room_index` from rooms API; optional `promo_code`, `points_to_redeem`, `search_id`, `supplier`, contact fields. Same idempotency as flights.

**Success:** `{ "success": true, "payment_url": "...", "booking_reference": "...", "message": "..." }`

### 7.3 Payment callback

| Method | Path | Audience | Status |
| --- | --- | --- | --- |
| GET/POST | `/api/v1/flights/checkout/callback` | Browser return (`paymentId`) | **LOCAL VERIFIED** · **INTERNAL** |
| POST | `/api/v1/flights/checkout/webhook` | MyFatoorah HMAC | **LOCAL VERIFIED** · **INTERNAL** |
| GET/POST | `/api/v1/hotels/checkout/callback` | Browser return | **LOCAL VERIFIED** · **INTERNAL** |
| POST | `/api/v1/hotels/checkout/webhook` | MyFatoorah HMAC | **LOCAL VERIFIED** · **INTERNAL** |

**Not mobile endpoints.** Open `payment_url` in a secure browser session (Custom Tab / SFSafariViewController). After return, **poll** booking / status. Do **not** treat the redirect as PAID.  
`/myfatoorah*` and `/test-payment*` are **NON-CONTRACT**.

Webhook success body: `{ "status": "Webhook received" }` (not the usual envelope).

### 7.4 My bookings

`GET /api/v1/customer/my-bookings` · Sanctum · own only · **LOCAL VERIFIED** · Pattern C

| Query | Default | Notes |
| --- | --- | --- |
| `page` | 1 | |
| `per_page` | 15 | 1–100 |
| `type` | `all` | `all` \| `flight(s)` \| `hotel(s)` |

**Item fields:** `booking_number`, `booking_type`, `status`, `supplier`, `price`, `locked_sell_price`, `currency`, `created_at`, `payment_status`, `price_change_status`, `fulfillment_status`, `customer_booking_status`. Flight extras: `pnr`, `ticket_number`, `is_refundable`. Hotel extras: `hotel_code`, `hotel_name`, `check_in`, `check_out`, `confirmation_number`.

### 7.5 Booking status

`GET /api/v1/customer/bookings/{reference}/status` · Sanctum · own `user_id` · **LOCAL VERIFIED**

`data`: `booking_reference`, `product_type`, `payment_status`, `booking_status`, `fulfillment_status`, `customer_booking_status`, `sla_due_at`, `approval_id`, `pending_approval`, `timeline[]`.

**Customer-visible UI statuses (4)** — keep separate from payment / fulfillment vocabularies:

| `customer_booking_status` | When |
| --- | --- |
| `pending` | Before / during payment |
| `booking_request_confirmed` | After PAID orchestration |
| `awaiting_customer_approval` | Ops requested a decision |
| `final_confirmed` | Confirmed/ticketed or fulfillment fulfilled |

**Polling:** after payment return, poll this (or product detail) with backoff. Fulfillment can take minutes/hours — not a blocking spinner. Do not invent “ticketed immediately after pay”.

### 7.6 Booking detail

| Method + path | Auth | Status |
| --- | --- | --- |
| `GET /api/v1/flights/booking/{reference}` | Challenge (owner **or** guest `email` + `last_name`) | **LOCAL VERIFIED** |
| `GET /api/v1/hotels/booking/{reference}` | Challenge | **LOCAL VERIFIED** |
| `GET /api/v1/flights/booking/{reference}/invoice` | Challenge | **LOCAL VERIFIED** · binary |
| `GET /api/v1/flights/booking/{reference}/ticket` | Challenge | **LOCAL VERIFIED** · binary |

`total_price` prefers `locked_sell_price`. PNR / confirmation may be **null** until fulfillment succeeds.

### 7.7 Cancel hotel

`POST /api/v1/hotels/booking/{reference}/cancel` · Sanctum · owner · **LOCAL VERIFIED**  
Optional body `reason`. Supplier cancel keys are supplier-dependent (**UNCERTAIN** for a fixed schema).

### 7.8 Flight refund / release

| Method + path | Auth | Status | Notes |
| --- | --- | --- | --- |
| `POST /api/v1/flights/booking/{reference}/refund` | Sanctum · owner or staff | **LOCAL VERIFIED** | optional `amount`, `reason` |
| `POST /api/v1/flights/booking/{reference}/release` | Sanctum · owner or staff | **LOCAL VERIFIED** | Release PNR |
| `POST /api/v1/flights/ticket` | Sanctum · owner or staff | **LOCAL VERIFIED** | `pnr` XOR `booking_reference` |

Ownership/mutation checks apply. Customer apps should not expose staff-only paths as primary UX.

### 7.9 Customer approvals

`POST /api/v1/customer/approvals/{id}/respond` · Sanctum · **LOCAL VERIFIED**  
When `customer_booking_status` / fulfillment is `awaiting_customer_approval`.

| Field | Required | Validation |
| --- | --- | --- |
| `approved` | yes | boolean |
| `channel` | no | max 50 |

Ownership: fulfillment `user_id` must match. Payload may include `approval_id`, `decision`, `price_impact`, `proposed_option`, `original_option`, `expires_at`, `decided_at`, `channel`. Do not show supplier cost / margins (`PhaseOneApiContractTest` leak guard).

### 7.10 UX Guidance (bookings)

[`BOOKINGS.md` UX](../frontend/BOOKINGS.md#ux-guidance) · [`FULFILLMENT.md` UX](../frontend/FULFILLMENT.md#ux-guidance)

```text
Search → Quote/Rooms → Checkout → open payment_url → return to app → poll status
```

- Never mark PAID from the redirect alone.
- Keep payment / booking / fulfillment / customer statuses **separate**.
- Duplicate checkout: same idempotency key.
- Pull-to-refresh only on safe GETs (`my-bookings`, devices). Do not re-POST checkout.

---

## Section 8 — Offers

**Doc:** [`PROMOTIONS.md`](../frontend/PROMOTIONS.md) · Tests: `OffersApiContractTest`, `CheckoutPromoCodeTest`

### 8.1 Available offers

`GET /api/v1/offers/available` · **PUBLIC** · **LOCAL VERIFIED**

`PublicOfferResource` does **not** expose `code`. Listing is **not** gated by `OFFERS_ENABLED` (default **`false`**). When the flag is false, checkout **does not** apply discounts even if `promo_code` is sent.

Response shape: [`PROMOTIONS.md`](../frontend/PROMOTIONS.md) (`id`, `name`, `type`, `discount_*`, `conditions`, `gallery`).

### 8.2 Promo code application

Send optional `promo_code` (max 50, normalized uppercase) on **checkout initiate** only.  
**There is no standalone validate endpoint.** Do not invent one.

### 8.3 Offer push notifications

When an offer **becomes** `status=active`, backend dispatches `OfferActivated` → `FanOutConsentedPush` → per consented user. **LOCAL VERIFIED** at job/listener layer (`OfferActivatedPushTest`).  
`POST /admin/offers/{id}/activate` HTTP is **NOT VERIFIED** — not a mobile concern.

Payload: `type=offer.activated`, `offer_id`, `offer_type`. No `deep_link` today.

### 8.4 UX Guidance (offers)

[`PROMOTIONS.md` UX](../frontend/PROMOTIONS.md#ux-guidance)

- Show marketing cards from the public list.
- Code entry at checkout (campaign / deep link / support).
- Display **backend** payable after initiate — not a client-estimated discount.
- Empty `data: []` is success.

---

## Section 9 — Loyalty points

**Module:** `app/Modules/Loyalty` · Tests: `LoyaltyApiContractTest`, `CheckoutPointsTest`, `PublicBookingAccessSecurityTest`  
**Flag:** `POINTS_ENABLED` (`loyalty.enabled`, default **`false`**).

### 9.1 Balance

`GET /api/v1/customer/points` · Sanctum · **LOCAL VERIFIED** · `CustomerPointsController@balance`

```json
{
  "success": true,
  "data": {
    "balance": 0,
    "lifetime_earned": 0,
    "lifetime_redeemed": 0
  }
}
```

Unauthenticated → `401`.

### 9.2 History

`GET /api/v1/customer/points/history` · Sanctum · **LOCAL VERIFIED** · Pattern C · `per_page` default 25

**Row (`CustomerPointsTransactionResource`):** `id`, `type`, `amount`, `balance_after`, `booking_reference`, `reason`, `created_at`.  
**Not exposed:** `idempotency_key`, `admin_id`, `wallet_id`, `metadata`, `user_id`.

### 9.3 Redeem at checkout

Optional `points_to_redeem` (≥0) on flight/hotel initiate. Client values are **not** authoritative. Pipeline applies after sell + offer (when enabled).

| Config | Env | Default (code) |
| --- | --- | --- |
| Enabled | `POINTS_ENABLED` | `false` |
| Redeem ratio | `LOYALTY_REDEEM_RATIO` | `0.10` |
| Min points | `LOYALTY_MIN_REDEEM_POINTS` | `100` |
| Max % of sell | `LOYALTY_MAX_REDEEM_PERCENT` | `50` |

`CheckoutPointsTest` (service, not HTTP): 200 points × 0.10 = 20.00 off 1000 → 980, when min is 50 in that test config. Confirm environment before promising redemption UX. Payment-fail restores points once (`points_reverted_on_payment_fail`).

---

## Section 10 — Reference data

**Tests:** `ReferenceListApiTest`, `SetLocaleApiTest`, `CitiesEndpointTest`  
**Doc:** [`AUTH.md` locale](../frontend/AUTH.md#locale--reference) · [`FLIGHTS.md`](../frontend/FLIGHTS.md)

| Method | Path | Status | Notes |
| --- | --- | --- | --- |
| GET | `/api/v1/countries` | **LOCAL VERIFIED** | `successPaginated`; `iso2`, localized `name` |
| GET | `/api/v1/currencies` | **LOCAL VERIFIED** | `{ data, meta.count }` — **not** paginated links |
| GET | `/api/v1/airlines` | **LOCAL VERIFIED** | paginated; DTO `iataCode` camelCase |
| GET | `/api/v1/airlines/suggest` | **LOCAL VERIFIED** | |
| GET | `/api/v1/airlines/autocomplete` | **LOCAL VERIFIED** | |
| GET | `/api/v1/airports/suggest` | **LOCAL VERIFIED** | |
| GET | `/api/v1/destinations/autocomplete` | **LOCAL VERIFIED** | |
| GET | `/api/v1/flights/airports` | **LOCAL VERIFIED** | |
| GET | `/api/v1/flights/airports/autocomplete` | **LOCAL VERIFIED** | |
| GET | `/api/v1/cities` | **LOCAL VERIFIED** | filterable, paginated |
| POST | `/api/v1/set-locale` | **LOCAL VERIFIED** | `{ "locale": "en" \| "ar" }` → `{ success, locale, direction }` (`ltr`/`rtl`). Sanctum user: updates `preferred_locale`. Unsupported → `422`. |

**NOT VERIFIED (skip):** `GET /cities/{city}/airports`, flight zones/nearby/`{code}`, hotel autocomplete/mappings.

---

## Section 11 — Error handling

**Doc:** [`ERROR_HANDLING.md`](../frontend/ERROR_HANDLING.md) — do not re-implement a third shape.

**Shape 1** (renderer): `{ success: false, error: { code, message, details }, trace_id, status_code }` + `X-Trace-Id`.  
**Shape 2** (trait): `{ success: false, error: "forbidden", message: "..." }` — `error` is a **string**. Validation may use top-level `errors`.

| HTTP | Typical |
| --- | --- |
| 401 | Missing/invalid token |
| 403 | Permission / ownership / signed-url / suspended |
| 404 | Not found; device delete for another user’s id |
| 409 | Fare-quote price change; payment reconciliation |
| 410 | Legacy `/book`; fare quote expired |
| 422 | Validation, TBO business, **`PRICING_FAILED`** |
| 429 | Throttle |
| 503 | Phone provider / some TBO unavailable |

**`PRICING_FAILED`:** 422, `error.code=PRICING_FAILED`, `details.support_code`, `details.context` (`flight_booking` / `hotel_booking`). Show message + support code. New search. Never invent a total.

**Retry:** safe GETs and search POSTs after backoff. Checkout only with the **same** idempotency key. Do not retry login through lockout.

---

## Section 12 — Rate limiting

| Scope | Limit | Endpoints |
| --- | --- | --- |
| Global `api` | 60/min/IP | Most `/api/v1` |
| `search` | 30/min/IP | Flight/hotel search, cheapest, fastest |
| `booking` | 10/min/IP | Checkout, booking detail, cancel, ticket |
| Login | 5 failures / 15 min / email+IP | `/auth/login` (and admin login — not used by this app) |
| OTP | 6 send / min, 12 verify / min | Phone OTP |
| Email resend | 6/min | Verification notification |

**Backoff:** honor `retry_after` / `cooldown_seconds`. After `429` on search, wait before re-POST. Do not spin.

---

## Section 13 — Idempotency

On `POST .../checkout/initiate` (flights and hotels):

| Mechanism | Name |
| --- | --- |
| Header | `Idempotency-Key` **or** `X-Idempotency-Key` |
| Body | `idempotency_key` |

Max length **128**. Authenticated uniqueness: `(user_id, idempotency_key)`. Retrying the same key should not create a second checkout when a booking exists. If omitted, flights may fingerprint passengers + result — still send an explicit key.

---

## Section 14 — Testing checklist

| # | Call | Expect | Edge |
| --- | --- | --- | --- |
| 1 | `POST /auth/register` | `201`, no token | Duplicate email `422` |
| 2 | Signed `GET /auth/email/verify/{id}/{hash}` | `200` + token on first verify | Unsigned `403` |
| 3 | `POST /auth/login` | `200` + token | 5th fail → `429` |
| 4 | `POST /auth/refresh` | New token; old 401 | Store rotation |
| 5 | `GET /auth/user` | Consents default false | |
| 6 | `PUT /auth/profile` | Editable fields only | Forbidden fields `422` |
| 7 | `POST /auth/push-notification-consent` | `true` | Independent of marketing |
| 8 | `POST /customer/devices` | `201`, no raw token | `platform=web` → `422` |
| 9 | `GET /customer/devices` | `token_hint` only | |
| 10 | `DELETE /customer/devices/{id}` | Own id | Other user `404` |
| 11 | `POST /flights/search` | Sell prices | `PRICING_FAILED` 422 |
| 12 | `POST /flights/cheapest` + `/fastest` | Sorted subset | Empty body `422` |
| 13 | `POST /flights/fare-quote` | `result_index`, `price_changed` | 409 / 410 |
| 14 | `POST /hotels/search` then `/{code}/rooms` | Rooms priced | `min_price` ≠ payable |
| 15 | Checkout + `Idempotency-Key` | `payment_url` | Replay same key |
| 16 | `GET /customer/my-bookings` | Paginated | `type=hotel` |
| 17 | `GET .../status` | 4 customer statuses | Poll, don’t assume PAID |
| 18 | Challenge GET booking | Owner or email+last_name | Reference alone fails |
| 19 | `GET /offers/available` | Public list, no `code` | Empty `[]` |
| 20 | `GET /customer/points` | Balance object | `401` without token |
| 21 | `POST /set-locale` | `direction` | Bad locale `422` |
| 22 | Payment return | Poll status | Redirect ≠ PAID |

---

## Section 15 — Cross-references

| Doc | Use |
| --- | --- |
| [`../frontend/README.md`](../frontend/README.md) | Hub, CAN / MUST NOT |
| [`../frontend/API_ENDPOINT_INDEX.md`](../frontend/API_ENDPOINT_INDEX.md) | 173 LOCAL VERIFIED inventory |
| [`CONFIGURATION.md`](./CONFIGURATION.md) | Firebase / APNs / consent sequence |
| [`../admin/ADMIN_DASHBOARD_GUIDE.md`](../admin/ADMIN_DASHBOARD_GUIDE.md) | Staff SPA (do not call from customer app) |
| [`../operations/RELEASE_READINESS_CHECKLIST.md`](../operations/RELEASE_READINESS_CHECKLIST.md) | Staging gate |

---

## Verification legend

| Status | Meaning |
| --- | --- |
| **LOCAL VERIFIED** | Route + HTTP test in this repo (Phase 1/2) |
| **STAGING PENDING** | Live FCM, Twilio Verify, TBO, MyFatoorah, FX |
| **NOT VERIFIED** | Routed but no HTTP test — **skipped** |
| **INTERNAL** | Gateway/callback — not a mobile feature |
| **DEPRECATED** | `POST .../book` → 410 |

**Skipped (NOT VERIFIED):** `POST /auth/confirm-password`; public `GET /settings`; flight zones/nearby/`{code}`/flight-types; hotel autocomplete/mappings; `PATCH /customer/notification-preferences` (does not exist).

**Customer app MUST NOT:** calculate markup/margin; set MyFatoorah amount; call `/pricing/preview`; call admin APIs; call supplier Book; trust redirect as PAID; store Firebase server keys.
