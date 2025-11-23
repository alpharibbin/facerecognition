import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/face_embedding.dart';

class DetectionService {
  static const String kBoxName = 'face_embeddings_box';
  static const String kCollection = 'users';

  late final Box<FaceEmbedding> _box;
  final FirebaseFirestore _firestore;
  bool _isInitialized = false;

  DetectionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> init() async {
    if (!_isInitialized) {
      _box = await Hive.openBox<FaceEmbedding>(kBoxName);
      _isInitialized = true;
      await syncFromFirestore();
      _listenForChanges();
    } else {
      // Already initialized; resync only
      await syncFromFirestore();
    }
  }

  Future<void> syncFromFirestore() async {
    final snapshot = await _firestore
        .collection(kCollection)
        .where('embedding', isNull: false)
        .get();

    final existingKeys = Set<String>.from(_box.keys.cast<String>());
    final seen = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final email = doc.id.toLowerCase(); // email is the doc id
      final name = data['name'] as String?;
      final dynamic embRaw = data['embedding'];

      if (email.isEmpty || embRaw is! List) {
        continue;
      }

      final emb = embRaw
          .where((e) => e != null)
          .map((e) => (e as num).toDouble())
          .toList(growable: false);

      if (emb.isEmpty) continue;

      // Store with name instead of email for better identification
      final key = name != null && name.isNotEmpty ? name : email;
      await _box.put(key, FaceEmbedding(email: email, embedding: emb));
      seen.add(key);
    }

    // Remove deleted docs
    for (final key in existingKeys.difference(seen)) {
      await _box.delete(key);
    }
  }

  void _listenForChanges() {
    _firestore
        .collection(kCollection)
        .where('embedding', isNull: false)
        .snapshots()
        .listen((snapshot) async {
          for (final change in snapshot.docChanges) {
            final doc = change.doc;
            final data = doc.data();

            if (change.type == DocumentChangeType.removed) {
              final email = doc.id.toLowerCase();
              final name = data?['name'] as String?;
              final key = name != null && name.isNotEmpty ? name : email;
              if (key != null) await _box.delete(key);
            } else {
              if (data == null) continue;

              final email = doc.id.toLowerCase();
              final name = data['name'] as String?;
              final dynamic embRaw = data['embedding'];

              if (email.isEmpty || embRaw is! List) continue;

              final emb = embRaw
                  .where((e) => e != null)
                  .map((e) => (e as num).toDouble())
                  .toList(growable: false);

              if (emb.isEmpty) continue;

              final key = name != null && name.isNotEmpty ? name : email;
              await _box.put(key, FaceEmbedding(email: email, embedding: emb));
            }
          }
        });
  }

  MapEntry<String, double>? findBestMatch(
    List<double> probeEmbedding, {
    double threshold = 0.7,
  }) {
    if (probeEmbedding.isEmpty) return null;
    final normalizedProbe = _l2Normalize(probeEmbedding);
    String? bestName;
    double bestScore = -1.0;
    for (final key in _box.keys) {
      final item = _box.get(key);
      if (item == null) continue;
      final score = _cosineSimilarity(
        normalizedProbe,
        _l2Normalize(item.embedding),
      );
      if (score > bestScore) {
        bestScore = score;
        bestName = key; // key is the name, not email
      }
    }
    if (bestName != null && bestScore >= threshold) {
      return MapEntry(bestName, bestScore);
    }
    return null;
  }

  // Helper method to get email from name if needed
  String? getEmailFromName(String name) {
    final item = _box.get(name);
    return item?.email;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, na = 0, nb = 0;
    for (int i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      dot += x * y;
      na += x * x;
      nb += y * y;
    }
    final denom = sqrt(na) * sqrt(nb);
    return denom == 0 ? 0 : dot / denom;
  }

  List<double> _l2Normalize(List<double> v) {
    double sumsq = 0;
    for (final x in v) sumsq += x * x;
    final norm = sqrt(sumsq);
    if (norm == 0) return v;
    return v.map((x) => x / norm).toList(growable: false);
  }
}
