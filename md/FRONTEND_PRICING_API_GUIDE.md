# Safer-Be Pricing API — Frontend Integration Guide

**Status:** VERIFIED FROM IMPLEMENTATION (audit 2026-09-16)  
**Base path:** `/api/v1`  
**Audience:** Admin Pricing UI + customer flights engineers  
**Related:** [`FRONTEND_FLIGHTS_API_GUIDE.md`](./FRONTEND_FLIGHTS_API_GUIDE.md), [`frontend/PRICING.md`](./frontend/PRICING.md), [`modules/Pricing.md`](./modules/Pricing.md)

This document describes **only** behavior confirmed in the current Laravel source, routes, validators, and automated tests. It does not invent endpoints, fields, or wallet products.

---

# 1. Overview

Pricing is a **server-side** module that converts supplier amounts into the **customer sell price**.

Admin controls Pricing Rules (CRUD, activation, schedule, priority, configuration). The customer UI **displays** sell prices returned by Flights Search / Fare Quote. The Admin UI manages rules and may use Analytics / Preview tools.

```text
Supplier amount
  → currency normalization
  → Pricing Rules (or legacy MarkupEngine fallback)
  → Margin Guard
  → tax on markup (when markup > 0)
  → Customer sell price
```

**Frontend must not calculate markup.** Always display `price.total` / Fare Quote `flight.total_price` / locked checkout amount from the server.

Gate: `config('pricing.enabled')` ← env `PRICING_ENGINE_ENABLED` (default **false**). When disabled, Search/Fare Quote return supplier amounts as sell and `price.pricing.applied` is `false`.

---

# 2. Pricing Architecture

```text
Supplier Price
     ↓
Pricing Engine (PricingIntegrationService::priceFlight)
     ↓
Customer Sell Price
     ↓
Search  (POST /flights/search)     → price.total (sell)
     ↓
Fare Quote / Recheck  (POST /flights/fare-quote)
     ↓
Price Lock  (created inside checkout initiate — no public lock API)
     ↓
Checkout  (POST /flights/checkout/initiate)
     ↓
MyFatoorah invoice
     ↓
Payment Confirmation (GetPaymentStatus authoritative)
     ↓
Fulfillment request (assisted — NOT supplier book)
     ↓
Loyalty PointsWallet earn  (only after FulfillmentCompleted — see §18)
```

There is **no** separate prepaid cash “Safer-Be Wallet” credited on MyFatoorah success. See §18.

---

# 3. Important Pricing Rules

```text
Frontend does NOT calculate markup.
Frontend displays backend-calculated sell price.
Supplier cost is internal (not on public Search/Fare Quote).
Markup percentage is internal (not on public Search/Fare Quote).
Pricing rule IDs are internal (Admin rules/analytics only; not customer Search cards).
```

Public Search exposes only:

```json
"pricing": { "applied": true }
```

`applied` means the Pricing engine flag is on (`pricing.enabled`), **not** that a specific rule matched, and **not** a markup amount.

---

# 4. Admin Permissions

Source: `app/Modules/Auth/Enums/Permission.php` + seed `database/seeders/data/roles_permissions.php`.

| Permission | Used by |
|------------|---------|
| `pricing.view` | `GET /pricing/rules`, `GET /pricing/rules/{id}`, analytics |
| `pricing.create` | `POST /pricing/rules` |
| `pricing.update` | `PUT` / `PATCH /pricing/rules/{id}` |
| `pricing.delete` | `DELETE /pricing/rules/{id}` |

Seeded access (do **not** hard-code UI from role names alone — use `user.permissions` from Admin login / `GET /auth/admin/me`):

| Role | pricing.* |
|------|-----------|
| `super_admin` | all |
| `operations` | view, create, update (no delete) |
| `finance` | view, create, update, delete |
| `admin` / `devops` | none in seed |

Middleware: `auth:sanctum` + `permission:…` (`CheckPermission`).

Public `POST /pricing/preview` and `POST /pricing/breakdown`: **no** auth, **no** permission (throttle only).

---

# 5. Endpoint Reference

Routes: `app/Modules/Pricing/routes.php`.

## `POST /api/v1/pricing/preview`

**Authentication:** none  
**Permission:** none  
**Throttle:** `pricing.preview_rate_limit` (default 30/min)  
**Purpose:** Non-persisting price calculation tool (Admin/diagnostics). **Not** booking authority.

**Request:** see `PricePreviewRequest`  
**Response:** `success: true` + nested `data` object with supplier/markup/tax/grand_total (includes commercial fields — **do not show to customers**).

