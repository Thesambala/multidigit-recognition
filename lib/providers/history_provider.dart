import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/history_entry.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(Box<HistoryEntry> box) : _box = box {
    _loadEntries();
  }

  final Box<HistoryEntry> _box;
  List<HistoryEntry> _entries = const [];
  bool _isSaving = false;
  bool _isLoading = true;

  List<HistoryEntry> get entries => _entries;
  bool get isSaving => _isSaving;
  bool get isEmpty => _entries.isEmpty;
  bool get isLoading => _isLoading;

  Future<void> refresh() async {
    _entries = _box.values.toList().reversed.toList();
    notifyListeners();
  }

  Future<void> _loadEntries() async {
    _isLoading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _entries = _box.values.toList().reversed.toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveEntry({
    required Uint8List imageBytes,
    required String prediction,
    required double accuracy,
    required String captureSource,
    required DateTime recordedAt,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final filePath = await _persistImage(imageBytes, recordedAt);
      final entry = HistoryEntry(
        id: recordedAt.millisecondsSinceEpoch.toString(),
        imagePath: filePath,
        prediction: prediction,
        accuracy: accuracy,
        captureSource: captureSource,
        recordedAt: recordedAt,
      );
      await _box.add(entry);
      _entries = [entry, ..._entries];
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String> _persistImage(Uint8List bytes, DateTime timestamp) async {
    final directory = await getApplicationDocumentsDirectory();
    final historyDir = Directory('${directory.path}/history');
    if (!historyDir.existsSync()) {
      historyDir.createSync(recursive: true);
    }
    final file = File(
      '${historyDir.path}/capture_${timestamp.millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
