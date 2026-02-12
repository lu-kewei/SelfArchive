import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage/database_service.dart';
import 'ui/board/board_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService();
  await dbService.init();

  final container = ProviderContainer(
    overrides: [databaseServiceProvider.overrideWithValue(dbService)],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SelfArchiveApp(),
    ),
  );
}

class SelfArchiveApp extends StatelessWidget {
  const SelfArchiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self Archive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3E2723)),
        useMaterial3: true,
      ),
      home: const BoardScreen(),
    );
  }
}
