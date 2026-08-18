# Flight Search & Filters — Flutter Integration Guide

> Reference implementation: Safer Be web (`app/[locale]/(landing)/flight`)  
> **Base URL:** `https://backend.saferbe.com/api/v1`  
> **Content-Type:** `application/json`  
> **Accept-Language:** `en` | `ar` (same as web locale)

This document describes how the web app searches flights, applies filters/sort, and books.  
Flutter should mirror the same **flow**, **query-string model**, and **API contracts**.

---

## App routes (web mirror → Flutter screens)

| Web route | Purpose | Flutter screen |
|-----------|---------|----------------|
| `/{locale}/flight` | Search form (hero) | Flight search home |
| `/{locale}/flight/results?…` | Results + filters | Results list |
| `/{locale}/flight/{id}?reference_index=…&supplier=…&search_id=…` | Fare quote / details | Flight details |
| `/{locale}/flight/checkout/{token}` | Passenger form → payment | Checkout |
| `/{locale}/booking/flight/{reference}` | Booking status | Booking status |

`locale` is `en` or `ar`. Prefer storing search state in a deep-linkable query (or equivalent typed model), same keys as below.

---

## End-to-end flow

```
[1] Airport pickers (GET suggest / list / autocomplete)
              ↓
[2] Build search form (trip, dates, pax, cabin, currency)
              ↓
[3] POST /flights/search  (or /flights/cheapest|fastest)
         save search_id + results list in memory
              ↓
[4] Navigate to results (persist query params)
              ↓
[5] Filters / sort
    · Most filters / sort = CLIENT-SIDE on last POST results
    · Airline filter change = RE-POST /flights/search (server)
              ↓
[6] Tap flight → POST /flights/fare-quote
              ↓
[7] POST /flights/checkout/initiate → open payment_url
              ↓
[8] After pay → GET /flights/booking/{reference}
```

### Re-search rules (important)

Web only re-calls `POST /flights/search` when the **server search signature** changes:

| Field change | New API call? |
|--------------|---------------|
| Origin / destination / dates / trip type / segments | ✅ Yes |
| Adults / children / infants / cabin / currency | ✅ Yes |
| Airlines preferred filter | ✅ Yes (debounced ~450ms on web) |
| Sort (best / cheapest / shortest) | ❌ Client only |
| Stops | ❌ Client only |
| Checked baggage toggle | ❌ Client only |
| Price min/max | ❌ Client only |
| Departure / arrival time slots | ❌ Client only |

Fingerprint used on web (`urlStateServerSearchKey`):  
`from`, `to`, `depart`, `return`, `adults`, `children`, `infants`, `cabin`, `trip`, `flightType`, `limit`, `segments`, `airlines`, `currency`.

---

## 1 — Reference / pickers

### Airports

| Use case | Method | Endpoint | Key query params |
|----------|--------|----------|------------------|
| Origin typeahead / country-aware suggest | `GET` | `/airports/suggest` | `q`, `limit` (default 10), country if used |
| Destination browse list | `GET` | `/flights/airports` | `limit` (default 15) |
| Airport autocomplete | `GET` | `/flights/airports/autocomplete` | `q`, `limit` (default 10) |

Store for each selection:

- `airportCode` (IATA 3-letter uppercase) → search `Origin` / `Destination`
- Display name / city / country for UI only

### Airlines (results filter / catalog)

| Use case | Method | Endpoint | Params |
|----------|--------|----------|--------|
| Catalog pages | `GET` | `/airlines` | `page`, `per_page` (e.g. 30–50), `locale` |
| Typeahead (≥ 2 chars) | `GET` | `/airlines/autocomplete` | `q`, `limit` (e.g. 8), `locale` |

Airline **code** for search:

- Prefer **IATA** 2-letter
- Else ICAO / legacy code (2–3 alphanumerics)
- Normalize: trim, uppercase, `^[A-Z0-9]{2,3}$`

