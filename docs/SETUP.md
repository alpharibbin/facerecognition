# Setup Guide

This guide will walk you through setting up the Face Recognition app from scratch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Flutter Installation](#flutter-installation)
3. [Project Setup](#project-setup)
4. [Firebase Configuration](#firebase-configuration)
5. [Model Files](#model-files)
6. [Running the App](#running-the-app)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

Before you begin, ensure you have:

- **Flutter SDK** (3.10.0 or higher)
  - Check installation: `flutter --version`
  - Install from: https://docs.flutter.dev/get-started/install

- **Android Studio** (for Android development)
  - Download from: https://developer.android.com/studio
  - Install Android SDK and required tools

- **Xcode** (for iOS development - macOS only)
  - Available on Mac App Store
  - Install Command Line Tools: `xcode-select --install`

- **VS Code** or **Android Studio** (recommended IDEs)
  - VS Code: https://code.visualstudio.com/
  - Install Flutter and Dart extensions

- **Firebase Account**
  - Create account at: https://firebase.google.com/

## Flutter Installation

### Windows

1. Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows
2. Extract to a location (e.g., `C:\src\flutter`)
3. Add Flutter to PATH:
   - Search for "Environment Variables" in Windows
   - Add `C:\src\flutter\bin` to Path variable
4. Verify installation:
   ```bash
   flutter doctor
   ```

### macOS

1. Download Flutter SDK from https://docs.flutter.dev/get-started/install/macos
2. Extract to a location (e.g., `~/development/flutter`)
3. Add to PATH in `~/.zshrc` or `~/.bash_profile`:
   ```bash
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```
4. Run `source ~/.zshrc` or `source ~/.bash_profile`
5. Verify: `flutter doctor`

### Linux

1. Download Flutter SDK from https://docs.flutter.dev/get-started/install/linux
2. Extract to a location (e.g., `~/development/flutter`)
3. Add to PATH in `~/.bashrc`:
   ```bash
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```
4. Run `source ~/.bashrc`
5. Verify: `flutter doctor`

## Project Setup

### 1. Clone or Create Project

If starting fresh:
```bash
flutter create --org com.incoss facerecognition
cd facerecognition
```

If using existing repository:
```bash
git clone https://github.com/alpharibbin/facerecognition.git
cd facerecognition
```

### 2. Install Dependencies

```bash
flutter pub get
```

This will install all packages listed in `pubspec.yaml`.

### 3. Verify Setup

Run Flutter doctor to check for issues:
```bash
flutter doctor -v
```

Fix any issues reported (missing licenses, Android SDK, etc.).

## Firebase Configuration

### 1. Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Enter project name: `face-recognition-open-source`
4. Follow the setup wizard
5. Enable Google Analytics (optional)

### 2. Install Firebase CLI

```bash
npm install -g firebase-tools
```

### 3. Login to Firebase

```bash
firebase login
```

Follow the authentication flow in your browser.

### 4. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 5. Configure Firebase for Flutter

```bash
flutterfire configure --project=face-recognition-open-source
```

Select platforms:
- Android
- iOS (if on macOS)
- Web (optional)
- Windows (optional)
- macOS (optional)

This will:
- Register your apps with Firebase
- Generate `lib/firebase_options.dart`
- Configure platform-specific files

### 6. Setup Firestore Database

1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Start in **test mode** (for development)
4. Choose a location (closest to your users)
5. Click "Enable"

### 7. Configure Firestore Rules

For production, update Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{email} {
      allow read, write: if true; // Update with proper authentication
    }
  }
}
```

**Note**: Update rules for production with proper authentication.

### 8. Android Configuration

The `google-services.json` file should be automatically added to:
```
android/app/google-services.json
```

Verify it exists.

### 9. iOS Configuration (macOS only)

The `GoogleService-Info.plist` should be automatically added to:
```
ios/Runner/GoogleService-Info.plist
```

Add it to Xcode project if not automatically added.

## Model Files

### 1. Download FaceNet Model

You need the `facenet.tflite` model file. This is typically:
- A TensorFlow Lite model trained for face recognition
- Size: ~20-30 MB
- Input: 160x160 RGB image
- Output: 512-dimensional embedding vector

### 2. Place Model File

Create the assets directory structure:
```bash
mkdir -p assets/models
```

Place `facenet.tflite` in:
```
assets/models/facenet.tflite
```

### 3. Verify Asset Configuration

Check `pubspec.yaml` includes:
```yaml
flutter:
  assets:
    - assets/models/facenet.tflite
```

## Running the App

### Android

1. Connect Android device or start emulator
2. Enable USB debugging (if using physical device)
3. Run:
   ```bash
   flutter run
   ```

### iOS (macOS only)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select a simulator or connected device
3. Run from Xcode or:
   ```bash
   flutter run
   ```

### Web

```bash
flutter run -d chrome
```

## Troubleshooting

### Common Issues

#### 1. Flutter Doctor Issues

**Issue**: Missing Android licenses
```bash
flutter doctor --android-licenses
```

**Issue**: Missing Xcode command line tools (macOS)
```bash
xcode-select --install
```

#### 2. Firebase Configuration Errors

**Issue**: `firebase_options.dart` not found
- Run `flutterfire configure` again
- Ensure you're logged in: `firebase login`

**Issue**: Google Services not found
- Verify `google-services.json` exists in `android/app/`
- Rebuild: `flutter clean && flutter pub get`

#### 3. Model Loading Errors

**Issue**: Model file not found
- Verify `facenet.tflite` exists in `assets/models/`
- Check `pubspec.yaml` includes the asset
- Run `flutter clean && flutter pub get`

#### 4. Camera Permission Issues

**Android**: Add to `AndroidManifest.xml` (already included):
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS**: Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for face recognition</string>
```

#### 5. Build Errors

**Issue**: Gradle sync failed
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Issue**: Pod install failed (iOS)
```bash
cd ios
pod deintegrate
pod install
cd ..
```

### Getting Help

- Check Flutter documentation: https://docs.flutter.dev/
- Firebase documentation: https://firebase.google.com/docs
- TensorFlow Lite: https://www.tensorflow.org/lite

## Next Steps

After setup is complete:
1. Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand the project structure
2. Review [FEATURES.md](FEATURES.md) to learn about app features
3. Check [API.md](API.md) for service documentation

---

**Setup complete!** You're ready to start developing. 🚀

