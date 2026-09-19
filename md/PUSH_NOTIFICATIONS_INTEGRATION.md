# Push Notifications Integration Guide

**Audience:** Android and iOS engineers integrating Firebase Cloud Messaging (FCM) with Safer-Be.  
**Verification:** Device/consent HTTP APIs are **LOCAL VERIFIED**. Live FCM delivery is **STAGING PENDING**. Package names, bundle IDs, APNs, and Firebase *app* records are **REQUIRES MOBILE CONFIG** (not in this repo).

This guide is the mobile push narrative. Field-level API contracts stay in Phase 2 docs. Do **not** invent endpoints or embed Firebase **server** keys in the app.

| Concern | Canonical doc |
| --- | --- |
| Customer API (auth, devices, bookings) | [`MOBILE_DEVELOPER_GUIDE.md`](./MOBILE_DEVELOPER_GUIDE.md) |
| Backend-known mobile config | [`CONFIGURATION.md`](./CONFIGURATION.md) |
| Device tokens / consent / payload | [`../frontend/NOTIFICATIONS.md`](../frontend/NOTIFICATIONS.md) |
| Endpoint inventory | [`../frontend/API_ENDPOINT_INDEX.md`](../frontend/API_ENDPOINT_INDEX.md) |
| Offers + `offer.activated` | [`../frontend/PROMOTIONS.md`](../frontend/PROMOTIONS.md) |

---

