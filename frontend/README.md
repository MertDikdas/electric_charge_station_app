# frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Google Maps API Key Setup (do not commit keys)

This app expects a Google Maps API key but it is intentionally **not** stored in the repo.

### Android

- Add this line to `android/local.properties` (this file is ignored by git):

	`MAPS_API_KEY=YOUR_ANDROID_MAPS_API_KEY`

### iOS

- Create `ios/Flutter/Secrets.xcconfig` (ignored by git). You can copy from `ios/Flutter/Secrets.xcconfig.example`.
- Set:

	`MAPS_API_KEY=YOUR_IOS_MAPS_API_KEY`

### Web

- Create `web/config.js` (ignored by git). You can copy from `web/config.example.js`.
- Set:

	`window.GOOGLE_MAPS_API_KEY = "YOUR_WEB_MAPS_API_KEY";`
