# API Reference — Traveling Safer v1

**Base URL:** `/api/v1`  
**Content-Type:** `application/json`  
**Locale:** Auto-detected via URL prefix (`/ar/...`), `Accept-Language` header, or user preference.

---

## Table of Contents

- [Reference Data](#reference-data)
- [Flights](#flights)
- [Hotels](#hotels)
- [Pricing](#pricing)
- [Error Format](#error-format)
- [Localization](#localization)

---

## Reference Data

### List Countries

```
GET /api/v1/countries
```

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `search` | string | no | Filter by country name or ISO code |
| `per_page` | int | no | Results per page (default 50, max 100) |
| `sort_by` | string | no | Sort field (default `sort_order`) |
| `sort_order` | string | no | `asc` or `desc` (default `asc`) |

**Response:**

```json
{
  "data": [
    {
      "id": 1,
      "code": "SA",
      "phone_code": "+966",
      "geoname_id": 1023582,
      "iso_alpha3": "SAU",
      "name": "Saudi Arabia",
      "iso_numeric": "682"
    }
  ],
  "links": { "first": "...", "last": "...", "prev": null, "next": "..." },
  "meta": { "current_page": 1, "last_page": 5, "per_page": 50, "total": 230 }
}
```

---

### List Cities

```
GET /api/v1/cities
```

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `search` | string | no | Search query (prefix match, min 2 chars) |
| `locale` | string | no | `en` or `ar` (default: app locale) |
| `country` | string | no | 2-letter ISO country code filter |
| `limit` | int | no | Max results for search/country modes (default 20) |
| `per_page` | int | no | Results per page for paginated mode (default 100, max 500) |
| `cursor` | string | no | Cursor for paginated mode |

**Response (search/country mode):**

```json
{
  "data": [
    { "id": 1, "code": "JED", "name": "Jeddah", "country_code": "SA", "country_name": "Saudi Arabia", "latitude": 21.4858, "longitude": 39.1925 }
  ],
  "meta": { "count": 5 }
}
```

**Response (paginated mode):**

```json
{
  "data": [...],
  "meta": { "count": 150, "has_more": true, "next_page": "...", "prev_page": null, "per_page": 100 }
}
```

---

### List Airlines

```
GET /api/v1/airlines
```

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `search` | string | no | Filter by airline name or IATA code |
| `per_page` | int | no | Results per page (default 50, max 100) |
| `sort_by` | string | no | Sort field (default `sort_order`) |
| `sort_order` | string | no | `asc` or `desc` (default `asc`) |

**Response:**

```json
{
  "data": [
    {
      "id": 1,
      "iata_code": "SV",
      "name": "Saudi Arabian Airlines",
      "icao_code": "SVA",
      "logo_url": "/logos/sv.png",
      "geoname_id": 1023582,
      "is_low_cost": false
    }
  ],
  "links": { "first": "...", "last": "...", "prev": null, "next": "..." },
  "meta": { "current_page": 1, "last_page": 3, "per_page": 50, "total": 120 }
}
```

---

### Autocomplete Airlines

```
GET /api/v1/airlines/autocomplete
```

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `q` | string | yes | Search query (min 1 char) |
| `limit` | int | no | Max results (default 20, max 100) |

**Response:**

```json
{
  "data": [
    { "code": "SV", "name": "Saudi Arabian Airlines" },
    { "code": "EK", "name": "Emirates" }
  ]
}
```

---

### List Currencies

```
GET /api/v1/currencies
```

Returns all active supported currencies with translations.

**Response:**

```json
{
  "data": [
    {
      "id": 1,
      "code": "USD",
      "name": "US Dollar",
      "symbol": "$",
      "decimal_precision": 2,
      "is_default": true
    },
    {
      "id": 2,
      "code": "SAR",
      "name": "Saudi Riyal",
      "symbol": "ر.س",
      "decimal_precision": 2,
      "is_default": false
    }
  ],
  "meta": { "count": 10 }
}
```

---

## Flights

### Autocomplete Airports

```
GET /api/v1/flights/airports/autocomplete
```

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `q` | string | yes | Search query (min 1 char) |
| `limit` | int | no | Max results (default 20) |

**Response:**

```json
{
  "data": [
    {
      "code": "JED",
      "name": "King Abdulaziz International",
      "city": "Jeddah",
      "country": "Saudi Arabia",
      "country_code": "SA"
    }
  ]
}
```

---

### Search Flights

```
POST /api/v1/flights/search
```

Rate limited via `throttle:search`.

**Request Body:**

```json
{
  "JourneyType": 1,
  "Origin": "JED",
  "Destination": "CAI",
  "DepartureDate": "2026-08-15",
  "ReturnDate": "2026-08-20",
  "AdultCount": 1,
  "ChildCount": 0,
  "InfantCount": 0,
  "FlightCabinClass": 1,
  "currency": "SAR",
  "PreferredAirlines": ["SV"],
  "Segments": [
    {
      "Origin": "JED",
      "Destination": "CAI",
      "PreferredDepartureTime": "2026-08-15",
      "FlightCabinClass": 1
    }
  ],
  "filters": {
    "airlines": ["SV"],
    "stops": "nonstop",
    "cabin_class": "economy",
    "departure_time": "morning",
    "arrival_time": "afternoon",
    "refundable": true,
    "min_price": 100,
    "max_price": 2000
  }
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `JourneyType` | int | no | `1`=OneWay, `2`=Return, `3`=MultiCity |
| `Origin` | string | conditional | 3-letter IATA code; required if no `Segments` |
| `Destination` | string | conditional | 3-letter IATA code; required if no `Segments` |
| `DepartureDate` | date | conditional | `after_or_equal:today` |
| `ReturnDate` | date | no | Required for Return journeys |
| `AdultCount` | int | **yes** | 1-9 |
| `ChildCount` | int | no | 0-9 (default 0) |
| `InfantCount` | int | no | 0-9 (default 0) |
| `FlightCabinClass` | int | no | `0`=All, `1`=Economy, `2`=Business, `3`=First, `4`=Premium Economy |
| `currency` | string | no | 3-letter ISO 4217 (default `USD`) |
| `Segments` | array | conditional | Required for MultiCity; 2-6 segments |
| `PreferredAirlines` | string[] | no | 2-letter IATA airline codes |
| `filters` | object | no | Optional filter criteria |

**JourneyType values:**

| Value | Description |
|-------|-------------|
| `1` | One Way |
| `2` | Return |
| `3` | Multi City (requires `Segments` array) |

**Filter options:**

| Key | Type | Description |
|-----|------|-------------|
| `airlines` | string[] | Filter by airline IATA codes |
| `stops` | string | `nonstop`, `1_stop`, `2_stops`, `any` |
| `cabin_class` | string | `economy`, `business`, `first`, `premium_economy` |
| `departure_time` | string | `morning` (06-12), `afternoon` (12-18), `evening` (18-00), `night` (00-06) |
| `arrival_time` | string | Same as departure_time |
| `refundable` | bool | Filter refundable flights only |
| `min_price` | float | Minimum total price |
| `max_price` | float | Maximum total price |

**Response:**

```json
{
  "data": {
    "results": [
      {
        "id": "SV_1234_JED_CAI",
        "result_index": "0",
        "reference_index": "SV_001",
        "supplier": "tbo",
        "journey_type": "one_way",
        "legs": [
          {
            "flight_number": "SV 1234",
            "airline_code": "SV",
            "airline_name": "Saudia",
            "departure_airport": "JED",
            "arrival_airport": "CAI",
            "departure_time": "2026-08-15T08:00:00",
            "arrival_time": "2026-08-15T10:30:00",
            "duration_minutes": 150,
            "duration_text": "2h 30m",
            "stops_count": 0,
            "cabin_class": "economy",
            "operating_carrier_code": "SV"
          }
        ],
        "price": {
          "total": 1250.00,
          "currency": "SAR",
          "base_fare": 980.00,
          "taxes": 200.00,
          "other_charges": 70.00,
          "breakdown": []
        },
        "baggage": {
          "carry_on": "7kg",
          "checked": "23kg"
        },
        "refundable": true,
        "last_ticket_date": "2026-08-10",
        "best_deal_labels": ["cheapest"]
      }
    ],
    "total": 42,
    "currency": "SAR",
    "highlights": {
      "cheapest": "SV_1234_JED_CAI",
      "fastest": "EK_5678_JED_CAI",
      "nonstop_count": 15
    }
  }
}
```

---

### Cheapest Flights

```
POST /api/v1/flights/cheapest
```

Same request body as `/search`. Returns only the cheapest option per route.

---

### Fastest Flights

```
POST /api/v1/flights/fastest
```

Same request body as `/search`. Returns only the fastest option per route.

---

### Fare Quote

```
POST /api/v1/flights/fare-quote
```

Get detailed pricing for a specific flight result.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `result_index` | string | conditional | Result index from search |
| `reference_index` | string | conditional | Alternative reference index |
| `currency` | string | no | Requested currency (ISO 4217) |

Exactly one of `result_index` or `reference_index` must be provided.

**Response:** Full flight result with detailed fare breakdown (same structure as search result).

---

### Flight Zones

```
GET /api/v1/flights/zones
```

Returns configured geographic zones for zone-based pricing.

**Response:**

```json
{
  "data": [
    {
      "id": 1,
      "code": "MENA",
      "name": "Middle East & North Africa",
      "countries": ["SA", "AE", "KW", "EG", "QA", "BH", "OM"]
    }
  ]
}
```

---

### Detect User Zone

```
POST /api/v1/flights/detect-zone
```

Detect the user's geographic zone based on IP or request headers.

**Response:**

```json
{
  "data": {
    "zone": "MENA",
    "country_code": "SA",
    "city": "Riyadh"
  }
}
```

---

### List Airports

```
GET /api/v1/flights/airports
```

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `q` | string | no | Search query |
| `limit` | int | no | Max results (default 20) |
| `zone` | string | no | Filter by zone code |

---

### Airport by Code

```
GET /api/v1/flights/airports/{code}
```

Get a specific airport by IATA code (e.g., `JED`, `CAI`).

---

### Nearby Airports

```
GET /api/v1/flights/airports/nearby
```

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `latitude` | float | yes | Latitude |
| `longitude` | float | yes | Longitude |
| `radius` | int | no | Radius in km (default 100) |

---

### Flight Types

```
GET /api/v1/flights/flight-types
```

Returns available flight type configurations.

---

### Booking

```
POST /api/v1/flights/book
```

Rate limited via `throttle:booking`.

**Request Body:**

```json
{
  "result_id": "0",
  "supplier": "tbo",
  "flight": {
    "resultIndex": "0",
    "airlineCode": "SV",
    "airlineName": "Saudia",
    "totalPrice": 1250.00,
    "baseFare": 980.00,
    "tax": 200.00,
    "currency": "SAR",
    "isRefundable": true,
    "segments": [
      {
        "origin": { "code": "JED", "name": "King Abdulaziz International", "city": "Jeddah", "country": "Saudi Arabia" },
        "destination": { "code": "CAI", "name": "Cairo International", "city": "Cairo", "country": "Egypt" },
        "airlineCode": "SV",
        "airlineName": "Saudia",
        "flightNumber": "SV 1234",
        "departureTime": "2026-08-15T08:00:00",
        "arrivalTime": "2026-08-15T10:30:00",
        "duration": 150,
        "cabinClass": 1
      }
    ]
  },
  "passengers": [
    {
      "title": "Mr",
      "first_name": "Mohammed",
      "last_name": "Al Saud",
      "type": "adult",
      "date_of_birth": "1990-05-15",
      "passport_number": "A12345678",
      "passport_expiry": "2030-05-15",
      "nationality": "SA",
      "email": "mohammed@example.com",
      "phone": "+966501234567",
      "is_lead_passenger": true,
      "gender": "1",
      "address": "123 King Fahd Road",
      "address2": "Riyadh, Saudi Arabia"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `result_id` | string | **yes** | `resultIndex` from search/fare-quote |
| `supplier` | string | no | `tbo` or `amadeus` (default: `tbo`) |
| `flight` | object | **yes** | Flight data (camelCase format from fare-quote) |
| `flight_result` | object | **yes** | Alternative: flight data (snake_case format from search) |
| `passengers` | array | **yes** | 1-9 passengers |

**Passenger fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | **yes** | `Mr`, `Mrs`, `Ms`, `Miss`, `Dr` |
| `first_name` | string | **yes** | Max 100 chars |
| `last_name` | string | **yes** | Max 100 chars |
| `type` | string | **yes** | `adult`, `child`, `infant` |
| `date_of_birth` | date | **yes** | Must be before today |
| `passport_number` | string | **yes** | 6-20 chars |
| `passport_expiry` | date | **yes** | Min 6 months after departure |
| `nationality` | string | **yes** | 2-letter ISO code |
| `email` | email | **yes** | Lead guest email |
| `phone` | string | **yes** | 10-15 digits, may start with `+` |
| `is_lead_passenger` | boolean | no | |
| `gender` | string | no | `"1"` = Male, `"2"` = Female. Required by supplier; no default applied. |
| `address` | string | no | Primary address line. Max 255 chars. Defaults to empty string if omitted. |
| `address2` | string | no | Secondary address line. Max 255 chars. Defaults to empty string if omitted. |
| `phone_country_code` | string | no | Country code for phone number. Max 4 digits, may start with `+`. |

**Flight segment fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `origin.code` | string | **yes** | 3-letter IATA code |
| `origin.name` | string | **yes** | Airport name |
| `origin.city` | string | **yes** | City name |
| `origin.country` | string | **yes** | Country name |
| `destination.code` | string | **yes** | 3-letter IATA code |
| `destination.name` | string | **yes** | Airport name |
| `destination.city` | string | **yes** | City name |
| `destination.country` | string | **yes** | Country name |
| `airlineCode` | string | **yes** | 2-letter IATA airline code |
| `airlineName` | string | **yes** | Airline name |
| `flightNumber` | string | **yes** | Max 10 chars |
| `departureTime` | datetime | **yes** | ISO 8601 format |
| `arrivalTime` | datetime | **yes** | ISO 8601 format |
| `duration` | int | **yes** | Duration in minutes (min: 1) |
| `baggage` | string | no | Baggage allowance |
| `cabinClass` | int | **yes** | `1`=Economy, `2`=Business, `3`=First, `4`=Premium Economy |

**Validation notes:**
- Phone numbers with duplicated country code + leading zero are rejected (e.g., `009660501234567`)
- Passport expiry must be at least 6 months after departure date
- `cabinClass` must be an integer matching the TBO FareQuote value, not a string label

**Response:**

```json
{
  "data": {
    "booking_reference": "BKG-2026-08-15-SV-001",
    "pnr": "ABC123",
    "status": "confirmed",
    "total_price": 1250.00,
    "currency": "SAR",
    "passengers": [
      { "name": "Mohammed Al Saud", "type": "adult", "is_lead": true }
    ],
    "segments": [
      {
        "flight": "SV1234",
        "route": "JED → CAI",
        "departure": "2026-08-15T08:00:00",
        "arrival": "2026-08-15T10:30:00"
      }
    ]
  },
  "message": "Booking created successfully"
}
```

---

### Booking Details

```
GET /api/v1/flights/booking/{reference}
```

Get booking details by PNR or booking reference.

**Response:** Full booking object with passengers and flight details.

---

### Issue Ticket

```
POST /api/v1/flights/ticket
```

Rate limited via `throttle:booking`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `pnr` | string | yes | PNR code |
| `booking_reference` | string | no | Alternative to `pnr` |

**Response:**

```json
{
  "data": {
    "ticket_number": "123-4567890123",
    "pnr": "ABC123",
    "status": "ticketed"
  }
}
```

---

### Release PNR

```
POST /api/v1/flights/booking/{reference}/release
```

Release (cancel) a pending booking.

---

### Refund

```
POST /api/v1/flights/booking/{reference}/refund
```

Rate limited via `throttle:booking`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `amount` | float | no | Refund amount (null = full refund) |
| `reason` | string | no | Default: "Customer request" |

---

### Download Ticket

```
GET /api/v1/flights/booking/{reference}/ticket
```

Download PDF ticket for a booking.

---

### Download Invoice

```
GET /api/v1/flights/booking/{reference}/invoice
```

Download PDF invoice for a booking.

---

### Clear Cache

```
DELETE /api/v1/flights/cache
```

Clear flight search cache. Admin use only.

---

## Hotels

### Search Hotels

```
POST /api/v1/hotels/search
```

Rate limited via `throttle:search`.

**Request Body:**

```json
{
  "city_code": "JED",
  "check_in": "2026-08-15",
  "check_out": "2026-08-20",
  "adults": 2,
  "children": 1,
  "child_ages": [5],
  "nationality": "SA",
  "currency": "SAR",
  "star_rating": 4,
  "min_price": 100,
  "max_price": 500,
  "supplier": "tbo_hotels",
  "filters": {
    "star_rating": [4, 5],
    "refundable": true,
    "min_price": 100,
    "max_price": 500,
    "board_type": "half_board"
  }
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `city_code` | string | conditional | IATA city code; required if no `hotel_code` |
| `hotel_code` | string | no | Specific hotel code |
| `check_in` | date | **yes** | `after_or_equal:today` |
| `check_out` | date | **yes** | Must be after `check_in` |
| `adults` | int | no | 1-20 (default 1) |
| `children` | int | no | 0-10 (default 0) |
| `child_ages` | int[] | no | Ages of children (0-17) |
| `nationality` | string | no | 2-letter ISO code |
| `currency` | string | no | 3-letter ISO code (default `USD`) |
| `star_rating` | int | no | Filter by star rating (1-7) |
| `min_price` | float | no | Minimum price |
| `max_price` | float | no | Maximum price |
| `supplier` | string | no | `tbo_hotels` (default) |
| `filters` | object | no | Filter criteria |
| `page` | int | no | Page number (default 1) |
| `per_page` | int | no | Results per page (1-100) |

**Hotel filter options:**

| Key | Type | Description |
|-----|------|-------------|
| `star_rating` | int[] | Star ratings to include |
| `refundable` | bool | Filter refundable rooms only |
| `min_price` | float | Minimum room price |
| `max_price` | float | Maximum room price |
| `board_type` | string | `room_only`, `breakfast`, `half_board`, `full_board`, `all_inclusive` |

**Response:**

```json
{
  "data": {
    "hotels": [
      {
        "hotel_code": "HOTEL001",
        "hotel_name": "Mövenpick Resort & Spa Jeddah",
        "giata_id": "12345",
        "description": "Luxury beachfront resort...",
        "star_rating": 5,
        "latitude": 21.7258,
        "longitude": 39.1580,
        "address": "North Corniche Road",
        "city": "Jeddah",
        "country": "Saudi Arabia",
        "phone": "+966123456789",
        "email": "info@resort.com",
        "website": "https://resort.com",
        "images": ["https://..."],
        "min_price": 350.00,
        "max_price": 800.00,
        "currency": "SAR",
        "rooms": [
          {
            "room_code": "DELX-001",
            "room_name": "Deluxe Room",
            "total_price": 450.00,
            "base_price": 400.00,
            "tax": 50.00,
            "currency": "SAR",
            "max_guests": 2,
            "bed_type": "king",
            "board_type": "breakfast",
            "cancellation_policy": "Free cancellation until 24 hours before check-in"
          }
        ]
      }
    ],
    "total": 15,
    "currency": "SAR"
  }
}
```

---

### Get Available Rooms

```
POST /api/v1/hotels/{hotelCode}/rooms
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `check_in` | date | **yes** | |
| `check_out` | date | **yes** | Must be after check_in |
| `guests` | array | **yes** | Array of room configurations |
| `guests[].adults` | int | **yes** | Adults per room (min 1) |
| `guests[].children` | int | no | Children per room |
| `currency` | string | no | 3-letter ISO code for price conversion |
| `supplier` | string | no | `tbo_hotels` |

---

### Book Hotel

```
POST /api/v1/hotels/book
```

Rate limited via `throttle:booking`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `hotel_code` | string | **yes** | |
| `check_in` | date | **yes** | |
| `check_out` | date | **yes** | |
| `rooms` | array | **yes** | Room configurations with guest details |
| `email` | email | **yes** | Lead guest email |
| `phone` | string | **yes** | Lead guest phone |
| `nationality` | string | **yes** | 2-letter ISO code |
| `supplier` | string | no | `tbo_hotels` (default) |

**Response:** Booking confirmation with reference number.

---

### Hotel Booking Details

```
GET /api/v1/hotels/booking/{reference}
```

Get hotel booking details by reference.

---

### Cancel Hotel Booking

```
POST /api/v1/hotels/booking/{reference}/cancel
```

Rate limited via `throttle:booking`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reason` | string | no | Cancellation reason |

---

### Hotel Reference: Autocomplete

```
GET /api/v1/hotels/reference/hotels/autocomplete
```

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `q` | string | yes | Search query |

---

### Hotel Reference: Top Destinations

```
GET /api/v1/hotels/reference/top-destinations
```

Returns popular hotel destinations.

---

### Hotel Reference: City Mapping

```
GET /api/v1/hotels/reference/mappings/city/{cityId}
```

Get supplier mapping for a city.

---

### Hotel Reference: Country Mapping

```
GET /api/v1/hotels/reference/mappings/country/{countryId}
```

Get supplier mapping for a country.

---

## Pricing

### Admin Routes

All admin pricing routes require `auth:sanctum` middleware.

#### Pricing Rules

```
GET    /api/v1/pricing/rules          — List all rules
POST   /api/v1/pricing/rules          — Create rule
GET    /api/v1/pricing/rules/{id}     — Get rule
PUT    /api/v1/pricing/rules/{id}     — Update rule
DELETE /api/v1/pricing/rules/{id}     — Delete rule
```

#### Coupons

```
GET    /api/v1/pricing/coupons          — List all coupons
POST   /api/v1/pricing/coupons          — Create coupon
GET    /api/v1/pricing/coupons/{id}     — Get coupon
PUT    /api/v1/pricing/coupons/{id}     — Update coupon
DELETE /api/v1/pricing/coupons/{id}     — Delete coupon
```

#### Analytics

```
GET /api/v1/pricing/analytics/logs      — Pricing audit logs
GET /api/v1/pricing/analytics/summary   — Pricing analytics summary
```

### Public Routes

#### Validate Coupon

```
POST /api/v1/pricing/coupons/validate
```

Rate limited via `pricing.coupon_rate_limit` config (default 10/min).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `code` | string | **yes** | Coupon code |
| `booking_amount` | float | **yes** | Booking total |
| `currency` | string | no | Currency code (default `USD`) |

**Response:**

```json
{
  "data": {
    "valid": true,
    "discount": 150.00,
    "discount_type": "fixed",
    "final_amount": 1100.00
  }
}
```

---

## Error Format

All errors follow a consistent format:

```json
{
  "success": false,
  "message": "Human-readable error message",
  "errors": {
    "field_name": ["Validation error details"]
  },
  "status_code": 422
}
```

### Error Codes

| Code | Description |
|------|-------------|
| `download_ticket_failed` | Ticket download failed |
| `download_invoice_failed` | Invoice download failed |
| `validation_error` | Request validation failed |
| `not_found` | Resource not found |
| `unauthorized` | Authentication required |
| `forbidden` | Insufficient permissions |
| `rate_limited` | Too many requests |
| `supplier_error` | Third-party supplier error |
| `server_error` | Internal server error |

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 409 | Conflict (e.g., already ticketed/cancelled) |
| 422 | Validation Error |
| 429 | Rate Limited |
| 500 | Server Error |
| 502 | Supplier Error |

---

## Localization

The API supports Arabic (ar) and English (en). All response content (city/airport names, descriptions, validation messages) is translated based on the current locale.

**Locale resolution priority:**

1. URL prefix: `/ar/api/v1/...` or `/en/api/v1/...`
2. Authenticated user's preferred locale
3. `Accept-Language` HTTP header
4. Session locale
5. App fallback locale (`en`)

### Set Locale

```
POST /api/v1/set-locale
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `locale` | string | **yes** | `en` or `ar` |

**Response:**

```json
{
  "locale": "ar",
  "direction": "rtl"
}
```