## `POST /api/v1/pricing/breakdown`

Identical contract to preview (same `PricingPreviewService::preview`).

## `GET /api/v1/pricing/rules`

**Authentication:** Bearer admin  
**Permission:** `pricing.view`  
**Purpose:** Paginated list (`per_page` default 20). Ordered by `priority`, then `id`.

## `POST /api/v1/pricing/rules`

**Authentication:** Bearer admin  
**Permission:** `pricing.create`  
**Purpose:** Create a Pricing Rule. Side effect: `PricingCacheInvalidator::forgetDynamicRules()` (Search fingerprint bump).

## `GET /api/v1/pricing/rules/{rule}`

**Authentication:** Bearer admin  
**Permission:** `pricing.view`  
**Path:** `{rule}` = numeric rule id.

## `PUT|PATCH /api/v1/pricing/rules/{rule}`

**Authentication:** Bearer admin  
**Permission:** `pricing.update`  
**Side effect:** cache invalidation (same as create).

## `DELETE /api/v1/pricing/rules/{rule}`

**Authentication:** Bearer admin  
**Permission:** `pricing.delete`  
**Response:** `204` with `success` / message body via `noContent`.  
**Side effect:** cache invalidation.

## `GET /api/v1/pricing/analytics/logs`

**Authentication:** Bearer admin  
**Permission:** `pricing.view`  
**Query:** `priceable_type`, `product_type`, `priceable_id`, `supplier`, `currency`, `rule_id`, `from`, `to`, `per_page` (1–100).

## `GET /api/v1/pricing/analytics/summary`

**Authentication:** Bearer admin  
**Permission:** `pricing.view`  
**Response fields:** `total_rules_applied`, `avg_markup_24h`, `recent_logs_24h`.

### Not routed (controllers exist, no HTTP)

`Admin\CouponController`, `Public\CouponController` — **not** part of the live Pricing HTTP surface.

---

# 6. Request Examples

## Create percentage supplier markup

```http
POST /api/v1/pricing/rules
Authorization: Bearer {{admin_token}}
Content-Type: application/json
```

```json
{
  "name": "TBO supplier 10%",
  "description": "Supplier-level markup for TBO flights",
  "type": "supplier_markup",
  "priority": 10,
  "configuration": {
    "adjustment_type": "percentage",
    "adjustment_value": 10,
    "supplier_codes": ["tbo"],
    "scope": {
      "product_type": "flight"
    }
  },
  "is_active": true,
  "starts_at": null,
  "ends_at": null
}
```

## Create fixed airline markup

```json
{
  "name": "MS fixed SAR 25",
  "type": "airline_markup",
  "priority": 20,
  "configuration": {
    "adjustment_type": "fixed",
    "adjustment_value": 25,
    "currency": "SAR",
    "airline_codes": ["MS"],
    "scope": { "product_type": "flight" }
  },
  "is_active": true
}
```

## Create route markup

```json
{
  "name": "CAI-DXB 5%",
  "type": "route_markup",
  "priority": 15,
  "configuration": {
    "adjustment_type": "percentage",
    "adjustment_value": 5,
    "routes": [{ "origin": "CAI", "destination": "DXB" }],
    "scope": { "product_type": "flight" }
  }
}
```

## Scheduled window

```json
{
  "name": "Weekend promo window",
  "type": "weekend_surge",
  "priority": 5,
  "configuration": {
    "adjustment_type": "percentage",
    "adjustment_value": 15,
    "days": [5, 6],
    "scope": { "product_type": "flight" }
  },
  "is_active": true,
  "starts_at": "2026-09-20T00:00:00+00:00",
  "ends_at": "2026-09-30T23:59:59+00:00"
}
```

## Deactivate (update)

```json
{
  "is_active": false
}
```

## Public preview (tools only)

```json
{
  "product_type": "flight",
  "base_price": 500,
  "supplier_tax": 100,
  "supplier_fees": 0,
  "currency": "SAR",
  "airline_code": "MS",
  "origin": "CAI",
  "destination": "DXB",
  "departure_date": "2026-10-01"
}
```

Note: `PricePreviewRequest` does **not** accept `supplier` / `supplier_code`. Public preview therefore **cannot** match `supplier_markup` rules unless metadata is injected server-side (it is not, for public callers). Use Admin rule CRUD + live Search to verify supplier-scoped rules.

`customer_tier` is **prohibited** on public preview.

---

# 7. Response Examples

