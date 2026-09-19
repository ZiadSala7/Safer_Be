# Flight E2E Certification Report

**Date:** 2026-09-16  
**Scope:** Search → Pricing → Fare Quote → Price Lock → Offers/Promo → Checkout initiate → MyFatoorah amount  
**Out of scope:** Financial Transaction / Ledger, Wallet, webhook signature hardening, Refund redesign, Supplier Book live

---

## Executive Summary

The assisted Flight path is **application-certified** with automated tests for Pricing, Promo Codes, Price Lock, Fare Quote continuity, Search pricing cache, and payment-callback fulfillment (mocked gateway).

Public APIs expose **sell prices only**. Offers discount the **locked sell** after Pricing. MyFatoorah is invoiced for the **final discounted** `locked_sell_price`.

Live TBO Search/FQ and live MyFatoorah charges were **not** re-executed in this pass (environment/credentials). Prior live Search evidence exists in repo tmp docs but is not reclaimed as live certification here.

| Stage | Status |
|-------|--------|
| Search (contract + pricing mapping) | **CERTIFIED** (automated) |
| Pricing engine + cache | **CERTIFIED** (automated) |
| Fare Quote continuity | **CERTIFIED** (automated) |
| Price Lock | **CERTIFIED** (automated) |
| Promotions / Promo Codes | **CERTIFIED** (automated) |
| Pricing → Promo order | **CERTIFIED** (automated) |
| Checkout initiate contract | **CERTIFIED** (code + automated) |
| MyFatoorah initiation amount | **CERTIFIED** (amount path; gateway **MOCKED**) |
| Live TBO Search/FQ | **PARTIALLY CERTIFIED** (prior evidence; not re-run) |
| Live MyFatoorah charge | **NOT CERTIFIED** |
| Supplier Book | **NOT CERTIFIED** (assisted; deferred) |
| Financial ledger | **NOT CERTIFIED** (deferred by design) |

---

## Tested Flow

```text
Search → Pricing → Fare Quote → Price Lock → Promo/Offer → Checkout → MyFatoorah(initiate)
```

---

## Test Environment

| Item | Value |
|------|--------|
| Framework | Laravel 12 |
| Test runner | PHPUnit via `php artisan test` |
| Offers flag | `promotions.enabled` (env `OFFERS_ENABLED`, default false) |
| Pricing flag | `pricing.enabled` (`PRICING_ENGINE_ENABLED`) |
| Payment in tests | `MyFatoorahGateway` mocked |
| Supplier Book | Not invoked on payment |

---

## Search Certification

| Scenario | Status | Evidence |
|----------|--------|----------|
| One Way / Return / Multi City validation | CERTIFIED | `SearchFlightRequest`, HardSearch tests |
| Sell-only public price | CERTIFIED | `FlightSearchResultMapperTest`, `FlightSearchPriceDTO` |
| `search_id` + `reference_index` | CERTIFIED | mapper + docs |
| List-rank `result_index` ≠ supplier id | CERTIFIED | docs + mapper |
| Empty inventory / invalid cabin | PARTIAL | validation rules present; not all negative E2E HTTP cases re-run |

---

## Pricing Certification

| Scenario | Status | Evidence |
|----------|--------|----------|
| Percentage / fixed markup | CERTIFIED | `FlightsPricingTest`, financial matrix historically |
| Supplier isolation | CERTIFIED | `SupplierMarkupStrategyTest`, `PricingRuleIntegrationTest` |
| Cache invalidation / time window | CERTIFIED | `FlightSearchPricingCacheConsistencyTest`, `FlightSearchTimeWindowPricingCacheTest` |
| No double markup Search→FQ | CERTIFIED | `FlightFareQuotePricingContinuityTest` |
| Public leakage of cost/markup | CERTIFIED absent | `PublicPricingResourceTest` |

**Order:** markup on **supplier base**; tax-on-markup optional; sell = base′ + supplier tax + fees + tax_on_markup.

---

## Fare Quote Certification

| Scenario | Status | Evidence |
|----------|--------|----------|
| Public sell fields only | CERTIFIED | `PublicFareQuoteResource` |
| Pricing reapplied from supplier | CERTIFIED | continuity test |
| Stale/invalid context | PARTIAL | `SearchContextException` codes documented; not all HTTP matrix re-run |
| Price change TBO code 15 | CODE VERIFIED | exception factory; live not re-run |

---

## Price Lock Certification

| Scenario | Status | Evidence |
|----------|--------|----------|
| Created at checkout only | CERTIFIED | no public lock route |
| Client financial fields ignored | CERTIFIED | `EnterpriseBookingPriceLockTest` |
| Freeze across markup change | CERTIFIED | same |
| Snapshot includes sell + supplier anchors | CERTIFIED | `BookingPriceLockService` |

---

## Promotions Certification

| Scenario | Status | Evidence |
|----------|--------|----------|
| Global / airline / route + code | CERTIFIED | `OfferPromoCodeTest` |
| Invalid code no fallback | CERTIFIED | matcher + pipeline tests |
| Normalization `ramadan10`→`RAMADAN10` | CERTIFIED | `Offer::normalizeCode` |
| Usage reserve / release / idempotent | CERTIFIED | `CheckoutPromoCodeTest`, `OfferServiceTest` |
| Auto `matchBest` without code | CERTIFIED | regression tests |
| Search-time promo pricing | NOT IMPLEMENTED | by design |

---

## Checkout Certification

| Scenario | Status | Evidence |
|----------|--------|----------|
| `promo_code` on `BookFlightRequest` | CERTIFIED | request + pipeline |
| Auth gate | CODE VERIFIED | `CHECKOUT_REQUIRES_AUTH` |
| Response: `booking_reference` + `payment_url` | CERTIFIED | controller |
| Booking `status=pending`, `payment_status=PENDING` | CERTIFIED | payment service |

