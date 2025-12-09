import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:multidigit_recognition/main.dart';
import 'package:multidigit_recognition/models/history_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<HistoryEntry> historyBox;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('history_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(HistoryEntryAdapter().typeId)) {
      Hive.registerAdapter(HistoryEntryAdapter());
    }
    historyBox = await Hive.openBox<HistoryEntry>('history_entries_test');
  });

  tearDownAll(() async {
    await historyBox.close();
    await Hive.deleteBoxFromDisk('history_entries_test');
    await tempDir.delete(recursive: true);
  });

  testWidgets('Welcome page renders and navigates', (tester) async {
    await tester.pumpWidget(MyApp(historyBox: historyBox));

    expect(find.text('Deteksi MultiDigit'), findsOneWidget);

    await tester.tap(find.text('Mulai!'));
    await tester.pumpAndSettle();

    expect(find.text('Deteksi Multidigit'), findsOneWidget);

    await tester.tap(find.text('Mulai Deteksi Multidigit'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Scan Multidigit'), findsOneWidget);
  });
}