## Create rule — `201`

```json
{
  "success": true,
  "message": "Pricing rule created successfully",
  "data": {
    "id": 12,
    "name": "TBO supplier 10%",
    "type": "supplier_markup",
    "priority": 10,
    "configuration": { },
    "is_active": true,
    "starts_at": null,
    "ends_at": null
  }
}
```

(`data` is the Eloquent `toArray()` of `PricingRule`.)

## List rules — `200`

```json
{
  "success": true,
  "data": [ ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 20,
    "total": 0,
    "from": null,
    "to": null
  },
  "links": { }
}
```

## Preview — `200`

```json
{
  "success": true,
  "data": {
    "data": {
      "product_type": "flight",
      "currency": "SAR",
      "supplier_price": 500,
      "supplier_tax": 100,
      "supplier_fees": 0,
      "markup": { "total": 50, "breakdown": [] },
      "margin_guard": { "minimum_margin": 0, "adjusted": false },
      "net_price": 550,
      "tax": { "total": 0, "breakdown": [], "country_code": "EG" },
      "fees": 0,
      "grand_total": 650,
      "profit": 50,
      "margin_percentage": 7.69
    }
  }
}
```

(Controller wraps service result as `{ data: $result }` inside `successResponse`.)

Preview exposes **supplier_price / profit / markup** — Admin/tools only. Never use as the customer booking price source of truth.

---

# 8. Pricing Scenarios

### A — No Pricing Rule (engine on)

If `pricing.enabled` and **no** active `pricing_rules` rows, markup falls back to legacy `MarkupEngine` (airline / route / seasonal / customer segment tables). If those tables are empty and margin guard does not force a floor, sell base ≈ supplier base; total ≈ base + supplier tax + fees.

If `pricing.enabled` is **false**, Search returns supplier amounts unchanged; `pricing.applied = false`.

### B — Percentage markup (verified)

Markup is computed on **supplier base** (not base+tax):

```text
Supplier base = 500
Supplier tax  = 100
Rule          = 10% percentage
Markup        = 50
Sell base     = 550
Sell total    = 550 + 100 + tax_on_markup
```

`tax_on_markup` applies only when markup amount > 0 (`TaxCalculator`). Exact tax depends on tax config / defaults.

Evidence: `PricingIntegrationService::priceFlight`, `SupplierMarkupStrategyTest`, `PricingFinancialMatrixTest`, `FlightsPricingTest`.

### C — Fixed markup (verified)

`adjustment_type: fixed` (alias `flat`) requires `configuration.currency` matching the **pricing currency**. Amount is added as-is to the base stack. Fixed rules that do not match currency are skipped by the matcher.

### D — Supplier-specific (verified)

`type: supplier_markup` requires `supplier_codes`. Matching uses flight metadata supplier code. Non-matching suppliers are skipped (`SupplierMarkupStrategyTest`, `FlightSearchPricingCacheConsistencyTest`, `PricingRuleIntegrationTest`).

### E — Route / airline (verified)

- `airline_markup` → `airline_codes`
- `route_markup` → `routes[]` origin/destination pairs (strategy matches routes list)

Cabin / journey type: **not** implemented as Pricing match dimensions.

### F — Multiple rules (verified)

**All matching rules apply.** Sorted by ascending `priority`, then `id`. Each adjustment is calculated from the **original** normalized base (percentages do not compound on prior rule outputs). Amounts are summed (`RuleMatcherService`).

### G — Activation (verified)

`is_active: false` → excluded from `PricingRule::active()` → no match. Update invalidates Search pricing cache fingerprint.

### H — Rule update (verified)

`saved` / controller update → `forgetDynamicRules()` → Search key version bumps → stale sell prices not served (`FlightSearchPricingCacheConsistencyTest`).

### I — Rule delete (verified)

Same invalidation path as update.

### J — `starts_at` / `ends_at` (verified)

`scopeActive` requires window membership. Search cache includes active-rule identity so crossing a boundary without CRUD produces a new cache key (`FlightSearchTimeWindowPricingCacheTest`).

### K — No double markup on Search cache hit (verified)

Cached Search stores already-priced results. Cache key includes pricing state; HIT returns the same sell total without re-applying markup on stored sell.

### L — Search → Fare Quote continuity (verified)

Fare Quote re-fetches supplier quote, then runs `priceFlight` again on **supplier** components (does not markup an already-marked-up sell). `FlightFareQuotePricingContinuityTest`, `PublicFareQuoteResource` strips internals.

