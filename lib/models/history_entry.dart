import 'package:hive/hive.dart';

class HistoryEntry extends HiveObject {
  HistoryEntry({
    required this.id,
    required this.imagePath,
    required this.prediction,
    required this.accuracy,
    required this.captureSource,
    required this.recordedAt,
  });

  final String id;
  final String imagePath;
  final String prediction;
  final double accuracy;
  final String captureSource;
  final DateTime recordedAt;
}

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final int typeId = 0;

  @override
  HistoryEntry read(BinaryReader reader) {
    final fields = <int, dynamic>{};
    final count = reader.readByte();
    for (var i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return HistoryEntry(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      prediction: fields[2] as String,
      accuracy: fields[3] as double,
      captureSource: fields[4] as String,
      recordedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.prediction)
      ..writeByte(3)
      ..write(obj.accuracy)
      ..writeByte(4)
      ..write(obj.captureSource)
      ..writeByte(5)
      ..write(obj.recordedAt);
  }
}
