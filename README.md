# Gpro RL Mobile

Flutter application for Android and iOS with role-based interfaces. Customers see only HAPE/MBYLL. Business administrators also receive customer CRUD/status management and business-specific endpoint settings. It includes secure Sanctum token storage and automatic session restoration.

## Configure and run

The Laravel API base URL is provided at build time, while action URLs are always loaded from `/api/app/settings`:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com/api
```

For the Android emulator, the default is `http://10.0.2.2:8000/api`. For the iOS simulator use `--dart-define=API_BASE_URL=http://127.0.0.1:8000/api`. Real devices need a reachable HTTPS address. Production builds should always use HTTPS.

```bash
flutter test
flutter analyze
flutter build apk --dart-define=API_BASE_URL=https://api.example.com/api
flutter build ios --dart-define=API_BASE_URL=https://api.example.com/api
```

iOS builds require macOS and Xcode. Never put external-system credentials or customer passwords into Dart defines or source files.

## Logo and application icon

Replace `assets/branding/logo.png` with a square 1024×1024 PNG, then regenerate Android/iOS launcher icons:

```bash
dart run flutter_launcher_icons
```

The same file is also displayed on the login and splash screens.