Web avoids loading a full 50-item catalog until the user searches the filter.

---

## 2 — Search params (deep link model)

Mirror these query keys on results (web builds them via `buildFlightSearchQueryString`):

| Param | Example | Notes |
|-------|---------|-------|
| `from` | `CAI` | Required IATA |
| `to` | `DXB` | Required IATA |
| `fromName` / `toName` | city labels | Optional UI only |
| `depart` | `2026-09-10` | `YYYY-MM-DD` |
| `return` | `2026-09-17` | Round-trip only |
| `trip` | `one-way` \| `round-trip` \| `multi-city` | Normalize `_` → `-` |
| `segments` | `CAI\|DXB\|2026-09-10,DXB\|JED\|2026-09-15` | Multi-city legs |
| `adults` | `1` | min 1 |
| `children` | `0` | |
| `infants` | `0` | |
| `cabin` | `1` | see cabin table |
| `currency` | `USD` | ISO 4217 (3 letters) |
| `airlines` | `MS,EK` | Preferred; re-searches API |
| `stops` | `direct` \| `one_stop_or_less` \| omit for any | Client filter (+ optional API map) |
| `baggage` | `1` | Client: checked baggage only |
| `min_price` / `max_price` | numbers | Client filter |
| `sort` | `best` \| `cheapest` \| `shortest` | Client sort (default best) |
| `flightType` | `search` \| `cheapest` \| `fastest` | Highlight endpoints |
| `limit` | `3` | Highlight list size |
| `search_id` | opaque string | From search response — keep for fare quote / checkout |

**Example results URL**

```
/en/flight/results?from=CAI&to=DXB&depart=2026-09-10&trip=one-way&adults=1&children=0&infants=0&cabin=1&currency=USD&sort=cheapest
```

---

## 3 — Enums shared with web

### Journey type (`JourneyType` in body)

| UI trip | Value |
|---------|------:|
| One-way | `1` |
| Round-trip | `2` |
| Multi-city | `3` |

### Cabin class (`FlightCabinClass` / `cabin` query)

| UI | `cabin` / body value |
|----|---------------------:|
| Economy | `1` |
| Business | *(map if product adds it; types allow 0–4)* |
| First | `3` |
| Premium Economy | `4` |

Web quick search uses Economy `1`, Premium Economy `4`, First `3`.

### Highlight / flight type

| UI | Endpoint path under `/flights` |
|----|--------------------------------|
| Full search | `POST search` |
| Cheapest | `POST cheapest?limit=N` |
| Fastest | `POST fastest?limit=N` |

Body for highlights is the **same search payload** as full search.

---

## 4 — `POST /flights/search`

### One-way / round-trip body

```json
{
  "JourneyType": 1,
  "Origin": "CAI",
  "Destination": "DXB",
  "DepartureDate": "2026-09-10",
  "ReturnDate": null,
  "AdultCount": 1,
  "ChildCount": 0,
  "InfantCount": 0,
  "FlightCabinClass": 1,
  "PreferredAirlines": null,
  "EndUserIp": null,
  "currency": "USD",
  "Currency": "USD"
}
```

Round-trip: `JourneyType: 2`, `ReturnDate: "YYYY-MM-DD"`.

### Multi-city body

```json
{
  "JourneyType": 3,
  "AdultCount": 1,
  "ChildCount": 0,
  "InfantCount": 0,
  "FlightCabinClass": 1,
  "PreferredAirlines": null,
  "currency": "USD",
  "Currency": "USD",
  "Segments": [
    {
      "Origin": "CAI",
      "Destination": "DXB",
      "PreferredDepartureTime": "2026-09-10",
      "FlightCabinClass": 1
    },
    {
      "Origin": "DXB",
      "Destination": "JED",
      "PreferredDepartureTime": "2026-09-15",
      "FlightCabinClass": 1
    }
  ]
}
```

