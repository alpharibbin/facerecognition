# Firebase Setup Guide

Complete guide for setting up Firebase for the Face Recognition app.

## Table of Contents

1. [Firebase Project Setup](#firebase-project-setup)
2. [FlutterFire Configuration](#flutterfire-configuration)
3. [Firestore Setup](#firestore-setup)
4. [Security Rules](#security-rules)
5. [Troubleshooting](#troubleshooting)

## Firebase Project Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `face-recognition-open-source`
4. Click **"Continue"**
5. (Optional) Enable Google Analytics
6. Click **"Create project"**
7. Wait for project creation (30-60 seconds)
8. Click **"Continue"**

### 2. Install Firebase CLI

```bash
npm install -g firebase-tools
```

Verify installation:
```bash
firebase --version
```

### 3. Login to Firebase

```bash
firebase login
```

This will:
- Open browser for authentication
- Ask about Gemini features (optional)
- Ask about usage reporting (optional)
- Complete login

Verify login:
```bash
firebase projects:list
```

## FlutterFire Configuration

### 1. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Verify installation:
```bash
flutterfire --version
```

### 2. Configure Firebase for Flutter

Run the configuration command:

```bash
flutterfire configure --project=face-recognition-open-source
```

**Interactive Setup**:
1. Select platforms (use arrow keys and space):
   - ✅ Android
   - ✅ iOS (if on macOS)
   - ✅ Web (optional)
   - ✅ Windows (optional)
   - ✅ macOS (optional)

2. The CLI will:
   - Register apps with Firebase
   - Generate `lib/firebase_options.dart`
   - Configure platform files

### 3. Verify Configuration

Check that `lib/firebase_options.dart` exists and contains:
- Web configuration
- Android configuration
- iOS configuration (if configured)
- Other platform configs

### 4. Platform-Specific Files

#### Android

File: `android/app/google-services.json`

Should be automatically added. If missing:
1. Go to Firebase Console → Project Settings
2. Select Android app
3. Download `google-services.json`
4. Place in `android/app/`

#### iOS (macOS only)

File: `ios/Runner/GoogleService-Info.plist`

Should be automatically added. If missing:
1. Go to Firebase Console → Project Settings
2. Select iOS app
3. Download `GoogleService-Info.plist`
4. Add to Xcode project

## Firestore Setup

### 1. Create Firestore Database

1. Go to Firebase Console
2. Click **"Firestore Database"** in left menu
3. Click **"Create database"**
4. Choose mode:
   - **Test mode** (for development)
   - **Production mode** (for production)
5. Select location (closest to users)
6. Click **"Enable"**

### 2. Database Structure

The app uses the following structure:

```
users/
  {email}/  # Document ID is email address
    {
      name: string,
      embedding: array<number>,  # 512-dimensional vector
      face_updated_at: timestamp
    }
```

**Example Document**:
```
users/
  user@example.com/
    name: "John Doe"
    embedding: [0.123, -0.456, ..., 0.789]  # 512 numbers
    face_updated_at: Timestamp(2024, 1, 15, 10, 30, 0)
```

### 3. Indexes

No composite indexes required for current queries.

If you add queries with multiple where clauses, create indexes:
1. Go to Firestore → Indexes
2. Click "Create Index"
3. Follow the prompts

## Security Rules

### Development Rules (Test Mode)

For development, test mode allows all reads/writes:

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

### Production Rules

For production, implement proper security:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{email} {
      // Allow read for all authenticated users
      allow read: if request.auth != null;
      
      // Allow write only if:
      // 1. User is authenticated
      // 2. Document ID matches user's email
      allow write: if request.auth != null 
                   && request.auth.token.email == email;
    }
  }
}
```

### Update Rules

1. Go to Firestore → Rules
2. Edit rules
3. Click **"Publish"**

## Firebase Console Features

### Monitoring

1. **Usage**: Monitor read/write operations
2. **Performance**: Track query performance
3. **Errors**: View error logs

### Data Management

1. **Data**: View/edit documents manually
2. **Indexes**: Manage composite indexes
3. **Backup**: Schedule automatic backups

## Troubleshooting

### Common Issues

#### 1. Configuration File Missing

**Error**: `firebase_options.dart not found`

**Solution**:
```bash
flutterfire configure --project=face-recognition-open-source
```

#### 2. Google Services Missing (Android)

**Error**: `google-services.json not found`

**Solution**:
1. Check `android/app/google-services.json` exists
2. If missing, download from Firebase Console
3. Rebuild: `flutter clean && flutter pub get`

#### 3. Permission Denied

**Error**: `PERMISSION_DENIED: Missing or insufficient permissions`

**Solution**:
1. Check Firestore security rules
2. For development, use test mode
3. For production, implement proper authentication

#### 4. Network Error

**Error**: `UNAVAILABLE: The service is currently unavailable`

**Solution**:
1. Check internet connection
2. Verify Firebase project is active
3. Check Firestore is enabled
4. Try again after a few minutes

#### 5. Invalid Document Path

**Error**: `INVALID_ARGUMENT: Invalid document reference`

**Solution**:
- Ensure email is valid format
- Check document ID doesn't contain invalid characters
- Verify collection name is "users"

### Verification Steps

1. **Check Firebase Connection**:
   ```dart
   // In your app, verify Firebase is initialized
   FirebaseFirestore.instance
       .collection('users')
       .limit(1)
       .get()
       .then((snapshot) {
         print('Firebase connected: ${snapshot.docs.length}');
       });
   ```

2. **Check Firestore Rules**:
   - Go to Firestore → Rules
   - Verify rules allow your operations

3. **Check App Registration**:
   - Go to Project Settings
   - Verify your app is listed
   - Check package name matches

## Best Practices

### 1. Security

- Never commit `google-services.json` with sensitive data
- Use environment variables for API keys (if needed)
- Implement proper authentication
- Use security rules in production

### 2. Performance

- Use indexes for complex queries
- Limit document reads
- Use pagination for large datasets
- Cache data locally (Hive)

### 3. Data Management

- Use document IDs efficiently (email as ID)
- Avoid storing large arrays (embeddings are acceptable)
- Use timestamps for tracking updates
- Implement data cleanup for old records

### 4. Cost Optimization

- Monitor usage in Firebase Console
- Use local caching (Hive) to reduce reads
- Implement offline-first approach
- Set up billing alerts

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)

---

Firebase setup complete! Your app is now connected to the cloud. ☁️

