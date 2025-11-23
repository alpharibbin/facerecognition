# Firebase Setup for Public Repository

This repository does **NOT** include Firebase configuration files for security reasons. You need to set up your own Firebase project.

## Quick Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name
4. Follow the setup wizard

### 2. Configure Firebase for Flutter

Run the FlutterFire CLI:

```bash
# Install FlutterFire CLI (if not already installed)
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure --project=YOUR_PROJECT_ID
```

This will:
- Generate `lib/firebase_options.dart` with your API keys
- Add `android/app/google-services.json` (Android)
- Add `ios/Runner/GoogleService-Info.plist` (iOS, if on macOS)

### 3. Verify Files

After running `flutterfire configure`, you should have:

- ✅ `lib/firebase_options.dart` (generated)
- ✅ `android/app/google-services.json` (Android)
- ✅ `ios/Runner/GoogleService-Info.plist` (iOS, if configured)

## Manual Setup (Alternative)

If you prefer manual setup:

### Android

1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`
3. Copy `lib/firebase_options.dart.example` to `lib/firebase_options.dart`
4. Replace placeholder values with your Firebase project values

### iOS (macOS only)

1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/GoogleService-Info.plist`
3. Add it to Xcode project

## Security Notes

⚠️ **IMPORTANT**: 
- Never commit `firebase_options.dart` with real API keys
- Never commit `google-services.json` with real keys
- Never commit `GoogleService-Info.plist` with real keys
- These files are already in `.gitignore`

## Firestore Setup

1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Start in **test mode** (for development)
4. Choose a location
5. Click "Enable"

### Firestore Rules

For development (test mode):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

For production, implement proper security rules (see [docs/FIREBASE.md](docs/FIREBASE.md)).

## Need Help?

See detailed instructions in [docs/FIREBASE.md](docs/FIREBASE.md).