### M — Price Lock (verified)

Created only inside checkout initiate. Server re-runs Fare Quote, then `BookingPriceLockService::lock` **ignores** client financial fields. Payment amount = locked sell. `EnterpriseBookingPriceLockTest`.

---

# 9. Rule Priority

| Behavior | Current implementation |
|----------|------------------------|
| Order | Ascending `priority`, then `id` |
| Selection | **Stack all matches** (not first-match-wins) |
| % basis | Original supplier/normalized base |
| Lower number | Applied earlier in the stack (migration comment); still additive |

---

# 10. Date/Time Rules

| Field | Behavior |
|-------|----------|
| `starts_at` | Nullable. Active when null or `<= now()` |
| `ends_at` | Nullable. Active when null or `>= now()`; must be `after_or_equal:starts_at` on write |
| `is_active` | Must be true |

Admin sees rules outside the window in list/show; matcher only loads `active()` scope.

After CRUD or schedule boundary change, customer Search should reflect new pricing on the next request that misses the old Search cache key (identity / fingerprint change). Frontend does not poll cache keys.

---

# 11. Cache Behavior (frontend-facing)

When Admin creates / updates / deletes / deactivates a rule, backend bumps an internal Search pricing fingerprint. The next Search for the same itinerary uses a new cache identity and re-prices.

When a scheduled `starts_at` / `ends_at` is crossed with **no** Admin save, Search identity still changes (active-rule membership). Frontend should simply re-call Search; no special cache API.

Do **not** call global cache flush from the Admin UI for Pricing.

Warm Search with **no** rule/membership change: cache HIT, no unnecessary supplier call (same itinerary/key).

---

# 12. Flight Pricing Response (customer)

Public Search card `price` (`FlightSearchPriceDTO`):

```json
{
  "price": {
    "currency": "SAR",
    "base_fare": 588.23,
    "taxes": 681.30,
    "other_charges": 0,
    "total": 1269.53,
    "breakdown": [
      { "code": "BASE", "label": "Base Fare", "amount": 588.23 },
      { "code": "TAX", "label": "Taxes & Fees", "amount": 681.30 },
      { "code": "OTHER", "label": "Other Charges", "amount": 0 },
      { "code": "TOTAL", "label": "Total", "amount": 1269.53 }
    ],
    "pricing": {
      "applied": true
    }
  }
}
```

Also present on cards when mapped: `refundable`, `fare_policy`, legs, `reference_index`, list `result_index`, etc. See Flights guide.

**Never present on public Search:** supplier cost, markup %, rule id, margin, audit.

---

# 13. Fare Quote / Recheck

```http
POST /api/v1/flights/fare-quote
```

There is **no** separate `/recheck` route. Recheck = Fare Quote.

**Send:** opaque `reference_index` from Search (preferred) + optional `search_id` + optional `currency`.  
**Do not send** list-rank integer `result_index` as the opaque supplier key.

**Display:** `flight.total_price`, `flight.base_fare`, `flight.tax`, `flight.currency`.  
**Do not trust** any client-side recalculation. Public resource omits `price_breakdown`, `pricing_context`, supplier_* fields.

---

# 14. Price Lock

There is **no** public `POST /price-lock` endpoint.

Lock is created inside:

```http
POST /api/v1/flights/checkout/initiate
```

Server:

1. Fare-quotes the selected flight again  
2. Runs Pricing again from supplier components  
3. Locks sell amount into booking columns / `pricing_snapshot`  
4. Charges MyFatoorah that locked sell (after offers/points pipeline)

Client-submitted amounts / forged `price_lock` / `locked_sell_price` are ignored.

Checkout HTTP success typically returns `booking_reference` + `payment_url` (lock internals not required for the customer redirect).

---

# 15. Checkout

```http
POST /api/v1/flights/checkout/initiate
```

Auth: controlled by `fulfillment.checkout_requires_auth` / `CHECKOUT_REQUIRES_AUTH` (default require Sanctum customer).

Send identifiers and passengers/contact — **not** financial authority fields.

**Does not** call TBO Book / Ticket. Post-payment path creates a **fulfillment request** only (`PostPaymentOrchestrator`). Legacy `POST /flights/book` returns **410**.

---

# 16. MyFatoorah

Flow:

```text
Checkout initiate → MyFatoorahGateway::executePayment → payment_url
Customer pays on MyFatoorah
GET|POST /flights/checkout/callback  and/or  POST /flights/checkout/webhook
→ MyFatoorahGateway::getPaymentStatus (authoritative)
→ InvoiceStatus === 'Paid'
→ PaymentReconciliationService (amount, currency, reference)
→ payment_status = PAID
→ create fulfillment_request
```

