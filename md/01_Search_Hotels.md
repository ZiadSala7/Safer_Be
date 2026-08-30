# Step 1 — Search for Hotels (Aggregated)

## What this step does
When the user searches a destination, this single endpoint queries **both TBO Hotels and Juniper in the background simultaneously**, merges their results, and hands you back one unified list. You don't call TBO and Juniper separately — the backend does the fan-out for you.

### Endpoint
`POST /api/v1/hotels/search`

### Request Payload
```json
{
    "city_code": "DXB",
    "check_in": "2026-09-10",
    "check_out": "2026-09-12",
    "adults": 1,
    "children": 0,
    "currency": "SAR",
    "nationality": "AE"
}
```
- `city_code`: standard canonical code (e.g. `DXB`) — backend maps it internally to whatever TBO/Juniper expect.
- `currency`: optional (EUR, USD, SAR, etc.).
- `nationality`: important — Juniper/TBO price differently depending on this.

### Response (Extract)
```json
{
    "success": true,
    "hotels": [
        {
            "hotel_code": "JP046300",
            "hotel_name": "Allsun Hotel Pil·larí Playa UAT",
            "supplier": "juniper",
            "rate_plan_code": "ya79d...==",
            "min_price": 108.72,
            "currency": "EUR"
        }
    ],
    "total": 1,
    "supplier": "multiple"
}
```

## What to keep
For every hotel card you render, **store `supplier` and `rate_plan_code` alongside it in your frontend state.** You will need to send both of these back verbatim in Step 2 — they're not something you can regenerate later.
