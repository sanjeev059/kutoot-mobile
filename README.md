# Kutoot Mobile (Flutter)

Flutter app for Kutoot loyalty platform – Android & iOS.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.2+)
- Android Studio / Xcode for device testing

## Setup

**1. Install Flutter** (if not installed)
- Download: https://docs.flutter.dev/get-started/install/windows
- Add `flutter` to PATH

**2. Create project scaffolding** (run once – generates android/, ios/)
```bash
cd C:\Users\aDMIN\Desktop\kutoot-mobile
flutter create .
```

**3. Install dependencies**
```bash
flutter pub get
```

**4. Run**
```bash
flutter run
# Or: flutter run -d chrome  (for web)
```

## API Configuration

Default API URL: `https://dev.kutoot.com/api/v1`

To override:
```bash
flutter run --dart-define=KUTOOT_API_URL=https://your-api.com/api/v1
```

## Project Structure

```
lib/
├── api/           # Kutoot API client
├── config/        # Environment config
├── providers/     # State (AuthProvider)
├── screens/       # UI screens
│   ├── auth/      # Login, OTP
│   ├── home/      # Home with bottom nav
│   ├── campaigns/ # Campaign list
│   └── profile/   # User profile
├── theme/         # App theme (orange, white)
└── main.dart
```

## Screen Mapping

See [SCREEN_MAPPING.md](SCREEN_MAPPING.md) for Figma → Backend mapping.

## Current Features

- ✅ Splash, Login (OTP), Profile
- ✅ Home with bottom nav
- ✅ Campaigns list
- 🔲 Coupons, Stamps, Subscriptions (TODO)
- 🔲 Razorpay, QR scan (TODO)
