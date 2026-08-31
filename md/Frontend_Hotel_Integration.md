# Frontend Hotel Booking Integration Guide (TBO & Juniper)

This guide documents the complete A-to-Z flow for frontend developers to integrate the hotel booking engine. It covers everything from searching for hotels (for both TBO and Juniper concurrently) to fetching rooms, initiating checkout via MyFatoorah, and handling the final booking redirect.

---

## 1. Search for Hotels (Aggregated)

When the user searches for a destination, the system will automatically query **both TBO Hotels and Juniper** in the background, aggregate the results, and return them in a unified format.

### **Endpoint**

`POST /api/v1/hotels/search`

### **Request Payload**

```json
{
    "city_code": "DXB", // Use the standard canonical City Code (e.g. DXB)
    "check_in": "2026-09-10",
    "check_out": "2026-09-12",
    "adults": 1,
    "children": 0,
    "currency": "SAR", // Optional: EUR, USD, SAR, etc.
    "nationality": "AE" // Important for Juniper/TBO pricing
}
```

_Note: Due to our recent updates, you can pass standard city codes like `"DXB"`. The backend will figure out the supplier-specific mappings (like `G292223` for Juniper or TBO mappings)._

### **Response (Extract)**

You will receive a list of hotels. Note the `supplier` and `rate_plan_code` keys—you must store and pass these when requesting rooms!

```json
{
    "success": true,
    "hotels": [
        {
            "hotel_code": "JP046300",
            "hotel_name": "Allsun Hotel Pil·larí Playa UAT",
            "supplier": "juniper", // Important for next steps!
            "rate_plan_code": "ya79d...==", // Important for next steps!
            "min_price": 108.72,
            "currency": "EUR"
        }
    ],
    "total": 1,
    "supplier": "multiple"
}
```

---

## 2. Fetch Available Rooms for a Specific Hotel

Once a user clicks on a search result, fetch the exact room availability.

### **Endpoint**

`POST /api/v1/hotels/{hotel_code}/rooms`
_(Example: `POST /api/v1/hotels/JP046300/rooms`)_

### **Request Payload**

You **MUST** pass the `supplier` and `rate_plan_code` exactly as you received them in Step 1.

```json
{
    "supplier": "juniper", // Pass the supplier from the search result!
    "rate_plan_code": "ya79d...==", // Pass the rate_plan_code from the search result!
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

### **Response (Extract)**

You will receive available rooms. Note the `room_id`, `room_code`, and `total_price`—these are critical for checkout.

```json
{
    "success": true,
    "hotel_code": "JP046300",
    "rooms": [
        {
            "room_id": "ya79d..._room_1", // Important: Used as cache key
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

---

## 3. Initiate Checkout & Connect to MyFatoorah

When the user selects a room and clicks "Book Now", you initiate the checkout session.

**This step locks the price and generates the MyFatoorah Payment URL.**

### **Endpoint**

`POST /api/v1/hotels/checkout/initiate`

### **Request Payload**

Pass the room selection exactly as received in the rooms API response. **Crucially, include `room_id`, `room_code`, and `total_price`.**

```json
{
    "supplier": "juniper", // OR tbo_hotels
    "hotel_code": "JP046300",
    "check_in": "2026-09-10",
    "check_out": "2026-09-12",
    "currency": "EUR",
    "email": "customer@email.com",
    "phone": "+966500000000",
    "nationality": "AE",
    "rooms": [
        {
            "room_id": "ya79d..._room_1", // Exactly from the Rooms response
            "room_code": "STD",
            "room_type_code": "STD",
            "meal_plan": "Room Only",
            "total_price": 94.3, // Send the cost you displayed to the user
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
    "callback_url": "https://frontend.saferbe.com/payment/success", // Where user returns
    "error_url": "https://frontend.saferbe.com/payment/failed" // Where user returns
}
```

### **Response (Extract)**

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

### **Action:** Redirect the User

The frontend should immediately redirect the user to `data.payment_url`.

---

## 4. Payment Callback & Finalizing the Booking

Once the user completes the payment on the MyFatoorah gateway, MyFatoorah redirects the user back to the `callback_url` you provided earlier (e.g., `https://frontend.saferbe.com/payment/success?paymentId=123456789`).

### **Endpoint**

`GET /api/v1/hotels/checkout/callback?paymentId=123456789`
_(Typically, the backend is polling webhooks or the frontend can hit this endpoint optionally to verify. The best practice is for the frontend to render the successful checkout UI after checking status)._

Alternatively, SaferBe API processes the background Webhook from MyFatoorah to confirm the booking directly with Juniper or TBO.

To check the exact status of the booking reference you got in Step 3:

### **Booking Details Endpoint**

`GET /api/v1/hotels/booking/SAFER-1786652184-9123`

### **Summary of Important Keys:**

1. **`city_code` (Search)** -> Determines aggregated search limits.
2. **`supplier` (Rooms & Checkout)** -> Tells backend whether to talk to TBO or Juniper.
3. **`rate_plan_code` (Rooms)** -> Used by Juniper to fetch live room availability.
4. **`room_id` / `room_code` (Checkout)** -> Critical for the backend price cache lock, ensuring correct payment amounts are routed to MyFatoorah.
