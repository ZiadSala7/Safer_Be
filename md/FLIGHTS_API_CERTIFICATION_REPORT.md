# Flights API Final Certification Report

Date: 2026-09-16  
Guide: [`docs/FRONTEND_FLIGHTS_API_GUIDE.md`](FRONTEND_FLIGHTS_API_GUIDE.md)

---

## 1. Overall Status

```text
READY WITH KNOWN LIMITATIONS
```

Frontend can integrate against confirmed Search / Fare Quote / Checkout contracts. Live TBO Book remains blocked; Return/Multi City are flattened per-leg searches.

---

## 2. Search Status

```text
One Way:     CERTIFIED — CAI→DXB, 34 results, 57.6s
Return:      CERTIFIED — DXB↔DEL, 150 results, 92.2s (after OD-filter fix)
Multi City:  CERTIFIED — CAI→DXB→BKK→CAI, 143 results, 42.6s
```

---

## 3. Fare Quote

```text
Status:              CERTIFIED
Live Verified:       YES — OW selected result, sell 353.41 USD, expires_in 300
Automated Verified:  YES — PublicFareQuoteResource + continuity tests
```

---

## 4. Price Lock

```text
Status: CERTIFIED (automated)
When: checkout initiate
Client financial fields: ignored
Public endpoint: none (internal to checkout)
```

---

## 5. Pricing

```text
Supplier Cost:           Internal only (public search/FQ hide it)
Markup:                  Pricing Module rules (cumulative by priority/id)
Tax/Fee:                 TaxCalculator on markup amount
Final Sell Price:        Returned on search/FQ
Recheck Behavior:        Fare Quote re-prices from supplier components
Double Markup Protection: VERIFIED (160 → 160, not 121)
```

---

## 6. Supplier Markup

```text
supplier_markup — SUPPORTED in Pricing Module
Applied via SupplierMarkupStrategy + RuleMatcher
TBO integration contains NO hard-coded markup
```

Cases: 10% PASS, 0% PASS, not-applicable PASS, recheck no-compound PASS.

---

## 7. Booking

```text
Live:        BLOCKED (no safe live TBO Book environment)
Automated:   CERTIFIED — lock/tamper tests; legacy book 410; checkout path code-verified
Blocked:     Direct supplier Book automation
Reason:      Assisted fulfillment requires payment + ops fulfillment; Book URL is production
```

---

## 8. Endpoint Certification

```text
Total frontend-critical rows: 9
CERTIFIED:            7
TEST CERTIFIED:       1 (checkout initiate — contract + lock tests; live payment not required here)
BLOCKED:              1 (live TBO Book)
PARTIALLY CERTIFIED:  0 (after Return fix)
NOT SUPPORTED:        0
FAILED:               0
```

---

## 9. Remaining Issues

| Issue | Impact | Why it remains | Required action |
|-------|--------|----------------|-----------------|
| Return/Multi City are flattened one-way legs | UX must not assume single combined RT/MC quote | Current `ReturnStrategy` / `MultiCityStrategy` design | Product decision for native combined quotes later |
| Live TBO Book not executed | Cannot claim live Book CERTIFIED | No safe test booking env | Staged agency Book UAT |
| Cold TBO Auth latency ~40–90s | Slow first search | Upstream ValidateAgency | Pre-warm token / timeouts already isolated |
| Pricing preview exposes supplier_price | Not for customer flight cards | Intentional preview API | FE: use only for tools; flights UI uses search/FQ sell |

---

## 10. Files Changed

| File | Change |
|------|--------|
| `app/Modules/Flights/Actions/SearchFlightsAction.php` | Preserve supplier* dual-pricing fields |
| `app/Modules/Flights/Services/Orchestration/HardSearchConstraintEvaluator.php` | Accept per-leg Return inventory |
| `tests/Unit/HardSearchConstraintEvaluatorTest.php` | Return leg OD coverage |
| `Traveling_Safer_API_V1.postman_collection.json` | Flights flow docs + `reference_index` capture |
| `scripts/rebuild_postman.php` | Flights folder description |
| `docs/FRONTEND_FLIGHTS_API_GUIDE.md` | Frontend handoff guide |
| `docs/FLIGHTS_API_CERTIFICATION_REPORT.md` | This report |
| `tmp/flights_api_certification.php` | Certification runner |
| `tmp/*certification* / return_search_retry.json` | Evidence artifacts |

---

## 11. Final Documentation

```text
docs/FRONTEND_FLIGHTS_API_GUIDE.md — GENERATED
```

Postman `01 Flights` folder updated for Search → Fare Quote → Checkout journey without credentials.

---

## Defects fixed during certification

1. **Return searches returned 0 results** while One Way had inventory — `HardSearchConstraintEvaluator` required a full round-trip OD on each flattened one-way leg. Fixed to accept outbound/inbound legs.
2. **`SearchFlightsAction` dropped supplier dual-pricing fields** when cloning DTOs — restored so supplier cost anchors survive orchestration.