---

## Payment Initiation Certification

| Scenario | Status | Evidence |
|----------|--------|----------|
| Amount = final discounted lock | CERTIFIED | `FlightPaymentService` + `PricingThenPromoOrderTest` / `CheckoutPromoCodeTest` |
| Without promo payable = sell | CERTIFIED | pipeline |
| With promo payable = sell − discount | CERTIFIED | e.g. 1200 → 1080 |
| Gateway executePayment | MOCKED | Feature payment tests |
| Live MF charge | NOT CERTIFIED | blocked |

Certified Pricing→Promo example (tax-on-markup/margin = 0):

| Step | SAR |
|------|----:|
| Supplier base | 1000 |
| Supplier tax | 100 |
| Pricing +10% base | sell base 1100 |
| Sell total | 1200 |
| Promo 10% | −120 |
| **MyFatoorah amount** | **1080** |

---

## Request Validation Matrix (summary)

| Endpoint | Key required | Optional | Forbidden authority |
|----------|--------------|----------|---------------------|
| `POST /flights/search` | AdultCount; journey fields | currency, filters | client markup |
| `POST /flights/fare-quote` | `reference_index` or `result_index` | `search_id`, currency | |
| `POST /flights/checkout/initiate` | `result_id`, passengers, flight shape | `promo_code`, `search_id`, currency | client price/lock/cost |

Full field rules: `SearchFlightRequest`, `FareQuoteRequest`, `BookFlightRequest`.

---

## Response Contract Matrix (public)

| Endpoint | Customer sees |
|----------|----------------|
| Search | `price.*` sell, `pricing.applied`, fare_policy, ids |
| Fare Quote | `flight.total_price` sell, segments, `expires_in` |
| Checkout initiate | `booking_reference`, `payment_url`, message |
| Callback | booking + `payment_status`, sell amounts |

**Must not appear publicly:** supplier cost, markup %, margin, rule IDs, pricing_context.

---

## Enum / Metadata Matrix

| Domain | Values |
|--------|--------|
| JourneyType | 1, 2, 3 |
| Cabin (search) | 0–4 (0 = all) |
| Cabin (book segment) | 1–4 |
| Passenger type | adult, child, infant |
| Gender | 1, 2 |
| BookingStatus | pending, confirmed, ticketed, cancelled, failed, released, refunded |
| payment_status | PENDING, PAID, FAILED, REFUNDED |
| Offer type | global, destination, airline, route |
| discount_type | percentage, fixed |
| Offer status | draft, active, disabled |
| Condition type | airline, destination, route, min_amount |

---

## Error Matrix (frontend)

| Scenario | HTTP | Action |
|----------|-----:|--------|
| Validation | 422 | Field errors |
| Invalid promo | 422 | Clear / fix `promo_code` |
| FQ expired | 410 | Re-search |
| FQ price change | 409 | Confirm / re-quote |
| Context missing | 404/410 | Re-search |
| Payment reconcile fail | 409 | Support / retry |
| Legacy book | 410 | Use checkout |

---

## Frontend Integration Flow

Documented in `docs/FRONTEND_FLIGHTS_API_GUIDE.md` (Complete flow + Angular pseudo-flow + Offers section).

---

## Postman Coverage

Regenerated via `php scripts/rebuild_postman.php`:

- Search One Way / Return / Multi City  
- Fare Quote  
- Checkout initiate with `promo_code`  
- Admin Offers create with `code`  
- Invalid promo covered by automated tests (collection documents optional `{{promo_code}}`)

---

## Known Limitations

1. `OFFERS_ENABLED` / `PRICING_ENGINE_ENABLED` default off — must be enabled in env for production behavior.  
2. Checkout initiate does **not** return final payable in JSON (only `payment_url`).  
3. No hard Price Lock TTL — soft via FQ/search context.  
4. Product webhooks unsigned (deferred).  
5. Live TBO / live MF not re-certified this pass.  
6. Global Offers are not flight-product-filtered in matcher (hotels can match `global` if pipeline runs).

---

## Deferred Work

- FinancialTransaction / Ledger  
- Webhook signature verification  
- Refund architecture alignment  
- Live MF sandbox certification  
- Supplier Book / Sales fulfillment phase  

---

## Issues Discovered

| Severity | Issue | Notes |
|----------|-------|-------|
| Medium | Initiate response omits payable amount | UX must trust payment page / booking details |
| Medium | Unsigned checkout webhooks | Deferred; GetPaymentStatus still authoritative |
| Low | Global offer not flight-scoped | Documented; optional future condition |
| Documentation only | Guide previously light on promo | Updated this pass |

No critical defects blocking Search→Checkout certification were found. No production behavior changes required beyond documentation/tests already added for Promo Codes in the prior phase.

---

## Automated test evidence (this pass)

```text
Primary suite (82 tests, 300 assertions) — PASS
+ FlightsPricingTest / SupplierMarkupStrategyTest (12) — PASS
+ PricingThenPromoOrderTest (1) — PASS
```

Commands:

```bash
php artisan test --filter="OfferPromoCodeTest|CheckoutPromoCodeTest|OfferMatcherTest|CheckoutOfferTest|OfferServiceTest|OffersApiContractTest|PricingRuleIntegrationTest|FlightSearchPricingCacheConsistencyTest|FlightFareQuotePricingContinuityTest|FlightSearchTimeWindowPricingCacheTest|EnterpriseBookingPriceLockTest|FlightSearchResultMapperTest|PublicPricingResourceTest|PaymentCallbackFulfillmentTest|HardSearchConstraintEvaluatorTest"

php artisan test --filter="FlightsPricingTest|SupplierMarkupStrategyTest|PricingThenPromoOrderTest"
```
