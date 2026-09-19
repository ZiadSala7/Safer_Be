# Settings API Documentation

This document provides complete instructions for developers integrating the **System Settings API** in both the **Mobile Application** and the **Admin Dashboard**.

---

## 📱 1. Mobile Application API (Public)

### **Get System Settings**
Retrieves all public settings (such as payment gateway visibility) for the mobile app.

* **HTTP Method**: `GET`
* **Endpoint**: `/api/v1/settings`
* **Authentication**: None (Public)
* **Headers**:
  ```http
  Accept: application/json
  ```

#### **Request Body**
> *None*

#### **Success Response (`200 OK`)**
```json
{
  "success": true,
  "data": {
    "show_payment_gateway_mobile": true
  }
}
```

#### **Mobile Integration Example (Flutter / Dart / React Native)**
```javascript
// Example logic in Mobile App
if (response.data.show_payment_gateway_mobile === true) {
    // Show Payment Gateway options in Checkout screen
} else {
    // Hide Payment Gateway options
}
```

---

## 🛠️ 2. Admin Dashboard APIs (Protected)

---

### **A. View All Settings**
Retrieves all settings from the database for display in the Admin Dashboard panel.

* **HTTP Method**: `GET`
* **Endpoint**: `/api/v1/admin/settings`
* **Authentication**: Required (`auth:sanctum`)
* **Headers**:
  ```http
  Authorization: Bearer <ADMIN_BEARER_TOKEN>
  Accept: application/json
  ```

#### **Request Body**
> *None*

#### **Success Response (`200 OK`)**
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

### **B. Update Settings**
Updates one or more setting values from the Admin Dashboard.

* **HTTP Method**: `POST`
* **Endpoint**: `/api/v1/admin/settings`
* **Authentication**: Required (`auth:sanctum`)
* **Headers**:
  ```http
  Authorization: Bearer <ADMIN_BEARER_TOKEN>
  Content-Type: application/json
  Accept: application/json
  ```

#### **Request Body Example (To Disable Payment in Mobile)**
```json
{
  "show_payment_gateway_mobile": false
}
```

#### **Request Body Example (To Enable Payment in Mobile)**
```json
{
  "show_payment_gateway_mobile": true
}
```

#### **Success Response (`200 OK`)**
```json
{
  "success": true,
  "message": "Settings updated successfully.",
  "data": [
    {
      "id": 1,
      "key": "show_payment_gateway_mobile",
      "value": "1",
      "created_at": "2026-09-07T11:00:00.000000Z",
      "updated_at": "2026-09-07T11:08:00.000000Z"
    }
  ]
}
```

---

## 📋 Summary Table for Developers

| Feature | Target | Method | Endpoint | Auth Required | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Fetch Settings** | Mobile | `GET` | `/api/v1/settings` | ❌ No | Returns boolean key-value pairs for UI toggles |
| **List Settings** | Admin | `GET` | `/api/v1/admin/settings` | ✅ Yes | Returns raw setting records for admin dashboard |
| **Update Settings** | Admin | `POST` | `/api/v1/admin/settings` | ✅ Yes | Updates setting key values (e.g. `show_payment_gateway_mobile`) |
