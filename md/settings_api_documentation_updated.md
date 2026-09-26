# Settings API Documentation

This document defines how the **Mobile Application** should use the System Settings API to control the booking and payment experience.

---

## 1. Mobile Application API

### Get System Settings

Retrieves the public settings used by the mobile application.

- **HTTP Method:** `GET`
- **Endpoint:** `/api/v1/settings`
- **Authentication:** None (Public)
- **Headers:**

```http
Accept: application/json
```

### Request Body

None.

### Success Response

```json
{
  "success": true,
  "data": {
    "show_payment_gateway_mobile": true
  }
}
```

---

# 2. `show_payment_gateway_mobile`

The `show_payment_gateway_mobile` setting controls whether the mobile application operates in **normal online booking/payment mode** or **WhatsApp contact mode**.

## When the value is `true`

The mobile application works normally:

- Show the booking price.
- Show the **Book Now** button.
- Allow the user to continue with the booking process.
- Show the available payment options / Payment Gateway.
- Allow online payment.

Example:

```json
{
  "show_payment_gateway_mobile": true
}
```

Expected Flutter behavior:

```dart
if (showPaymentGatewayMobile) {
  // Show price
  // Show "Book Now"
  // Show payment options
  // Allow online payment
}
```

---

## When the value is `false`

The mobile application enters **WhatsApp Contact Mode**.

The application should still display the booking/trip/service information and its details, but online booking and payment must not be available.

### Hide:

- ❌ Booking price
- ❌ **Book Now** button
- ❌ Payment Gateway
- ❌ Any online payment action

### Show:

- ✅ Booking/trip/service details
- ✅ **Contact via WhatsApp** button

Example:

```json
{
  "show_payment_gateway_mobile": false
}
```

Expected Flutter behavior:

```dart
if (!showPaymentGatewayMobile) {
  // Show booking/trip/service details

  // Hide price
  // Hide "Book Now"
  // Hide payment options

  // Show "Contact via WhatsApp"
}
```

---

# 3. WhatsApp Button

When `show_payment_gateway_mobile` is `false`, the Flutter application should display a WhatsApp contact button instead of the normal booking action.

The WhatsApp button should open WhatsApp using the WhatsApp number already configured for the application.

Example behavior:

```text
show_payment_gateway_mobile = false
                |
                v
       Hide Price
       Hide Book Now
       Hide Payment
                |
                v
      Show WhatsApp Button
                |
                v
       Open WhatsApp Chat
```

The WhatsApp number can be configured according to the application's existing configuration.

> Note: This API documentation does not define a new WhatsApp-number API field. The Flutter application should use the WhatsApp number already available/configured in the application.

---

# 4. Admin Dashboard APIs

The existing Admin Dashboard APIs remain responsible for viewing and updating the setting.

## A. View All Settings

- **HTTP Method:** `GET`
- **Endpoint:** `/api/v1/admin/settings`
- **Authentication:** Required (`auth:sanctum`)

### Headers

```http
Authorization: Bearer <ADMIN_BEARER_TOKEN>
Accept: application/json
```

### Request Body

None.

### Success Response

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "key": "show_payment_gateway_mobile",
      "value": "1",
      "created_at": "2026-09-07T11:00:00.000000Z",
      "updated_at": "2026-09-07T11:00:00.000000Z"
    }
  ]
}
```

---

## B. Update Settings

- **HTTP Method:** `POST`
- **Endpoint:** `/api/v1/admin/settings`
- **Authentication:** Required (`auth:sanctum`)

### Headers

```http
Authorization: Bearer <ADMIN_BEARER_TOKEN>
Content-Type: application/json
Accept: application/json
```

### Enable Normal Online Booking and Payment

Send:

```json
{
  "show_payment_gateway_mobile": true
}
```

Result:

- Price is visible.
- **Book Now** is visible.
- Payment options are visible.
- Online payment is available.

### Disable Online Booking and Payment

Send:

```json
{
  "show_payment_gateway_mobile": false
}
```

Result:

- Price is hidden.
- **Book Now** is hidden.
- Payment options are hidden.
- Online payment is unavailable.
- Booking/trip/service details remain visible.
- **Contact via WhatsApp** is displayed.

### Success Response

```json
{
  "success": true,
  "message": "Settings updated successfully.",
  "data": [
    {
      "id": 1,
      "key": "show_payment_gateway_mobile",
      "value": "0",
      "created_at": "2026-09-07T11:00:00.000000Z",
      "updated_at": "2026-09-07T11:08:00.000000Z"
    }
  ]
}
```

---

# 5. Flutter Implementation Logic

The core business logic should follow this rule:

```dart
final bool showPaymentGatewayMobile =
    settings.showPaymentGatewayMobile;

if (showPaymentGatewayMobile) {
  // NORMAL BOOKING MODE
  //
  // Show:
  // - Price
  // - Book Now
  // - Payment Gateway
  //
  // Allow:
  // - Booking
  // - Online payment
} else {
  // WHATSAPP CONTACT MODE
  //
  // Show:
  // - Booking/trip/service details
  // - Contact via WhatsApp
  //
  // Hide:
  // - Price
  // - Book Now
  // - Payment Gateway
  //
  // Do not allow:
  // - Online booking
  // - Online payment
}
```

---

# 6. Final Behavior

| Setting | Price | Book Now | Payment | Details | WhatsApp |
|---|---|---|---|---|---|
| `true` | ✅ Show | ✅ Show | ✅ Show | ✅ Show | Optional |
| `false` | ❌ Hide | ❌ Hide | ❌ Hide | ✅ Show | ✅ Show |

The backend setting therefore acts as a remote switch between:

**Normal Online Booking Mode**

and

**WhatsApp Contact Mode**.

No Flutter app update should be required when the Admin changes the setting from the Admin Dashboard.
