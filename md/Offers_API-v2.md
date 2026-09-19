# Traveling Safer API V1 - Offers Module Documentation

## GET Offers › Available

**Description:** Retrieves a list of publicly available marketing offers.
**Authentication:** Public (No Bearer Token Required)

---

### 1. Request Details

- **Method:** `GET`
- **URL:** `{{base_url}}/api/v1/offers/available`

#### Request Headers

| Header | Value | Description |
| :--- | :--- | :--- |
| `Accept` | `application/json` | Enforces a JSON response format. |
| `Accept-Language` | `{{locale}}` | The preferred language for localization (e.g., `en`, `ar`). |
| `X-Request-Id` | `{{$guid}}` | A unique identifier for request tracing. |

#### Query Parameters
*(No specific query parameters are defined in the Postman collection for this endpoint)*

#### Request Body
*(Empty - Not applicable for this GET request)*

---

### 2. Response Details

*Note: The Postman collection does not contain a saved static response payload for this specific endpoint. However, based on the global test scripts included in the collection, the API utilizes a standardized JSON envelope structure.*

#### Expected 200 OK (Success)

The successful response will typically return an HTTP Status 200 with a `success` flag set to `true`, alongside the offers payload in the `data` array.

```json
{
  "success": true,
  "data": [
    {
      "id": 101,
      "title": "Summer Flight Sale",
      "description": "Get 15% off on all flights to DXB.",
      "code": "SUMMER15",
      "discount_type": "percentage",
      "discount_value": 15,
      "valid_from": "2026-09-01T00:00:00Z",
      "valid_until": "2026-09-30T23:59:59Z",
      "image_url": "https://example.com/images/offers/summer-sale.png"
    },
    {
      "id": 102,
      "title": "Welcome Hotel Bonus",
      "description": "Save $50 on your first hotel booking.",
      "code": "WELCOME50",
      "discount_type": "fixed",
      "discount_value": 50,
      "currency": "USD",
      "valid_from": "2026-01-01T00:00:00Z",
      "valid_until": null,
      "image_url": "https://example.com/images/offers/welcome-hotel.png"
    }
  ],
  "message": "Available offers retrieved successfully."
}
```

#### Expected 500 Internal Server Error (Failure)
If there is a server-side failure or database issue, the API will return a 5xx status code.

```json
{
  "success": false,
  "message": "An unexpected error occurred while retrieving offers.",
  "error_code": "INTERNAL_SERVER_ERROR"
}
```
