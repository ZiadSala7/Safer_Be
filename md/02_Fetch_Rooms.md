# Step 2 — Fetch Available Rooms for a Specific Hotel

## What this step does
Once the user clicks into a specific hotel from the search results, this endpoint fetches the real, live room availability and pricing for that hotel.

### Endpoint
`POST /api/v1/hotels/{hotel_code}/rooms`
_Example: `POST /api/v1/hotels/JP046300/rooms`_

### Request Payload
**You MUST echo back `supplier` and `rate_plan_code` exactly as returned in Step 1's search response.**
```json
{
    "supplier": "juniper",
    "rate_plan_code": "ya79d...==",
    "check_in": "2026-09-10",
    "check_out": "2026-09-12",
    "currency": "EUR",
    "guests": [
        {
            "adults": 1,
            "children": 0
        }
    ]
}
```

### Response (Extract)
```json
{
    "success": true,
    "hotel_code": "JP046300",
    "rooms": [
        {
            "room_id": "ya79d..._room_1",
            "room_code": "STD",
            "room_type_code": "STD",
            "meal_plan": "Room Only",
            "total_price": 94.3,
            "base_price": 94.3,
            "currency": "EUR"
        }
    ]
}
```

## What to keep
For each room the user could pick, store `room_id`, `room_code`, and `total_price`.
- `room_id` doubles as a **cache key** on the backend — it's how the price gets locked in the next step.
- These three values must be sent back **exactly as received** in Step 3's checkout call.
