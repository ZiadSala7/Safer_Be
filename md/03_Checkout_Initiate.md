# Step 3 — Initiate Checkout & Connect to MyFatoorah

## What this step does
Triggered when the user picks a room and clicks "Book Now". This call **locks the price** on the backend and generates a **MyFatoorah payment URL** for the user to pay through.

### Endpoint
`POST /api/v1/hotels/checkout/initiate`

### Request Payload
Pass the room selection **exactly as received from the Rooms API** — especially `room_id`, `room_code`, and `total_price`.
```json
{
    "supplier": "juniper",
    "hotel_code": "JP046300",
    "check_in": "2026-09-10",
    "check_out": "2026-09-12",
    "currency": "EUR",
    "email": "customer@email.com",
    "phone": "+966500000000",
    "nationality": "AE",
    "rooms": [
        {
            "room_id": "ya79d..._room_1",
            "room_code": "STD",
            "room_type_code": "STD",
            "meal_plan": "Room Only",
            "total_price": 94.3,
            "base_price": 94.3,
            "guests": [
                {
                    "title": "Mr",
                    "first_name": "John",
                    "last_name": "Doe",
                    "age": 30
                }
            ]
        }
    ],
    "callback_url": "https://frontend.saferbe.com/payment/success",
    "error_url": "https://frontend.saferbe.com/payment/failed"
}
```
- `supplier`: either `"juniper"` or `"tbo_hotels"`.
- `callback_url` / `error_url`: where MyFatoorah sends the user back to, depending on payment outcome.

### Response (Extract)
```json
{
    "success": true,
    "data": {
        "booking_reference": "SAFER-1786652184-9123",
        "payment_url": "https://demo.myfatoorah.com/En/KWT/PayInvoice/Details/0507...",
        "message": "Checkout initiated successfully. Please redirect to payment_url."
    }
}
```

## Action required
Immediately **redirect the browser to `data.payment_url`.** Also store `booking_reference` — you'll need it in Step 4 to look up the booking status.
