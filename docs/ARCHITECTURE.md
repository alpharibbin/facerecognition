# Architecture Documentation

This document explains the architecture and design decisions of the Face Recognition app.

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Data Flow](#data-flow)
4. [Component Structure](#component-structure)
5. [Design Patterns](#design-patterns)
6. [Data Models](#data-models)
7. [Services](#services)

## Overview

The Face Recognition app follows a layered architecture with clear separation of concerns:

- **Presentation Layer**: Flutter UI components (Pages)
- **Service Layer**: Business logic and external integrations
- **Data Layer**: Local storage (Hive) and cloud storage (Firestore)
- **Model Layer**: TensorFlow Lite for face embeddings

## System Architecture

```
┌────────────────────────────────────────────────────────┐
│                    Presentation Layer                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ DetectionPage│  │Registration  │  │ ViewAllPage  │  │
│  │              │  │   Page       │  │              │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
└─────────┼─────────────────┼─────────────────┼──────────┘
          │                 │                 │
┌─────────┼─────────────────┼─────────────────┼──────────┐
│         │                 │                 │          │
│  ┌──────▼──────┐   ┌──────▼───────┐  ┌──────▼───────┐  │
│  │Detection    │   │FaceEmbedder  │  │  Camera      │  │
│  │  Service    │   │  Service     │  │  Service     │  │
│  └──────┬──────┘   └───────┬──────┘  └──────────────┘  │
└─────────┼──────────────────┼───────────────────────────┘
          │                  │
┌─────────┼──────────────────┼──────────────────────┐
│         │                  │                      │
│  ┌──────▼──────┐   ┌───────▼────────┐             │
│  │    Hive     │   │  Firestore     │             │
│  │  (Local)    │   │   (Cloud)      │             │
│  └─────────────┘   └────────────────┘             │
│                                                   │
│  ┌─────────────────────────────────────────────┐  │
│  │      TensorFlow Lite (FaceNet Model)        │  │
│  └─────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────┘
```

## Data Flow

### Face Registration Flow

```
User Input (Email & Name)
    ↓
VerificationPage (Optional: Verify if email exists in users collection)
    ↓
Create/Update user document in users collection
    ↓
RegistrationPage (Capture 3 face images)
    ↓
FaceEmbedder (Generate embeddings from images)
    ↓
Average embeddings
    ↓
Firestore (Save to users/{email} with embedding)
    ↓
Hive (Save locally for offline access)
```

### Face Detection Flow

```
Camera Stream
    ↓
ML Kit Face Detection (Detect faces in frame)
    ↓
Crop detected faces
    ↓
FaceEmbedder (Generate embedding for detected face)
    ↓
DetectionService (Compare with stored embeddings)
    ↓
Cosine Similarity Calculation
    ↓
Display match result (if similarity > threshold)
```

### Sync Flow

```
App Start / Manual Sync
    ↓
DetectionService.init()
    ↓
Query Firestore (users with embeddings)
    ↓
Download embeddings
    ↓
Store in Hive (local storage)
    ↓
Listen for real-time updates
```

## Component Structure

### Pages (`lib/face/`)

#### DetectionPage
- **Purpose**: Real-time face detection and recognition
- **Features**:
  - Camera preview
  - Automatic face detection (every 1.5 seconds)
  - Face bounding boxes with labels
  - Confidence scores
- **Dependencies**: DetectionService, FaceEmbedder, Camera

#### RegistrationPage
- **Purpose**: Register new faces
- **Features**:
  - Camera preview with guide overlay
  - Capture 3 images
  - Face detection and cropping
  - Embedding generation
  - Save to Firestore and Hive
- **Dependencies**: FaceEmbedder, Camera, Firestore

#### VerificationPage
- **Purpose**: Enter email and name before registration (with optional verification)
- **Features**:
  - Email input field
  - Name input field (always enabled)
  - Optional verification to check if user exists in Firestore
  - Auto-populate name if user exists
  - Create or update user document
  - Navigate to registration page
- **Dependencies**: Firestore
- **Note**: Verification is optional - users can proceed directly to registration without clicking "Verify"

#### ViewAllRegisteredPage
- **Purpose**: Display all registered faces
- **Features**:
  - List all registered users
  - Search functionality
  - View details
  - Re-register option
  - Sync with Firestore
- **Dependencies**: DetectionService, Firestore

### Services (`lib/services/`)

#### DetectionService
- **Purpose**: Face matching and offline storage management
- **Responsibilities**:
  - Sync embeddings from Firestore to Hive
  - Real-time Firestore listener
  - Find best matching face using cosine similarity
  - Manage local Hive database
- **Key Methods**:
  - `init()`: Initialize service and sync
  - `syncFromFirestore()`: Download embeddings
  - `findBestMatch()`: Match face embedding
  - `_listenForChanges()`: Real-time updates

#### FaceEmbedder
- **Purpose**: TensorFlow Lite model management and embedding generation
- **Responsibilities**:
  - Load FaceNet model from assets
  - Preprocess images
  - Generate face embeddings
  - Normalize embeddings
- **Key Methods**:
  - `loadModel()`: Load TFLite model
  - `embedImage()`: Generate embedding from image
  - `_l2Normalize()`: Normalize embedding vector

### Models (`lib/models/`)

#### FaceEmbedding
- **Purpose**: Data model for face embeddings
- **Fields**:
  - `email`: String - User email
  - `embedding`: List<double> - Face embedding vector
- **Storage**: Hive box for local storage

## Design Patterns

### Singleton Pattern
- **FaceEmbedder**: Uses singleton pattern to ensure only one model instance
  ```dart
  static final FaceEmbedder _instance = FaceEmbedder._internal();
  factory FaceEmbedder() => _instance;
  ```

### Repository Pattern
- **DetectionService**: Acts as repository for face embeddings
  - Abstracts data source (Firestore/Hive)
  - Provides unified interface for data access

### Service Layer Pattern
- Clear separation between UI and business logic
- Services handle all external dependencies
- Pages only handle UI and user interaction

## Data Models

### Firestore Structure

```
users/
  {email}/  # Document ID is email address
    {
      name: string,
      embedding: array<number>,  # 512-dimensional vector
      face_updated_at: timestamp
    }
```

**Design Decisions**:
- Email as document ID: No duplicate emails, easy lookup
- No email field: Redundant (email is doc ID)
- Embedding as array: Direct storage of vector
- Timestamp: Track when face was last updated

### Hive Structure

```
face_embeddings_box/
  {name or email}/  # Key is name (if available) or email
    FaceEmbedding {
      email: string,
      embedding: List<double>
    }
```

**Design Decisions**:
- Key is name (if available): Better user experience
- Fallback to email: Ensures unique keys
- Stores email separately: Can retrieve email from name

## Services

### DetectionService Details

**Initialization**:
1. Open Hive box
2. Sync from Firestore
3. Set up real-time listener

**Matching Algorithm**:
1. Normalize probe embedding (L2 normalization)
2. Iterate through all stored embeddings
3. Calculate cosine similarity
4. Return best match if above threshold (0.7)

**Cosine Similarity**:
```
similarity = dot(a, b) / (||a|| * ||b||)
```
- Range: -1 to 1
- Higher value = more similar
- Threshold: 0.7 (70% similarity)

### FaceEmbedder Details

**Model Loading**:
1. Check if model exists locally
2. If not, load from assets
3. Copy to app documents directory
4. Load with TensorFlow Lite interpreter

**Image Preprocessing**:
1. Resize to model input size (typically 160x160)
2. Convert to RGB
3. Normalize to [-1, 1] range
4. Reshape to [1, H, W, 3]

**Embedding Generation**:
1. Run model inference
2. Get output vector (512 dimensions)
3. L2 normalize the vector
4. Return normalized embedding

## Performance Considerations

### Optimization Strategies

1. **Model Loading**: Singleton pattern ensures model loaded once
2. **Local Storage**: Hive for fast offline access
3. **Batch Processing**: Process multiple faces efficiently
4. **Image Resolution**: Medium resolution for balance between speed and accuracy
5. **Detection Interval**: 1.5 seconds to avoid overloading

### Memory Management

- Dispose camera controllers properly
- Close Hive boxes when done
- Release TensorFlow Lite interpreter resources
- Clear image buffers after processing

## Security Considerations

1. **Firestore Rules**: Should implement proper authentication
2. **Model Security**: FaceNet model is embedded in app
3. **Data Privacy**: Face embeddings stored locally and in cloud
4. **Permissions**: Camera permission required

## Future Improvements

1. **Authentication**: Add user authentication
2. **Encryption**: Encrypt local storage
3. **Model Updates**: Support model updates from server
4. **Batch Registration**: Register multiple faces at once
5. **Face Groups**: Organize faces into groups/categories

---

This architecture provides a solid foundation for the face recognition app with clear separation of concerns and extensibility.

