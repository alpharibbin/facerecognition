import 'package:hive/hive.dart';

class FaceEmbedding extends HiveObject {
  String email;
  List<double> embedding;

  FaceEmbedding({required this.email, required this.embedding});
}

class FaceEmbeddingAdapter extends TypeAdapter<FaceEmbedding> {
  @override
  final int typeId = 1;

  @override
  FaceEmbedding read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return FaceEmbedding(
      email: fields[0] as String,
      embedding: (fields[1] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }

  @override
  void write(BinaryWriter writer, FaceEmbedding obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.email)
      ..writeByte(1)
      ..write(obj.embedding);
  }
}
