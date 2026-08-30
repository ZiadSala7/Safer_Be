# Frontend Hotel Booking Integration — Overview

This is the entry point for the full TBO & Juniper hotel booking integration guide, split into focused files so each step can be worked on (or shared with a teammate) independently.

## Files in this set

| File | Covers |
|---|---|
| `01_Search_Hotels.md` | Step 1 — Aggregated hotel search (TBO + Juniper) |
| `02_Fetch_Rooms.md` | Step 2 — Fetching room availability for a chosen hotel |
| `03_Checkout_Initiate.md` | Step 3 — Initiating checkout & getting the MyFatoorah payment URL |
| `04_Payment_Callback.md` | Step 4 — Payment callback & finalizing/checking the booking |
| `05_Key_Values_Reference.md` | Quick-reference table of the critical keys that must be carried between steps |

## The flow, in one sentence per step

1. **Search** → user searches a city → backend queries TBO + Juniper together → you get a list of hotels, each tagged with `supplier` and `rate_plan_code`.
2. **Rooms** → user clicks a hotel → you re-send `supplier` + `rate_plan_code` → you get back real room options with `room_id`, `room_code`, `total_price`.
3. **Checkout** → user picks a room and clicks "Book Now" → you send the room details back exactly as received → backend locks the price and returns a MyFatoorah `payment_url` → you redirect the user there.
4. **Callback** → user pays on MyFatoorah → gets redirected back to your `callback_url` → you (optionally) verify status via the booking details endpoint.

The reason this split matters: **Steps 1→2→3 pass data forward**. Whatever `supplier` and `rate_plan_code` you got in Step 1 must be echoed back in Step 2, and whatever `room_id`/`room_code`/`total_price` you got in Step 2 must be echoed back in Step 3. None of these values are something you generate yourself — they're always round-tripped from the previous response.
