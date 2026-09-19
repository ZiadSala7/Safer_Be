# Traveling Safer API V1 - Bookings Endpoints

Based on the provided Postman collection, here is the documentation for all endpoints related to retrieving and managing bookings. 

## ✈️ Flight Bookings

### 1. Flight Booking Details (Owner)
* **Method:** `GET`
* **URL:** `/api/v1/flights/booking/{{booking_reference}}`
* **Auth:** Bearer `{{customer_token}}`
* **Description:** Secured endpoint to retrieve flight booking details for the booking owner.

### 2. Flight Booking Details (Guest Challenge)
* **Method:** `GET`
* **URL:** `/api/v1/flights/booking/{{booking_reference}}?email={{customer_email}}&last_name=Smith`
* **Auth:** Public
* **Description:** Guest booking lookup. Requires the customer's email and last name for verification. Invalid or missing parameters return 401/404.

### 3. Release Flight PNR (Owner)
* **Method:** `POST`
* **URL:** `/api/v1/flights/booking/{{booking_reference}}/release`
* **Auth:** Bearer `{{customer_token}}`
* **Description:** Allows the booking owner to release their own eligible PNR.

### 4. Request Flight Refund (Owner)
* **Method:** `POST`
* **URL:** `/api/v1/flights/booking/{{booking_reference}}/refund`
* **Auth:** Bearer `{{customer_token}}`
* **Body:**
  ```json
  {
      "amount": 490,
      "reason": "Customer request"
  }
  ```
* **Description:** Customer owner or admin/staff request to create an auditable refund record and execute the supplier refund.

### 5. Download Flight Invoice PDF (Owner)
* **Method:** `GET`
* **URL:** `/api/v1/flights/booking/{{booking_reference}}/invoice`
* **Auth:** Bearer `{{customer_token}}`
* **Description:** Downloads the flight invoice in PDF format.

### 6. Download Flight Ticket PDF (Owner)
* **Method:** `GET`
* **URL:** `/api/v1/flights/booking/{{booking_reference}}/ticket`
* **Auth:** Bearer `{{customer_token}}`
* **Description:** Retrieves the PDF ticket for the flight once ticketed.

---

## 🏨 Hotel Bookings

### 1. Hotel Booking Details (Owner)
* **Method:** `GET`
* **URL:** `/api/v1/hotels/booking/{{booking_reference}}`
* **Auth:** Bearer `{{customer_token}}`
* **Description:** Secured endpoint to retrieve hotel booking details for the owner. Returns a sanitized `CustomerHotelBookingResource`.

### 2. Hotel Booking Details (Guest Challenge)
* **Method:** `GET`
* **URL:** `/api/v1/hotels/booking/{{booking_reference}}?email={{customer_email}}&last_name=Smith`
* **Auth:** Public
* **Description:** Guest hotel booking lookup using the same verification logic as flights.

### 3. Request Hotel Cancellation (Owner)
* **Method:** `POST`
* **URL:** `/api/v1/hotels/booking/{{booking_reference}}/cancel`
* **Auth:** Bearer `{{customer_token}}`
* **Body:**
  ```json
  {
      "reason": "Customer cancellation"
  }
  ```
* **Description:** Creates an auditable refund/cancellation request, executes the supplier cancellation, and updates the payment state.

---

## 🛠️ Admin Booking Endpoints

### 1. Get Customer Bookings
* **Method:** `GET`
* **URL:** `/api/v1/admin/customers/{{customer_id}}/bookings`
* **Auth:** Bearer `{{admin_token}}`
* **Permission Required:** `customer.view`
* **Description:** Admin operation to retrieve all bookings associated with a specific customer ID.