### Optional filters block (when re-searching with server filters)

Built in web by `toFlightSearchPayload` → `filters` + top-level `PreferredAirlines` + `sort`/`Sort`:

```json
{
  "PreferredAirlines": ["MS", "EK"],
  "filters": {
    "airlines": ["MS", "EK"],
    "marketing_airlines": ["MS", "EK"],
    "direct": true,
    "direct_flights": true,
    "stops": "0",
    "has_checked_baggage": true,
    "min_price": 100,
    "max_price": 800
  },
  "sort": "price_asc",
  "Sort": "price_asc"
}
```

#### Mapping UI filters → API body

| UI | → API |
|----|--------|
| Airlines codes | `PreferredAirlines`, `filters.airlines`, `filters.marketing_airlines` |
| Stops = direct | `filters.direct=true`, `direct_flights=true`, `stops="0"` |
| Stops = one stop or less | `filters.stops="0,1"` |
| Checked baggage | `filters.has_checked_baggage=true` |
| Min / max price | `filters.min_price` / `max_price` |
| Sort cheapest | `sort`/`Sort` = `price_asc` |
| Sort shortest | `sort`/`Sort` = `duration_asc` |
| Sort best | omit `sort` |

> On web, stops / baggage / price / sort are applied **client-side** after one search; the table above is the contract if Flutter wants server-side parity or a future “Apply on supplier” mode.  
> **Airlines** on web **do** re-POST with the mapping above.

### Success response (shape used by UI)

```json
{
  "success": true,
  "data": [ /* FlightResult[] */ ],
  "meta": {
    "total": 42,
    "per_page": 42,
    "current_page": 1,
    "last_page": 1
  },
  "supplier": "tbo",
  "journey_type": 1,
  "search_criteria": { },
  "search_id": "<opaque>"
}
```

Persist **`search_id`** (session + deep link). Needed for fare quote and checkout.

#### Result item (fields commonly used in list cards)

```json
{
  "id": "…",
  "result_index": 1,
  "reference_index": "<string used for fare quote>",
  "supplier": "tbo",
  "journey_type": "1",
  "legs": [
    {
      "origin_code": "CAI",
      "destination_code": "DXB",
      "departure_time": "2026-09-10T08:00:00",
      "arrival_time": "2026-09-10T12:30:00",
      "duration_minutes": 270,
      "stops_count": 0,
      "airline_code": "MS",
      "airline_name": "EgyptAir",
      "flight_number": "MS123",
      "cabin_class": "Economy",
      "segments": [ ]
    }
  ],
  "price": {
    "total": 420.5,
    "currency": "USD",
    "base_fare": 350,
    "taxes": 70.5,
    "other_charges": 0
  },
  "baggage": {
    "checked": "23 KG",
    "cabin": "7 KG",
    "description": "…"
  },
  "refundable": false,
  "best_deal_labels": ["Cheapest"]
}
```

### Error / empty handling (web parity)

| HTTP | UX |
|------|-----|
| `502` / `503` / `504` / `404` | Treat as **no flights** (empty list), not a hard crash |
| Other | Surface API error message |

---

## 5 — Highlights (optional)

```
POST /flights/cheapest?limit=3
POST /flights/fastest?limit=3
```

Same body as search. Response:

```json
{
  "success": true,
  "supplier": "tbo",
  "journey_type": 1,
  "flights": [ /* FlightResult[] */ ],
  "total_available": 12,
  "limit": 3,
  "search_id": "…"
}
```

Map `flights` → same list UI as `data` from search.

---

## 6 — Results filters (client-side parity)

Apply on the **in-memory** list from the last successful search (after optional airline re-search).

### Stops

| UI value | Keep flight when |
|----------|------------------|
| `any` | always |
| `direct` | `stopsCount == 0` (from first/outbound leg aggregation as on web) |
| `one_stop_or_less` | `stopsCount <= 1` |

### Checked baggage

