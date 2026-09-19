# TBO Supplier E2E Final Report

Date: 2026-09-16  
Scope: TBO Flights Auth → Search → Pricing → FareQuote → Booking (price security)  
Supplier markup: **SUPPORTED** (after Phase C implementation)

---

## 1. Current Architecture

```text
FlightController
  → FlightSearchService
  → FlightSearchOrchestrator / SearchFlightsAction
  → FlightSupplierFactory (capability gate)
  → TboClient
       → TboAuth (ValidateAgency / tbo_token cache)
       → SearchRequestBuilder → SearchResponseHandler
  → SupplierNormalizer / TboFlightMapper
  → PricingIntegrationService (RuleMatcher | MarkupEngine → MarginGuard → TaxCalculator)
  → FlightSearchResultMapper / PublicFareQuoteResource

FareQuote: FlightController → FlightSearchService::fareQuote → TboClient::fareQuote → priceFlight
Booking:  BookingService / CreateBookingAction → BookingPriceLockService → TboClient::book
           BookRequestBuilder uses supplier* cost components (not client sell)
```

---

## 2. TBO Auth Findings

| Item | Value |
|------|-------|
| Class | `TboAuth` / `TboAuthService` |
| Endpoint | `POST .../Authenticate/ValidateAgency` |
| Payload | `UserName`, `Password`, `BookingMode` |
| Cache | `tbo_token` = TokenId + TrackingId, TTL **20h** |
| Failure marker | `tbo_auth_failed`, TTL **60s** |
| Auth timeout | **120s** via dedicated `authHttpClient()` |
| Cold auth (this run) | **42.8s PASS** |
| Cached auth | **0ms**, token reused |
| Why ~35–40s+ | Upstream ValidateAgency latency (not app retry loops) |

---

## 3. TBO Search Findings

| Scenario | Status | Duration | Results | Boundary |
|----------|--------|----------|---------|----------|
| DXB→DEL | PASS | 52.8s | 114 | — |
| CAI→DXB | PASS | auth 41.6s + search 11.0s | 40 | — |
| CAI→ISD | PASS (empty inventory) | auth 47.1s + search 3.3s | 0 | E.TBO_empty_inventory (`No Result Found.`) |
| FareQuote | PASS | 40.9s | price retained $169.70 | — |

**Required identifiers:** `TokenId`, `TraceId`/`TrackingId`, Search `ResultIndex` → FareQuote refreshed `ResultIndex` → Book.

---

## 4. Pricing Findings

```text
Supplier Cost (NormalizedSupplierPrice)
  → PricingIntegrationService::priceFlight
  → RuleMatcherService (DB rules) OR MarkupEngine (legacy tables)
  → MarginGuardService
  → TaxCalculator (tax on markup amount)
  → Sell Price on FlightResultDTO
```

- Supplier identification: `metadata.supplier_code` (e.g. `tbo`)
- Precedence: **cumulative** by rule `priority` then `id` (not winner-takes-all)
- Public API: sell fields only; cost/markup/context omitted (`PublicFareQuoteResource`)

---

## 5. Supplier Markup

```text
SUPPORTED
```

Implemented as Pricing rule type `supplier_markup` matching `configuration.supplier_codes` against context `metadata.supplier_code`. Any rule may also scope via `conditions.supplier_codes`. Markup remains a Pricing responsibility — **not** applied inside `TboClient`.

---

## 6. Recheck / Booking

```text
Search result (ResultIndex)
  → FareQuote (TokenId + TraceId + ResultIndex)
  → priceFlight again from supplier components
  → BookingPriceLockService::lock (server sell + supplier snapshot)
  → CreateBookingAction → TboClient::book
  → variance recorded; locked_sell_price remains customer contract
```

Live Book: **BLOCKED** (no safe automated booking environment).

---

## 7. Security Findings

| Concern | Status |
|---------|--------|
| Client price trust | Ignored by `BookingPriceLockService` |
| Supplier cost in public fare-quote | Hidden |
| Markup in public fare-quote | Hidden |
| Booking price manipulation | Server lock authoritative |
| Book payload uses | Supplier cost components from FareQuote |

---

## 8. Code Changes

| File | Change | Reason |
|------|--------|--------|
| `Strategies/SupplierMarkupStrategy.php` | New strategy | Supplier-level markup |
| `PricingServiceProvider.php` | Register strategy | DI wiring |
| `RuleMatcherService.php` | Optional supplier_codes scope | Shared supplier filter |
| `PricingContextBuilder.php` | product_type + supplier metadata | Matcher input |
| `PricingContext.php` | Pass supplier into metadata | Flight fallback path |
| `PricingPreviewService.php` | Merge supplier metadata | Preview parity |
| `PricingRuleConfigurationValidator.php` | Type + validation | Admin contract |
| `PricingRuleController.php` | Allow type in validation | Admin API |
| `docs/modules/Pricing.md` | Document type | Module contract |
| `docs/TBO_E2E_AUDIT_NOTES.md` | Audit notes | Phase A |
| `tests/Unit/SupplierMarkupStrategyTest.php` | Unit coverage | Strategy |
| `tests/Unit/PricingRuleConfigurationValidatorTest.php` | Validator cases | Contract |
| `tests/Feature/PricingRuleIntegrationTest.php` | 10% once + scope skip | Integration |
| `tests/Diagnostic/TboFlightsDiagnosticTest.php` | CAI routes + empty inventory | Evidence |
| `Traveling_Safer_API_V1.postman_collection.json` | Flow description | Postman |

---

## 9. Tests

### Pricing / lock regression (this session)

```text
Passed: 52 tests (164 assertions) — FlightsPricing, MarkupEngine, PublicPricing,
        FareQuote continuity, PropagationIntegrity, EnterpriseBookingPriceLock,
        HotelCheckoutPriceTampering
Failed: 0
```

### Supplier markup suite

```text
Passed: 14 tests (31 assertions)
Failed: 0
```

### Live TBO diagnostic

```text
Passed: configuration, auth, DXB→DEL search, FareQuote, CAI→DXB, token cache
Empty inventory (recorded): CAI→ISD — TBO "No Result Found."
Blocked: Live Book
```

### Controlled 10% markup price trace

```text
TBO Supplier
  Supplier Base Fare:  100.00
  Supplier Taxes:       50.00
  Supplier Total:      150.00
    ↓
Pricing Module
  Applicable Markup:   supplier_markup 10%
  Markup Amount:        10.00
  Tax on markup:         0.00
    ↓
Final Sell Price:      160.00
Recheck Sell Price:    160.00  (not 121 / not double-applied)
```

---

## 10. Final End-to-End Flow

```text
                    ┌───────────────────┐
                    │ FlightController  │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ FlightSearchService│
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ FlightSupplier    │
                    │ Factory           │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ TboAuth           │
                    │ ValidateAgency    │
                    │ cache tbo_token   │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ TboClient Search  │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ Normalize         │
                    │ (supplier_code)   │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ Pricing Module    │
                    │ supplier_markup   │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ Sell Price        │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ FareQuote Recheck │
                    │ + priceFlight     │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ Price Lock        │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ TboClient Book    │
                    │ (supplier cost)   │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ Internal Booking  │
                    └───────────────────┘
```

Evidence artifacts: `tmp/tbo_e2e_test_evidence.json`, `tmp/tbo_supplier_markup_trace.json`, `docs/TBO_E2E_AUDIT_NOTES.md`.