## Table of contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Android setup](#3-android-setup)
4. [iOS setup](#4-ios-setup)
5. [SDK installation](#5-sdk-installation)
6. [Device token flow](#6-device-token-flow)
7. [Backend API](#7-backend-api)
8. [Push consent](#8-push-consent)
9. [Notification payload](#9-notification-payload)
10. [Events covered](#10-events-covered)
11. [Deep link handling](#11-deep-link-handling)
12. [Consent UX](#12-consent-ux)
13. [Logout](#13-logout)
14. [Testing guide](#14-testing-guide)
15. [Troubleshooting](#15-troubleshooting)
16. [Code samples](#16-code-samples)
17. [Backend reference](#17-backend-reference)
18. [Checklist](#18-checklist)

---

## 1. Overview

Safer-Be sends **transactional** and **offer** push from the **backend** through FCM HTTP v1. The customer app:

1. Asks for OS notification permission (Android 13+, iOS).
2. Records business consent on the API (`push_notification_consent`, default **`false`**).
3. Obtains an FCM registration token and registers it with Safer-Be.
4. Handles `notification` (display) and `data` (routing) when a message arrives.

**Do not** send FCM from the client for booking or offer business events. The backend owns those.

```text
marketing_consent          → marketing email only
push_notification_consent  → backend may enqueue push (default false)
device_tokens              → FCM delivery endpoints (not consent)
```

These three are **independent**. Registering a token does not opt the user in. Opting in does not register a token. Push jobs are **not** dispatched when consent is false, even if tokens exist.

**FCM role**

| Side | Responsibility |
| --- | --- |
| Mobile app | Firebase *app* config, OS permission, FCM token, display + routing |
| Safer-Be API | Consent flag, `device_tokens` rows, queue `FanOutConsentedPush` → `SendPushNotification` |
| Firebase project | Same project ID as server `FIREBASE_PROJECT_ID` when `FIREBASE_ENABLED=true` |

Live send also needs a queue worker and server service-account env vars. Tests use LogOnly (`FIREBASE_ENABLED=false`). That is **not** a production delivery proof.

---

## 2. Prerequisites

| Item | Status | Notes |
| --- | --- | --- |
| Firebase project | **REQUIRES MOBILE CONFIG** | Must match server `FIREBASE_PROJECT_ID` when FCM is on |
| Android app in Firebase Console | **REQUIRES MOBILE CONFIG** | Package / application ID not stored here |
| iOS app in Firebase Console | **REQUIRES MOBILE CONFIG** | Bundle ID not stored here |
| APNs key or certificates | **REQUIRES MOBILE CONFIG** | Upload in **Firebase Console**, not Laravel |
| `google-services.json` | Android app only | Gitignored in this backend. Never commit here |
| `GoogleService-Info.plist` | iOS app only | Gitignored in this backend |
| API base | `{APP_URL}/api/v1` | **REQUIRES MOBILE CONFIG** per environment |
| Customer Sanctum PAT | After login / email verify | See [`MOBILE_DEVELOPER_GUIDE.md`](./MOBILE_DEVELOPER_GUIDE.md) §2 |

**Do not** put Firebase **Admin / service-account** JSON or `FIREBASE_*` server secrets in the mobile app.

Placeholders (fill from Firebase Console / App Store Connect):

```text
ANDROID_APPLICATION_ID = <REQUIRES MOBILE CONFIG>
IOS_BUNDLE_ID          = <REQUIRES MOBILE CONFIG>
FIREBASE_PROJECT_ID    = <same as server when FIREBASE_ENABLED=true>
API_BASE_URL           = <APP_URL>/api/v1
```

---

## 3. Android setup

All console values: **REQUIRES MOBILE CONFIG**.

### Firebase Console

1. Open the Firebase project that the backend uses for FCM.
2. Add an **Android** app. Application ID / package: `<ANDROID_APPLICATION_ID>`.
3. Download `google-services.json` into the Android app module (not this repo).
4. Enable Cloud Messaging (FCM). No APNs step on Android.

### `google-services.json`

- Lives in the Android app (typically `app/`).
- Never commit it to `traveling-safer-be`.
- Do not confuse it with the **server** service account.

### Gradle (illustrative)

Apply the Google Services plugin in the app module and depend on Firebase Cloud Messaging. Exact versions: **REQUIRES MOBILE CONFIG** (use the Firebase BoM your team approves).

```kotlin
// project-level: plugin google-services
// app-level:
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:<BOM_VERSION>"))
    implementation("com.google.firebase:firebase-messaging")
}
```

### OS permission

Android 13+ (`POST_NOTIFICATIONS`) is **in addition to** `POST /auth/push-notification-consent`. Request the OS permission first; then call the consent API; then register the FCM token.

---

## 4. iOS setup

All console values: **REQUIRES MOBILE CONFIG**.

### Firebase Console

1. Add an **iOS** app. Bundle ID: `<IOS_BUNDLE_ID>`.
2. Download `GoogleService-Info.plist` into the Xcode target (not this repo).

### APNs

1. Create an APNs Auth Key (recommended) or certificates in Apple Developer.
2. Upload the key/certs in Firebase Console → Project settings → Cloud Messaging.
3. Laravel does **not** store APNs keys. FCM talks to APNs.

### `GoogleService-Info.plist`

- Lives in the iOS app.
- Never commit it to this backend.

### Capabilities

Enable **Push Notifications** and **Background Modes → Remote notifications** in Xcode. Exact capability names: Apple’s current docs.

### OS permission

Request `UNUserNotificationCenter` authorization. That is **not** `push_notification_consent`. Call the Safer-Be consent API after the user opts in in-app.

---

## 5. SDK installation

| Platform | SDK | Token API |
| --- | --- | --- |
| Android | Firebase Cloud Messaging (BoM) | `FirebaseMessaging.getInstance().token` |
| iOS | Firebase Messaging (SPM / CocoaPods) | `Messaging.messaging().token` |

Use the **same** Firebase project as the server. After login (Sanctum), register the token with Safer-Be ([§7](#7-backend-api)).

No Safer-Be native SDK exists. Use HTTPS + Bearer PAT.

---

## 6. Device token flow

```text
Login (Sanctum)
  → User enables notifications (in-app + OS)
  → POST /api/v1/auth/push-notification-consent  { "push_notification_consent": true }
  → FirebaseMessaging token
  → POST /api/v1/customer/devices  { token, platform: android|ios, ... }

FCM token rotation
  → POST /api/v1/customer/devices again (upsert)

Disable in-app
  → POST /api/v1/auth/push-notification-consent  { "push_notification_consent": false }
  (tokens are kept; backend stops enqueueing)

Logout
  → DELETE /api/v1/customer/devices/{id}
  → POST /api/v1/auth/logout
```

| Rule | Behavior | Status |
| --- | --- | --- |
| Same FCM token | Upsert — no duplicate rows | **LOCAL VERIFIED** |
| Token belonged to another user | Reassigned to the current user | **LOCAL VERIFIED** |
| Full token in API responses | Never returned (`token_hint` only) | **LOCAL VERIFIED** |
| `platform=web` | `422` | **LOCAL VERIFIED** |

Persist the numeric `data.id` from register/list. Delete uses that id, **not** the FCM string.

---

## 7. Backend API

**LOCAL VERIFIED** · Sanctum on all four. Tests: `DeviceTokenApiTest`, `PushNotificationConsentTest`.

Base: `{API_BASE_URL}` = `{APP_URL}/api/v1`  
Headers: `Accept: application/json`, `Authorization: Bearer {customer_token}`.

### 7.1 Push consent

`POST /api/v1/auth/push-notification-consent`

```json
{ "push_notification_consent": true }
```

`push_notification_consent` is required boolean. Success includes `UserResource` (`push_notification_consent`, `push_notification_consent_at`).

`PATCH /api/v1/customer/notification-preferences` **does not exist**.

### 7.2 Register or update device

`POST /api/v1/customer/devices` · `201` created / `200` upsert · `RegisterDeviceTokenRequest`

| Field | Required | Validation |
| --- | --- | --- |
| `token` | yes | string, 8–512 |
| `platform` | yes | `android` \| `ios` |
| `device_id` | no | max 191 — stable hardware/install id |
| `app_version` | no | max 32 |

**Response `data`:** `id`, `platform`, `device_id`, `app_version`, `token_hint`, `last_used_at`, `created_at`.

### 7.3 List devices

`GET /api/v1/customer/devices` · own devices only · `{ "success": true, "data": [ ... ] }`

### 7.4 Unregister device

`DELETE /api/v1/customer/devices/{device}`  
`{device}` is numeric `id` (`whereNumber`). Other user’s id → **404**.

### Errors

| HTTP | When |
| --- | --- |
| 401 | Missing/invalid Sanctum |
| 404 | Delete of another user’s device id |
| 422 | Missing token, `platform` not `android`/`ios` |
| 5xx | Retry; surface `trace_id` if present |

No special device rate limiter is documented. Global `api` throttle applies ([`MOBILE_DEVELOPER_GUIDE.md`](./MOBILE_DEVELOPER_GUIDE.md) §12).

Register can succeed when the server is on LogOnly (**LOCAL VERIFIED**). That does **not** prove the phone received a message (**STAGING PENDING**).

---

## 8. Push consent

| | |
| --- | --- |
| Default | `false` |
| Endpoint | `POST /api/v1/auth/push-notification-consent` |
| Independent of | `marketing_consent`, FCM tokens |
| Effect | Jobs skipped when false |

Read initial state from `GET /api/v1/auth/user` → `user.push_notification_consent`.  
Treat the toggle as **off** until that field is true.

Marketing email is a **different** endpoint: `POST /api/v1/auth/marketing-consent`. Do not bind the two switches together.

---

## 9. Notification payload

FCM messages from Safer-Be use:

- **`notification`** — title/body display strings (system tray).
- **`data`** — **string-only** keys for routing. Do not expect JSON objects inside values.

| Key | Meaning |
| --- | --- |
| `type` | One of the six events in [§10](#10-events-covered) |
| `booking_reference` | Safer-Be reference (transactional types) |
| `product_type` | `flight` or `hotel` when known |
| `offer_id` | Numeric offer id as a **string** (`offer.activated`) |
| `offer_type` | `global` \| `destination` \| `airline` \| `route` |
| `deep_link` | Optional; **omitted** today until product defines a URL scheme |

Do not put payment credentials, PII dumps, or Firebase keys in `data`.

On Android, if both `notification` and `data` are present, a backgrounded app may deliver `data` via the system tray tap (`getIntent()` extras). Handle **cold start** and **warm start** the same way: read `type` first.

---

## 10. Events covered

Six `data.type` values are documented. **LOCAL VERIFIED** at listener/job layer for offer fan-out; transactional types are the same payload contract.

| `type` | Typical screen | Extra `data` |
| --- | --- | --- |
| `booking.request_confirmed` | Booking detail / status | `booking_reference`, `product_type` |
| `booking.confirmed` | Booking detail (PNR/confirmation may still be null until fulfillment) | same |
| `fulfillment.failed` | Booking status + support | same |
| `refund.completed` | Booking / refund status | same |
| `customer.approval_required` | Approval / status (`POST /customer/approvals/{id}/respond`) | same; poll status for `approval_id` |
| `offer.activated` | Public offers list or offer by id | `offer_id`, `offer_type` |

Offer fan-out: when an offer **becomes** `status=active`, backend dispatches `OfferActivated` → one `FanOutConsentedPush` → `SendPushNotification` per consented user. Re-activating an already-active offer does not re-fan-out. Opted-out users (including `marketing_consent=true`) are skipped. `POST /admin/offers/{id}/activate` HTTP is **NOT VERIFIED** — not a mobile concern.

Empty audience (zero consented users) is a no-op.

---

## 11. Deep link handling

| Topic | Current behavior |
| --- | --- |
| Backend URL scheme | **Not defined.** `deep_link` is omitted. |
| Routing | Use `data.type` + `booking_reference` / `offer_id`. |
| Cold vs warm start | **REQUIRES MOBILE CONFIG** — OS / Activity / `UNNotificationResponse`. |

**Recommended mapping** (UX, not a backend URL contract):

| `type` | Open |
| --- | --- |
| `booking.*` / `fulfillment.failed` / `refund.completed` | `GET /customer/bookings/{reference}/status` or product booking detail |
| `customer.approval_required` | Status screen → respond if `pending_approval` |
| `offer.activated` | `GET /offers/available` or in-app offer for `offer_id` |

If product later emits `deep_link`, prefer it when present; until then do not wait for it.

---

## 12. Consent UX

Full template: [`NOTIFICATIONS.md` UX](../frontend/NOTIFICATIONS.md#ux-guidance).

1. Toggle **off** until `UserResource.push_notification_consent` is true.
2. User turns on → OS permission → `POST` consent `true` → FCM token → `POST /devices`.
3. Disable the switch while consent or register is in flight.
4. User turns off → `POST` consent `false`. Do **not** delete tokens unless they also log out or ask to remove this device.
5. Empty device list after login is valid.
6. Touch target ≥ 44×44. Distinguish “push permission” vs “this device registered”.

Android 13+ OS deny: keep backend consent false; do not register a token you cannot use.

---

## 13. Logout

Verified sequence ([`CONFIGURATION.md`](./CONFIGURATION.md)):

```text
DELETE /api/v1/customer/devices/{id}   // numeric id for this install
POST /api/v1/auth/logout               // revoke current Sanctum PAT
```

Unregister so a shared/sold device stops receiving push. Unregister does **not** change `push_notification_consent`. Consent `false` does **not** delete tokens.

If delete returns `404`, the row is already gone or not owned — still logout.

---

## 14. Testing guide

| # | Step | Expect | Status |
| --- | --- | --- | --- |
| 1 | `GET /auth/user` after login | `push_notification_consent` false by default | **LOCAL VERIFIED** |
| 2 | `POST` consent `true` | UserResource true + timestamp | **LOCAL VERIFIED** |
| 3 | `POST /devices` `platform=android` or `ios` | `201`/`200`, `token_hint`, no raw token | **LOCAL VERIFIED** |
| 4 | `POST` same token again | Upsert, same `id` | **LOCAL VERIFIED** |
| 5 | `GET /devices` | Own rows only | **LOCAL VERIFIED** |
| 6 | `platform=web` | `422` | **LOCAL VERIFIED** |
| 7 | `DELETE` other user’s `id` | `404` | **LOCAL VERIFIED** |
| 8 | Consent `false` with tokens still stored | No push enqueue | **LOCAL VERIFIED** (jobs) |
| 9 | Activate a new offer (ops) | Fan-out only if consent true | **LOCAL VERIFIED** (jobs); FCM **STAGING PENDING** |
| 10 | Foreground / background / killed | Handle `data.type` on tap | **REQUIRES MOBILE CONFIG** |
| 11 | Token refresh callback | Re-`POST /devices` | **REQUIRES MOBILE CONFIG** |

Local API with `FIREBASE_ENABLED=false`: register still works; **no** real notification on the phone.

---

## 15. Troubleshooting

| Symptom | Check |
| --- | --- |
| 401 on devices/consent | Sanctum PAT expired — `POST /auth/refresh` or login |
| 422 on register | `platform` must be `android` or `ios`; `token` 8–512 chars |
| 404 on delete | Using FCM string instead of numeric `id`, or another user’s id |
| Consent on, no push | Server flags (`NOTIFICATIONS_*`, `FIREBASE_ENABLED`), queue worker, consent true, token row exists |
| Token registered, still no push | Consent still false; or LogOnly environment |
| iOS token never arrives | APNs key in Firebase Console; Push capability; physical device |
| Android 13 no banner | `POST_NOTIFICATIONS` denied |
| Offer push to opted-out user | Should not happen — report if it does |
| `deep_link` missing | Expected today — route on `type` |

Surface `trace_id` / `X-Trace-Id` to support on renderer errors.

---

## 16. Code samples

Illustrative only. Replace placeholders. Do **not** copy Firebase server keys into these files.

### Kotlin (Android)

```kotlin
// After login. Consent default is false — only call when the user opts in.
suspend fun enablePush(api: SaferBeApi, fcmToken: String) {
    api.updatePushConsent(pushNotificationConsent = true)
    api.registerDevice(
        token = fcmToken,
        platform = "android",
        deviceId = stableInstallId(), // optional, max 191
        appVersion = BuildConfig.VERSION_NAME,
    )
}

suspend fun disablePush(api: SaferBeApi) {
    api.updatePushConsent(pushNotificationConsent = false)
}

suspend fun logout(api: SaferBeApi, deviceRowId: Long) {
    runCatching { api.unregisterDevice(deviceRowId) }
    api.logout()
}

fun routeFromRemoteMessage(data: Map<String, String>) {
    when (data["type"]) {
        "offer.activated" -> openOffers(data["offer_id"])
        "customer.approval_required" -> openBookingStatus(data["booking_reference"])
        "booking.request_confirmed",
        "booking.confirmed",
        "fulfillment.failed",
        "refund.completed" -> openBookingStatus(data["booking_reference"])
        else -> openHome()
    }
}
```

```kotlin
// Retrofit-shaped paths — verified routes only
interface SaferBeApi {
    @POST("auth/push-notification-consent")
    suspend fun updatePushConsent(@Body body: PushConsentBody)

    @POST("customer/devices")
    suspend fun registerDevice(@Body body: DeviceBody)

    @GET("customer/devices")
    suspend fun listDevices(): DevicesEnvelope

    @DELETE("customer/devices/{id}")
    suspend fun unregisterDevice(@Path("id") id: Long)

    @POST("auth/logout")
    suspend fun logout()
}

data class PushConsentBody(val push_notification_consent: Boolean)
data class DeviceBody(
    val token: String,
    val platform: String,
    val device_id: String? = null,
    val app_version: String? = null,
)
```

On token refresh (`onNewToken`), `POST /customer/devices` again if the user is logged in and consent is true (or always upsert the token; enqueue still requires consent).

### Swift (iOS)

```swift
func enablePush(api: SaferBeAPI, fcmToken: String) async throws {
    try await api.updatePushConsent(true)
    try await api.registerDevice(
        token: fcmToken,
        platform: "ios",
        deviceId: UIDevice.current.identifierForVendor?.uuidString,
        appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    )
}

func disablePush(api: SaferBeAPI) async throws {
    try await api.updatePushConsent(false)
}

func logout(api: SaferBeAPI, deviceRowId: Int) async {
    try? await api.unregisterDevice(id: deviceRowId)
    try? await api.logout()
}

func route(from data: [String: String]) {
    switch data["type"] {
    case "offer.activated":
        openOffers(id: data["offer_id"])
    case "customer.approval_required":
        openBookingStatus(reference: data["booking_reference"])
    case "booking.request_confirmed",
         "booking.confirmed",
         "fulfillment.failed",
         "refund.completed":
        openBookingStatus(reference: data["booking_reference"])
    default:
        openHome()
    }
}
```

```swift
// Paths — verified routes only
// POST /api/v1/auth/push-notification-consent
// POST /api/v1/customer/devices
// GET  /api/v1/customer/devices
// DELETE /api/v1/customer/devices/{id}
// POST /api/v1/auth/logout
```

Messaging delegate `messaging(_:didReceiveRegistrationToken:)` → re-register when logged in.

---

## 17. Backend reference

| Method | Path | Auth | Status | Test |
| --- | --- | --- | --- | --- |
| POST | `/api/v1/auth/push-notification-consent` | sanctum | **LOCAL VERIFIED** | `PushNotificationConsentTest` |
| GET | `/api/v1/auth/user` | sanctum | **LOCAL VERIFIED** | `AuthTest` |
| POST | `/api/v1/customer/devices` | sanctum | **LOCAL VERIFIED** | `DeviceTokenApiTest` |
| GET | `/api/v1/customer/devices` | sanctum | **LOCAL VERIFIED** | `DeviceTokenApiTest` |
| DELETE | `/api/v1/customer/devices/{device}` | sanctum | **LOCAL VERIFIED** | `DeviceTokenApiTest` |
| POST | `/api/v1/auth/logout` | sanctum | **LOCAL VERIFIED** | `AuthTest` |
| GET | `/api/v1/customer/bookings/{reference}/status` | sanctum | **LOCAL VERIFIED** | fulfillment/status tests |
| POST | `/api/v1/customer/approvals/{id}/respond` | sanctum | **LOCAL VERIFIED** | `CustomerApprovalRespondTest` |
| GET | `/api/v1/offers/available` | none | **LOCAL VERIFIED** | `OffersApiContractTest` |

**Server flags** (ops, not mobile env): `NOTIFICATIONS_ENABLED`, `NOTIFICATIONS_PUSH_ENABLED`, `FIREBASE_ENABLED` + service-account vars. Invalid FCM tokens are deleted; temporary failures retry. Promotions does not call Firebase directly.

**NOT VERIFIED / do not call:** `PATCH /customer/notification-preferences` (does not exist); `POST /admin/offers/{id}/activate` as a mobile contract.

Controllers: `ProfileController@updatePushNotificationConsent`, `DeviceTokenController`.  
Jobs: `FanOutConsentedPush`, `SendPushNotification`.

---

## 18. Checklist

### Firebase / OS — **REQUIRES MOBILE CONFIG**

- [ ] Android app in the **same** Firebase project as the server
- [ ] iOS app + APNs key in Firebase Console
- [ ] `google-services.json` / `GoogleService-Info.plist` in the **app** repos only
- [ ] Android 13+ notification permission UX
- [ ] iOS notification permission UX
- [ ] Cold start + warm start handlers for `data.type`

### Safer-Be API — **LOCAL VERIFIED**

- [ ] Consent toggle bound only to `POST /auth/push-notification-consent`
- [ ] Default UI off until `UserResource` says otherwise
- [ ] `POST /customer/devices` with `android` or `ios`
- [ ] Persist numeric device `id` for logout delete
- [ ] Token refresh → register again
- [ ] Logout: `DELETE /devices/{id}` then `POST /auth/logout`
- [ ] Six `data.type` values routed ([§10](#10-events-covered))
- [ ] No `deep_link` required
- [ ] No Firebase server keys in the app
- [ ] Staging FCM delivery proven separately (**STAGING PENDING**)

---

## Verification legend

| Status | Meaning |
| --- | --- |
| **LOCAL VERIFIED** | HTTP or job tests in this repo |
| **STAGING PENDING** | Live FCM to a device |
| **REQUIRES MOBILE CONFIG** | Console / package / APNs / OS UX — not in this backend |