If toggle on: keep only items with checked baggage present  
(web: `hasCheckedBaggage` derived from baggage fields).

### Airlines (after server list returned)

Client multi-select by `airlineCode` **or** re-POST search with preferred airlines (web does re-POST).

### Price range

Keep if `price` within optional `[priceMin, priceMax]`.

### Time slots (departure / arrival independently)

| Slot id | Hour (local of ISO datetime) |
|---------|------------------------------|
| `before-6am` | `h < 6` |
| `6am-12pm` | `6 ≤ h < 12` |
| `12pm-6pm` | `12 ≤ h < 18` |
| `after-6pm` | `h ≥ 18` |

Empty slot list = no restriction for that side.  
Multiple selected slots = match **any** of them.

### Sort (client)

| UI | Order |
|----|--------|
| `best` | Prefer items with labels, then price ascending |
| `cheapest` | `price` ascending |
| `shortest` | `durationMinutes` ascending |

---

## 7 — Flight details (fare quote)

### Navigation params

```
/{locale}/flight/{id}?reference_index={reference_index}&supplier={supplier}&search_id={search_id}
```

| Query | Source |
|-------|--------|
| `reference_index` | result.reference_index |
| `supplier` | result.supplier (default `"tbo"`) |
| `search_id` | last search response / storage |

### Request

```
POST /flights/fare-quote
```

```json
{
  "reference_index": "<from result>",
  "search_id": "<from search>",
  "supplier": "tbo",
  "currency": "USD"
}
```

Also accepts `result_index` as alternate key if backend requires it.

### Error handling (web)

| Condition | Flutter UX |
|-----------|------------|
| `409` or `actionRequired: confirm_new_price` | Show old → new price; allow re-quote |
| `404` / `410` / `422` / `500` or sold-out style message | Ticket unavailable → back to search |
| Success | Show fare quote UI → continue booking |

---

## 8 — Checkout & booking

### Initiate payment

```
POST /flights/checkout/initiate
```

```json
{
  "result_id": "<flight resultIndex / id from fare quote>",
  "search_id": "<saved>",
  "supplier": "tbo",
  "currency": "USD",
  "flight": { },
  "passengers": [
    {
      "title": "Mr",
      "first_name": "Ahmed",
      "last_name": "Ali",
      "type": "adult",
      "date_of_birth": "1990-01-15",
      "passport_number": "…",
      "passport_expiry": "2030-01-01",
      "nationality": "EG",
      "email": "a@example.com",
      "phone": "+201000000000",
      "gender": "1",
      "is_lead_passenger": true
    }
  ],
  "callback_url": "https://your.app/booking/flight/return",
  "error_url": "https://your.app/booking/flight/return?status=error"
}
```

### Response

```json
{
  "success": true,
  "booking_reference": "SAFER-…",
  "payment_url": "https://…myfatoorah…"
}
```

1. Save `booking_reference`  
2. Open / launch `payment_url` (external browser / WebView)  

### Booking status

```
GET /flights/booking/{booking_reference}
```

### PDFs (optional)

```
GET /flights/booking/{reference}/ticket
GET /flights/booking/{reference}/invoice
```

Absolute base: `https://backend.saferbe.com/api/v1`.

---

## 9 — Headers & currency

Always send:

```
Content-Type: application/json
Accept: application/json
Accept-Language: en | ar
```

Currency rules (web):

- App stores a selected **ISO 4217** 3-letter code (`USD`, `SAR`, …)
- Every search injects both `currency` and `Currency` on the body
- Do not overwrite a user-selected currency with geo defaults if the user already chose one

---

## 10 — Recommended Flutter architecture

### Models to keep in sync

1. `FlightSearchForm` / query params (section 2)  
2. `FlightSearchPayload` (section 4)  
3. `FlightResult` list item  
4. `FlightResultsFilterState`:

