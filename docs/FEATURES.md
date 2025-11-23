# Features Documentation

This document provides detailed information about all features in the Face Recognition app.

## Table of Contents

1. [Home Page](#home-page)
2. [Face Registration](#face-registration)
3. [Face Detection](#face-detection)
4. [View All Registered](#view-all-registered)
5. [Offline Support](#offline-support)
6. [Search Functionality](#search-functionality)

## Home Page

The main entry point of the application.

### Features

- **Two Main Actions**:
  - **View All**: Navigate to list of all registered faces
  - **Detect Face**: Start real-time face detection

### User Flow

```
Home Page
    ├── View All → ViewAllRegisteredPage
    └── Detect Face → DetectionPage
```

### Implementation

Located in `lib/main.dart` - `MyHomePage` widget.

## Face Registration

Complete workflow for registering a new face.

### Step 1: Email Verification

**Page**: `VerificationPage`

**Features**:
- Email input field
- Real-time email validation
- Check if email exists in Firestore `users` collection
- Name input field (populated if user exists)
- Visual feedback:
  - 🔴 Red: Email not verified
  - 🟢 Green: Email verified
  - ⏳ Gray: Checking

**Validation**:
- Email format validation
- Check against Firestore `users` collection
- Document ID is the email address

**Actions**:
- **Verify Button**: Check email in Firestore
- **Continue/Edit Button**: 
  - If new user: Create document in `users` collection
  - Navigate to registration page

### Step 2: Face Capture

**Page**: `RegistrationPage`

**Features**:
- Camera preview with guide overlay
- Green grid overlay for face positioning
- Centered face box guide
- Camera swap (front/back)
- Email display in app bar (read-only)

**Capture Process**:
1. User positions face in guide
2. Click "Capture & Register"
3. System captures 3 images automatically
4. 150ms delay between captures
5. Each image:
   - Detects face using ML Kit
   - Crops face region
   - Generates embedding using FaceNet
6. Averages the 3 embeddings
7. Saves to Firestore and Hive

**Error Handling**:
- No face detected: Shows error message
- Invalid email: Validation error
- Network error: Retry option

**Success**:
- Shows success snackbar
- Returns to previous page
- Updates registered faces list

## Face Detection

Real-time face detection and recognition.

**Page**: `DetectionPage`

### Features

- **Real-time Detection**:
  - Automatic detection every 1.5 seconds
  - Processes camera frames continuously
  - Detects multiple faces simultaneously

- **Visual Feedback**:
  - Bounding boxes around detected faces
  - Color-coded confidence:
    - 🟢 Green: ≥90% confidence
    - 🟠 Orange: 80-89% confidence
    - 🔴 Red: 70-79% confidence
    - ⚪ Gray: <70% confidence
  - Name label above each face
  - Confidence percentage display

- **Camera Controls**:
  - Swap camera (front/back)
  - Camera preference saved in SharedPreferences

### Detection Process

```
Camera Frame
    ↓
ML Kit Face Detection
    ↓
For each detected face:
    ├── Crop face region
    ├── Generate embedding
    ├── Compare with stored embeddings
    ├── Find best match (cosine similarity)
    └── Display result if above threshold (0.7)
```

### Matching Algorithm

- **Cosine Similarity**: Measures angle between embedding vectors
- **Threshold**: 0.7 (70% similarity required)
- **Best Match**: Highest similarity score above threshold
- **Unknown**: No match above threshold

### Performance

- Detection interval: 1.5 seconds
- Resolution: Medium (balanced speed/accuracy)
- Multi-face support: Yes
- Offline capable: Yes (uses local Hive storage)

## View All Registered

Browse and manage all registered faces.

**Page**: `ViewAllRegisteredPage`

### Features

- **Face List**:
  - Displays all registered faces
  - Shows name and email
  - Empty state with helpful message
  - Loading indicator during fetch

- **Search**:
  - Search by name or email
  - Real-time filtering
  - Case-insensitive
  - Toggle search bar

- **Actions**:
  - **Sync**: Manually sync with Firestore
  - **Refresh**: Reload from Firestore
  - **Double-tap**: Show action sheet
    - View Details
    - Register Again
    - Delete (with confirmation)
  - **Replay Icon**: Quick re-register

- **Navigation**:
  - Floating action button (+): Add new registration
  - Navigates to VerificationPage

### Face Details

Shows dialog with:
- Email address
- Name
- Other user information (if available)

### Delete Face

- **Access**: Double-tap a face → Select "Delete"
- **Confirmation**: Shows confirmation dialog before deletion
- **Deletion**: 
  - Removes from Firestore database
  - Removes from local Hive storage
  - Updates the list automatically
- **Safety**: Cannot be undone, requires explicit confirmation

### Sync Functionality

- **Automatic**: On page load
- **Manual**: Sync button in app bar
- **Real-time**: Listens to Firestore changes
- **Offline**: Works with cached data

## Offline Support

The app works offline using local storage.

### Storage

- **Hive Database**: Local NoSQL database
- **Box Name**: `face_embeddings_box`
- **Storage Location**: App documents directory

### Sync Strategy

1. **On App Start**:
   - Initialize DetectionService
   - Sync embeddings from Firestore
   - Store in Hive

2. **Real-time Updates**:
   - Listen to Firestore changes
   - Update Hive automatically
   - Remove deleted embeddings

3. **Offline Mode**:
   - Detection uses Hive data
   - No network required
   - Works seamlessly

### Data Structure

```
Hive Box: face_embeddings_box
  Key: {name or email}
  Value: FaceEmbedding {
    email: string
    embedding: List<double>
  }
```

## Search Functionality

### Implementation

- **Location**: ViewAllRegisteredPage
- **Trigger**: Search icon in app bar
- **Scope**: Name and email fields
- **Algorithm**: Case-insensitive substring match

### Usage

1. Click search icon
2. Type search query
3. Results filter in real-time
4. Click close to exit search

### Search Logic

```dart
filtered = registeredFaces.where((item) {
  final email = item['email'].toLowerCase();
  final name = item['name'].toLowerCase();
  final query = searchQuery.toLowerCase();
  return email.contains(query) || name.contains(query);
}).toList();
```

## Additional Features

### Camera Management

- **Preference Storage**: SharedPreferences
- **Default**: Back camera
- **Swap**: Toggle between front/back
- **State Persistence**: Remembers last used camera

### Error Handling

- **Network Errors**: Graceful degradation
- **Camera Errors**: User-friendly messages
- **Model Loading**: Progress indication
- **Validation**: Real-time feedback

### User Experience

- **Loading States**: Clear indicators
- **Empty States**: Helpful messages
- **Success Feedback**: Snackbars
- **Error Feedback**: Red snackbars with messages

## Feature Roadmap

### Planned Features

1. **Face Groups**: Organize faces into categories
2. **Batch Registration**: Register multiple faces
3. **Face Updates**: Update existing registrations
4. **Export/Import**: Backup and restore data
5. **Statistics**: Recognition accuracy metrics
6. **Settings**: Customize thresholds and intervals

### Future Enhancements

- Face quality scoring
- Age/gender detection
- Emotion recognition
- Face clustering
- Duplicate detection

---

All features are designed with user experience and performance in mind, ensuring smooth operation even on lower-end devices.