Frontend must **not** mark payment successful from browser redirect alone. Use booking details / payment status from the backend after callback processing.

`LIVE PAYMENT` against production MyFatoorah is out of scope for this audit unless safe test credentials are explicitly configured.

---

# 17. Payment Status

Booking fields used in this stage:

| Field | Meaning |
|-------|---------|
| `payment_status` | `PENDING` → `PAID` or `FAILED` |
| `status` | Remains `PENDING` after paid (assisted fulfillment; not ticketed yet) |
| Customer-facing | Often `booking_request_confirmed` after paid orchestrator |

Failed / unpaid callback: `payment_status = FAILED`, no fulfillment create, no loyalty earn.

---

# 18. Wallet

**Important product clarification**

| Concept | Implemented? |
|---------|----------------|
| Prepaid cash wallet funded by MyFatoorah | **NO** |
| Loyalty `PointsWallet` / `PointsTransaction` | **YES** |

Loyalty earn path:

```text
Payment PAID
  → fulfillment_request created
  → (later) admin/ops completes fulfillment
  → FulfillmentCompleted event
  → EarnPointsOnFulfillmentCompleted
  → PointsService::earnForBooking(locked_sell_price)
  → points_wallets.balance += floor(amount * earn_ratio)
```

Earn is **not** triggered by payment confirmation alone.  
Idempotency key: `earn:{booking_reference}`.

Customer Points APIs (Loyalty module) and Admin Loyalty wallets are separate from Pricing. See Postman folder `05 Points` / Admin Loyalty.

At checkout, points may be **redeemed** (debit), which is not a MyFatoorah credit.

---

# 19. Error Handling

| Situation | Typical status |
|-----------|----------------|
| Invalid rule configuration | `422` validation |
| Missing permission | `403` |
| Unauthenticated admin | `401` |
| Rule not found | `404` |
| Preview bad input | `422` |
| Preview missing FX rate | `422` on currency |
| Fare Quote unknown reference | error from Flights service (context membership) |
| Checkout auth required | `401` when gate enabled |
| Payment unpaid | callback throws / FAILED path |
| Payment amount mismatch | reconciliation reject (`FinancialIntegrityBoundaryTest`) |

---

# 20. Security Notes

Frontend / clients must **not**:

* calculate markup or rebuild sell totals from supplier cost  
* submit supplier cost, margin, or trusted final prices  
* modify locked prices  
* mark payment successful locally  
* mark wallet / points successful without backend confirmation  
* call Pricing Admin APIs without `pricing.*` permissions  
* treat public `/pricing/preview` as customer booking authority (it exposes commercial fields)  
* expose Admin analytics (rule ids, markup averages) to customers  

---

# Appendix A — Supported rule `type` values

Exactly:

`airline_markup`, `route_markup`, `seasonal`, `customer_tier`, `peak_time`, `hotel_markup`, `supplier_markup`, `weekend_surge`, `advance_purchase`, `last_minute`

## Adjustment types

`percentage` | `fixed` (alias `flat`) | `multiplier`

- Percentage: typically `0…100`; negative allowed for `customer_tier` and `last_minute` (`-100…100`)  
- Fixed: value ≥ 0 (or negative for those types); **currency required**  
- Multiplier: amount = `base * (value - 1)`  

## Store validation (rule envelope)

| Field | Create rules |
|-------|----------------|
| `name` | required, string, max 255 |
| `description` | nullable string |
| `type` | required, in list above |
| `priority` | nullable integer 0–9999 (default 0) |
| `configuration` | required array → normalized by `PricingRuleConfigurationValidator` |
| `is_active` | nullable boolean (default true) |
| `starts_at` | nullable date |
| `ends_at` | nullable date, after_or_equal starts_at |

Update uses `sometimes` / nullable variants.

---

# Appendix B — Customer flight endpoints (pricing-relevant)

| Method | Path | Role |
|--------|------|------|
| POST | `/flights/search` | Sell prices |
| POST | `/flights/fare-quote` | Recheck + sell |
| POST | `/flights/checkout/initiate` | Lock + MyFatoorah |
| GET/POST | `/flights/checkout/callback` | Gateway return |
| POST | `/flights/checkout/webhook` | Gateway webhook |

Full Flights contracts: `docs/FRONTEND_FLIGHTS_API_GUIDE.md`.
