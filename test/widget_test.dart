import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/di/providers.dart';
import 'package:infinity/main.dart';

class TestDatabase extends AppDatabase {
  TestDatabase() : super.forTesting(NativeDatabase.memory());
}

void main() {
  testWidgets('InfinityApp smoke test', (WidgetTester tester) async {
    final testDb = TestDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const InfinityApp(),
      ),
    );

    expect(find.byType(InfinityApp), findsOneWidget);
    await tester.pump();
    await testDb.close();
  });
}
