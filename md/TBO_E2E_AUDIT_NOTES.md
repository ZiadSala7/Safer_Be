# TBO Flights E2E Audit Notes (Phase A)

Date: 2026-09-16  
Scope: Auth → Search → Normalization → Pricing → FareQuote → Price Lock → Book  
Status: Read-only discovery complete before supplier markup implementation.

## Identifier chain (Search → FareQuote → Book)

| Stage | Identifier | Source | Required for |
|-------|------------|--------|--------------|
| Auth | `TokenId` | `ValidateAgency` → dedicated cache store `tbo` key `tbo_token` | Search, FareQuote, Book |
| Auth | `TrackingId` | same dedicated store | Used as `TraceId` on Search/FareQuote/Book |
| Search | `ResultIndex` | TBO Search Results | FareQuote (`ResultIndex`) |
| Search | `traceId` on DTO | Auth TrackingId | Continuity / logging |
| FareQuote | New `ResultIndex` | FareQuote response | Book (`ResultIndex`) |
| FareQuote | Supplier fare components | FareQuote Fare | BookRequestBuilder uses **supplier*** fields, not sell |
| Book | `ResultIndex`, `TokenId`, `TraceId`, passengers, segments, booking class | BookRequestBuilder | TBO Book |

Do not strip or rewrite `ResultIndex` / `TraceId` between stages.

## Failure boundary taxonomy

| Code | Boundary | Typical signal |
|------|----------|----------------|
| A | Authentication | `TboAuthException`, `tbo_auth_failed` marker, ValidateAgency failure |
| B | Network / timeout | HTTP client timeout, connection errors |
| C | Request payload | Invalid criteria / builder validation |
| D | TBO validation | TBO ErrorCode validation responses |
| E | TBO supplier-side | Upstream 5xx / inventory errors |
| F | Response parsing | Handler/normalizer exceptions |
| G | Internal application | Orchestrator / factory / unexpected exceptions |
| H | Pricing layer | `PricingIntegrationService` failures (search keeps original on catch) |
| I | Unknown | Unclassified |

## Booking price security

- `BookingPriceLockService::lock()` ignores client financial fields; freezes server sell + supplier snapshot.
- `CreateBookingAction` uses `locked_sell_price` as customer contract; supplier variance is recorded, sell lock is not auto-rewritten.
- `BookRequestBuilder` sends **supplier** cost components to TBO, not customer sell price.
- `PublicFareQuoteResource` omits `supplier_base*`, `price_breakdown`, `pricing_context`, `rawData`.

## Pricing gap (pre-implementation)

- Supplier cost identification exists: `metadata.supplier_code` via `NormalizedSupplierPrice`.
- Supplier-scoped markup rule type: **NOT SUPPORTED** before Phase C.
- Precedence: cumulative by `priority` then `id` (airline + route can both apply).

## Known live timings (prior diagnostics)

- Cold Auth: ~46–90s (upstream ValidateAgency).
- Auth cache hit: ~0–1ms.
- Search (warm token): ~15–60s.
- Live Book: **BLOCKED** (no safe automated test-booking environment).

## Search cold-start after `optimize:clear` / `cache:clear` (2026-09-16)

Measured (CAI→DXB, 1 ADT, USD, `supplier=tbo`, database Search cache):

| Stage | Cold (after full clear) | Warm (immediate repeat) |
|-------|-------------------------|-------------------------|
| Wall | ~76s | ~98ms |
| TBO supplier (auth+search) | ~75s | 0 (cache HIT) |
| Pricing + audit | ~662ms | 0 |
| Mapping | ~22ms | 0 |
| SQLSTATE 22001 | none | none |

**Root cause:** default app cache clear wiped `tbo_token` **and** Search result cache → forced cold ValidateAgency + TBO Search. Application overhead (~1s) is not the dominant delay.

**Fix:** TBO auth token + failure marker use dedicated cache store `tbo` (file driver by default) via `TboConfig::tokenCache()`, so `php artisan cache:clear` / `optimize:clear` no longer invalidate a warm token. Search result cache still clears (expected MISS → TBO Search only).

**Still external:** first Search after Search-cache clear still waits on TBO Search HTTP (~10–60s). Warm Search remains ~100ms.

**Time-window pricing:** Search cache keys include `PricingCacheInvalidator::activeRulesIdentity()` (active rule IDs under current `starts_at`/`ends_at`). Active-rules list cache is bound to that identity (and TTL-capped at the next schedule boundary). Crossing a window without CRUD cannot serve a stale priced Search entry.
