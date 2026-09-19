# Mobile app configuration

Local verification: **LOCAL VERIFIED** for backend APIs in this repo. Android/iOS app records: **MOBILE CONFIG REQUIRED**. Staging FCM: **STAGING PENDING**.

Step-by-step FCM integration (Android/iOS samples): [`PUSH_NOTIFICATIONS_INTEGRATION.md`](./PUSH_NOTIFICATIONS_INTEGRATION.md).

This document lists **backend-known** mobile requirements. Android package
names, iOS bundle IDs, APNs keys, and Firebase *app* records are **not**
stored in this repository.

```text
REQUIRES MOBILE CONFIG
```

for any value that must come from the mobile/Firebase console.

## Consent vs token (both platforms)

| Concept | Backend field / API | Meaning |
| --- | --- | --- |
| Business permission | `users.push_notification_consent` via `POST /api/v1/auth/push-notification-consent` | Default `false`. Required before the backend will enqueue push. |
| Delivery endpoint | `device_tokens` via `POST /api/v1/customer/devices` | FCM registration token only. Not consent. |

Verified client sequence:

```text
Accept Notifications
  → POST /auth/push-notification-consent { "push_notification_consent": true }
  → obtain FCM token
  → POST /customer/devices { token, platform: android|ios, ... }

Disable Notifications
  → POST /auth/push-notification-consent { "push_notification_consent": false }

Logout
  → DELETE /customer/devices/{id} for the current device
  → revoke Sanctum session
```

Disabling consent does not delete stored tokens. Unregistering a device does
not change consent.

## Android

| Item | Status |
| --- | --- |
| Firebase project | Server uses `FIREBASE_PROJECT_ID` when `FIREBASE_ENABLED=true`. The Android app must use the **same** Firebase project. |
| Firebase Android app | **REQUIRES MOBILE CONFIG** |
| Application ID / package | **REQUIRES MOBILE CONFIG** — not in this repo |
| `google-services.json` | Lives in the Android app. Gitignored here; never commit to the backend. |
| FCM | Client obtains a registration token; backend sends via FCM HTTP v1 |
| Notification permission | OS runtime permission is separate from `push_notification_consent` |
| Token registration | `POST /api/v1/customer/devices` with `platform=android` |
| Token refresh | Register again when FCM rotates the token |
| Unregister | `DELETE /api/v1/customer/devices/{id}` |
| Deep links | Backend `deep_link` is currently omitted. Offer payload includes `type=offer.activated` and `offer_id`. |
| Environment | Point the app at the API `APP_URL` + `/api/v1`. Do not embed Firebase **server** private keys in the app. |

## iOS

| Item | Status |
| --- | --- |
| Firebase iOS app | **REQUIRES MOBILE CONFIG** |
| Bundle identifier | **REQUIRES MOBILE CONFIG** — not in this repo |
| APNs key / certificates | **REQUIRES MOBILE CONFIG** (uploaded in Firebase console, not this API) |
| `GoogleService-Info.plist` | Lives in the iOS app. Gitignored here. |
| Firebase Messaging | Client obtains an FCM token (APNs is configured in Firebase, not in Laravel) |
| Notification permission | OS permission is separate from `push_notification_consent` |
| Token registration | `POST /api/v1/customer/devices` with `platform=ios` |
| Token refresh | Register again when the FCM token rotates |
| Unregister | `DELETE /api/v1/customer/devices/{id}` |
| Deep links | Same as Android — no backend URL scheme is defined |
| Environment | Same API base as Android for a given backend environment |

## Backend flags the app must not assume

Push is sent only when **all** of these are true:

1. `NOTIFICATIONS_ENABLED=true`
2. `NOTIFICATIONS_PUSH_ENABLED=true`
3. `users.push_notification_consent=true`
4. At least one `device_tokens` row for that user
5. For real FCM: `FIREBASE_ENABLED=true` plus service-account env vars

Local/tests often run with push/Firebase flags false (log-only). That is not
a production delivery proof.

## What this backend verified

- Device register / list / owner-scoped delete
- Consent independent of marketing and of tokens
- Offer activation queues fan-out only to consented users
- Invalid FCM tokens are deleted; temporary failures retry
- Full FCM tokens are not returned by the API

## What still requires the mobile team

- Android application ID
- iOS bundle ID
- Firebase Android/iOS app records
- APNs
- Notification permission UX
- Storing/refreshing FCM tokens on the device
- Handling `offer.activated` and transactional `data.type` values in the OS notification
