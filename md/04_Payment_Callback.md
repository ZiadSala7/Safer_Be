# Step 4 — Payment Callback & Finalizing the Booking

## What this step does
After the user finishes paying on the MyFatoorah gateway, they get redirected back to whichever `callback_url` you supplied in Step 3 (e.g. `https://frontend.saferbe.com/payment/success?paymentId=123456789`).

### Optional verification endpoint
`GET /api/v1/hotels/checkout/callback?paymentId=123456789`

In practice, the backend also listens for a MyFatoorah webhook in the background to confirm the booking directly with Juniper or TBO — so the frontend hitting this endpoint is a nice-to-have for rendering the right UI, not the only source of truth.

### Booking status lookup
Use the `booking_reference` you stored from Step 3 to check the actual booking status at any time:

`GET /api/v1/hotels/booking/SAFER-1786652184-9123`

## Best practice
Render the "success" UI only after confirming status (via the callback endpoint or the booking details endpoint) — don't assume success purely because the user landed back on `callback_url`, since a user could land there without payment actually succeeding.
