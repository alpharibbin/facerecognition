# API Reference

Complete API documentation for services and components in the Face Recognition app.

## Table of Contents

1. [DetectionService](#detectionservice)
2. [FaceEmbedder](#faceembedder)
3. [FaceEmbedding Model](#faceembedding-model)
4. [Firestore API](#firestore-api)

## DetectionService

Service for managing face embeddings and performing face matching.

### Class: `DetectionService`

```dart
class DetectionService
```

### Properties

- `static const String kBoxName = 'face_embeddings_box'`
- `static const String kCollection = 'users'`

### Methods

#### `init()`

Initialize the service and sync embeddings from Firestore.

```dart
Future<void> init() async
```

**Description**:
- Opens Hive box for local storage
- Syncs embeddings from Firestore
- Sets up real-time listener for changes

**Usage**:
```dart
final service = DetectionService();
await service.init();
```

**Throws**: `HiveError` if box cannot be opened

---

#### `syncFromFirestore()`

Download all embeddings from Firestore and store locally.

```dart
Future<void> syncFromFirestore() async
```

**Description**:
- Queries Firestore for all users with embeddings
- Downloads embeddings to Hive
- Removes deleted embeddings from local storage

**Usage**:
```dart
await service.syncFromFirestore();
```

**Firestore Query**:
```dart
collection('users')
  .where('embedding', isNull: false)
  .get()
```

---

#### `findBestMatch()`

Find the best matching face for a given embedding.

```dart
MapEntry<String, double>? findBestMatch(
  List<double> probeEmbedding, {
  double threshold = 0.7,
})
```

**Parameters**:
- `probeEmbedding`: Face embedding to match (List<double>)
- `threshold`: Minimum similarity score (default: 0.7)

**Returns**:
- `MapEntry<String, double>?`: Best match with name and score, or null if no match

**Description**:
- Normalizes probe embedding
- Compares with all stored embeddings using cosine similarity
- Returns best match if above threshold

**Usage**:
```dart
final match = service.findBestMatch(embedding, threshold: 0.8);
if (match != null) {
  print('Matched: ${match.key} with score: ${match.value}');
}
```

**Algorithm**:
1. L2 normalize probe embedding
2. For each stored embedding:
   - L2 normalize stored embedding
   - Calculate cosine similarity
   - Track best match
3. Return best match if above threshold

---

#### `getEmailFromName()`

Get email address from name.

```dart
String? getEmailFromName(String name)
```

**Parameters**:
- `name`: Name to lookup (String)

**Returns**:
- `String?`: Email address or null if not found

**Usage**:
```dart
final email = service.getEmailFromName('John Doe');
```

---

### Private Methods

#### `_listenForChanges()`

Listen for real-time Firestore changes.

```dart
void _listenForChanges()
```

**Description**:
- Sets up Firestore snapshot listener
- Updates Hive on document changes
- Handles additions, updates, and deletions

---

#### `_cosineSimilarity()`

Calculate cosine similarity between two vectors.

```dart
double _cosineSimilarity(List<double> a, List<double> b)
```

**Returns**: Similarity score between -1 and 1

---

#### `_l2Normalize()`

L2 normalize a vector.

```dart
List<double> _l2Normalize(List<double> v)
```

**Returns**: Normalized vector

---

## FaceEmbedder

Service for loading TensorFlow Lite model and generating face embeddings.

### Class: `FaceEmbedder`

```dart
class FaceEmbedder
```

**Pattern**: Singleton

### Methods

#### `loadModel()`

Load the FaceNet TensorFlow Lite model.

```dart
Future<bool> loadModel({
  required BuildContext context,
  String modelName = 'facenet.tflite',
}) async
```

**Parameters**:
- `context`: BuildContext for showing errors
- `modelName`: Name of model file (default: 'facenet.tflite')

**Returns**:
- `bool`: true if loaded successfully, false otherwise

**Description**:
- Loads model from assets
- Copies to app documents directory
- Initializes TensorFlow Lite interpreter
- Sets up input/output shapes

**Usage**:
```dart
final embedder = FaceEmbedder();
final loaded = await embedder.loadModel(context: context);
if (loaded) {
  // Model ready
}
```

**Model Path**: `assets/models/facenet.tflite`

---

#### `embedImage()`

Generate face embedding from image.

```dart
Future<List<double>> embedImage(
  imglib.Image faceRgb, {
  bool normalizeToMinusOneToOne = true,
}) async
```

**Parameters**:
- `faceRgb`: RGB image (imglib.Image)
- `normalizeToMinusOneToOne`: Normalize to [-1, 1] range (default: true)

**Returns**:
- `List<double>`: 512-dimensional embedding vector

**Description**:
- Resizes image to model input size (typically 160x160)
- Normalizes pixel values
- Runs model inference
- Returns L2-normalized embedding

**Usage**:
```dart
final embedding = await embedder.embedImage(faceImage);
// embedding is List<double> with 512 elements
```

**Preprocessing**:
1. Resize to model input size
2. Convert pixels to float
3. Normalize: `(pixel - 127.5) / 128.0` (if normalizeToMinusOneToOne)
4. Reshape to [1, H, W, 3]

**Post-processing**:
- L2 normalization of output vector

---

### Private Methods

#### `_getLocalModelPath()`

Get local path for model file.

```dart
Future<String> _getLocalModelPath(String modelName) async
```

**Returns**: Path to model file

**Description**:
- Checks if model exists locally
- If not, loads from assets and saves locally
- Returns path to model file

---

#### `_l2Normalize()`

L2 normalize a vector.

```dart
List<double> _l2Normalize(List<double> v)
```

**Returns**: Normalized vector

---

## FaceEmbedding Model

Data model for face embeddings stored in Hive.

### Class: `FaceEmbedding`

```dart
class FaceEmbedding extends HiveObject
```

### Properties

- `String email`: User email address
- `List<double> embedding`: Face embedding vector (512 dimensions)

### Constructor

```dart
FaceEmbedding({
  required this.email,
  required this.embedding,
})
```

### Usage

```dart
final faceEmbedding = FaceEmbedding(
  email: 'user@example.com',
  embedding: [0.123, -0.456, ..., 0.789], // 512 numbers
);
```

### Hive Adapter

Automatically registered with Hive:
- Type ID: 1
- Serializes email and embedding array

---

## Firestore API

### Collection: `users`

Document structure:
```
users/
  {email}/  # Document ID is email
    {
      name: string,
      embedding: array<number>,
      face_updated_at: timestamp
    }
```

### Operations

#### Create/Update User

```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(email)
    .set({
      'name': name,
      'embedding': embedding,
      'face_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
```

#### Get User

```dart
final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc(email)
    .get();

if (doc.exists) {
  final data = doc.data();
  final name = data?['name'];
  final embedding = data?['embedding'];
}
```

#### Query Users with Embeddings

```dart
final snapshot = await FirebaseFirestore.instance
    .collection('users')
    .where('embedding', isNull: false)
    .get();

for (final doc in snapshot.docs) {
  final email = doc.id;
  final data = doc.data();
  // Process data
}
```

#### Listen for Changes

```dart
FirebaseFirestore.instance
    .collection('users')
    .where('embedding', isNull: false)
    .snapshots()
    .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        // Handle change
      }
    });
```

---

## Error Handling

### DetectionService Errors

- **HiveError**: Box cannot be opened
  - Solution: Check Hive initialization

- **FirestoreError**: Network or permission issues
  - Solution: Check internet and Firestore rules

### FaceEmbedder Errors

- **ModelNotFoundError**: Model file missing
  - Solution: Ensure `facenet.tflite` in `assets/models/`

- **InterpreterError**: TensorFlow Lite error
  - Solution: Check model compatibility

---

## Performance Considerations

### DetectionService

- **Sync**: Runs once on init, then listens
- **Matching**: O(n) where n = number of stored faces
- **Storage**: Uses Hive for fast local access

### FaceEmbedder

- **Model Loading**: One-time operation (singleton)
- **Inference**: ~50-100ms per image
- **Memory**: Model loaded in memory (~20-30 MB)

---

## Examples

### Complete Registration Flow

```dart
// 1. Load model
final embedder = FaceEmbedder();
await embedder.loadModel(context: context);

// 2. Generate embedding
final embedding = await embedder.embedImage(faceImage);

// 3. Save to Firestore
await FirebaseFirestore.instance
    .collection('users')
    .doc(email)
    .set({
      'name': name,
      'embedding': embedding,
      'face_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

// 4. Save to Hive
final box = await Hive.openBox<FaceEmbedding>('face_embeddings_box');
await box.put(name, FaceEmbedding(email: email, embedding: embedding));
```

### Complete Detection Flow

```dart
// 1. Initialize service
final service = DetectionService();
await service.init();

// 2. Generate embedding from detected face
final embedder = FaceEmbedder();
await embedder.loadModel(context: context);
final embedding = await embedder.embedImage(detectedFace);

// 3. Find match
final match = service.findBestMatch(embedding, threshold: 0.7);
if (match != null) {
  print('Recognized: ${match.key} (${match.value})');
} else {
  print('Unknown face');
}
```

---

This API reference covers all public methods and classes. For implementation details, see the source code.

