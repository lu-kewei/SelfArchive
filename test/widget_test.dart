import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:self_archive/main.dart';
import 'package:self_archive/storage/database_service.dart';
import 'package:self_archive/scene/models/node_entity.dart';
import 'package:self_archive/scene/models/edge_entity.dart';

// Mock/Fake DatabaseService
class FakeDatabaseService extends DatabaseService {
  @override
  Future<void> init() async {}

  @override
  Future<List<NodeEntity>> getAllNodes() async => [];

  @override
  Future<List<EdgeEntity>> getAllEdges() async => [];
}

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(FakeDatabaseService()),
        ],
        child: const SelfArchiveApp(),
      ),
    );

    // Verify that the app builds without crashing.
    expect(find.byType(SelfArchiveApp), findsOneWidget);
  });
}
