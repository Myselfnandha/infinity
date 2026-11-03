// This code for widget smoke test verifying root application rendering
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/di/providers.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This code for providing an in-memory database instance for testing
class TestDatabase extends AppDatabase {
  TestDatabase() : super.forTesting(NativeDatabase.memory());
}

void main() {
  testWidgets('InfinityApp smoke test', (WidgetTester tester) async {
    // This code for mocking SharedPreferences with onboarding completed
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final prefs = await AppPreferences.getInstance();
    final testDb = TestDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          preferencesProvider.overrideWithValue(prefs),
        ],
        child: const InfinityApp(),
      ),
    );

    expect(find.byType(InfinityApp), findsOneWidget);
    await tester.pump();
    await testDb.close();
  });
}