```dart
// conceptual
stops: any | direct | one_stop_or_less
includesCheckedBaggage: bool
airlines: List<String>
priceMin / priceMax: double?
originTimeSlots / destinationTimeSlots: List<slot>
sortBy: best | cheapest | shortest
```

### Services

| Service | Endpoints |
|---------|-----------|
| `AirportRepository` | suggest, list, autocomplete |
| `AirlineRepository` | list, autocomplete |
| `FlightSearchRepository` | search, cheapest, fastest |
| `FareQuoteRepository` | fare-quote |
| `FlightCheckoutRepository` | checkout/initiate, booking/{ref} |

### State machine (results)

```
idle → searching → resultsLoaded
                 ↘ empty (incl. 502 soft-empty)
resultsLoaded → refining (client filters)      // no network
resultsLoaded → searching (airline / criteria) // network
resultsLoaded → quoting → checkout → paying → bookingStatus
```

### Performance tips (parity)

- Cache last `search_id` + full `data` while criteria server key is unchanged  
- Debounce airline multi-select before re-POST (~400–500 ms)  
- Do not re-search on sort / stops / baggage / price-only changes  
- Prefetch airport suggest only when the field is focused  
- Airline autocomplete only when query length ≥ 2  

---

## 11 — Minimal sequence (happy path)

1. `GET /airports/suggest?q=cai` → pick `CAI`  
2. `GET /flights/airports` or autocomplete → pick `DXB`  
3. User: one-way, dates, 1 adult, economy, currency `USD`  
4. `POST /flights/search` with body (section 4)  
5. Store `search_id`, show list  
6. Client-filter sort=cheapest, stops=direct  
7. User selects preferred airlines `MS` → debounced re-`POST /flights/search` with `PreferredAirlines` + filters  
8. Tap item → `POST /flights/fare-quote` with `reference_index` + `search_id`  
9. Fill passengers → `POST /flights/checkout/initiate` → open `payment_url`  
10. `GET /flights/booking/{booking_reference}` after return  

---

## 12 — Quick endpoint index

| Step | Method | Path |
|------|--------|------|
| Airport suggest | GET | `/airports/suggest` |
| Flight airports list | GET | `/flights/airports` |
| Flight airports autocomplete | GET | `/flights/airports/autocomplete` |
| Airlines list | GET | `/airlines` |
| Airlines autocomplete | GET | `/airlines/autocomplete` |
| Search | POST | `/flights/search` |
| Cheapest highlight | POST | `/flights/cheapest?limit=N` |
| Fastest highlight | POST | `/flights/fastest?limit=N` |
| Fare quote | POST | `/flights/fare-quote` |
| Checkout | POST | `/flights/checkout/initiate` |
| Booking status | GET | `/flights/booking/{reference}` |
| Ticket PDF | GET | `/flights/booking/{reference}/ticket` |
| Invoice PDF | GET | `/flights/booking/{reference}/invoice` |

All paths are under base `https://backend.saferbe.com/api/v1`.

---

## Related web source (for engineers)

| Concern | Path |
|---------|------|
| Routes | `app/[locale]/(landing)/flight/**` |
| Search URL / fingerprint | `src/modules/home/features/flight-tab/util/flightSearchUrl.ts` |
| Payload mapper | `src/modules/home/mappers/toFlightSearchPayload.ts` |
| Search API | `src/modules/home/api/flights/search.ts` |
| Types | `src/modules/home/api/flights/types.ts` |
| Client filters / sort | `src/modules/flight/features/flight-search-results/utils/*` |
| Filter types | `src/modules/flight/features/flight-search-results/types/filter.types.ts` |
| Fare quote screen | `src/modules/flight/screens/FlightDetailsScreen.tsx` |
| Checkout | `src/modules/home/api/flights/checkout.ts` |

---

*Generated for Flutter parity with Safer Be web flight search & filters. Prefer backend contracts if this doc and live API diverge; update both platforms together when adding filters that must hit the server.*
