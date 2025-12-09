import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/history_entry.dart';
import 'pages/welcome_page.dart';
import 'providers/capture_provider.dart';
import 'providers/history_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(HistoryEntryAdapter());
  final historyBox = await Hive.openBox<HistoryEntry>('history_entries');
  runApp(MyApp(historyBox: historyBox));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.historyBox});

  final Box<HistoryEntry> historyBox;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CaptureProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider(historyBox)),
      ],
      child: MaterialApp(
        title: 'Deteksi MultiDigit',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
        home: const WelcomePage(),
      ),
    );
  }
}
