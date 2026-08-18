# Safer Be

A bilingual Saudi-first travel application prototype built with Flutter.

## Included

- Arabic (default) and English with automatic RTL/LTR layout
- Light and dark themes
- Guest-ready account state
- Animated branded splash screen
- First-launch, bilingual onboarding with locally persisted completion
- Responsive Home, Trips, Offers, and Profile experiences
- Reusable text, password, button, section, search, and travel-card widgets
- Feature-first clean architecture using `data`, `domain`, and `presentation`

## Project structure

```text
lib/
  app/                  # Application state and root configuration
  core/                 # Theme, localization, constants, shared widgets
  features/
    home/
    onboarding/
    offers/
    profile/
    shell/
    splash/
    trips/
```

Authentication, airports, cities, flight search, and hotel search use the Safer Be
V1 API. Offers, transfers, and trip lists remain local because the supplied API
collection does not include public list endpoints for them.

The default API URL is `https://backend.saferbe.com/api/v1`. Override it per environment:

```bash
flutter run --dart-define=SAFER_BE_API_URL=https://example.com/api/v1
```

Mobile application identifier: `com.darkNode.saferBe`.

## Run

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
```
