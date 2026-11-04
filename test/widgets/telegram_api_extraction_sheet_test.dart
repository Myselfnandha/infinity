// This code for widget testing TelegramApiExtractionSheet modal presentation and manual credential entry
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/features/auth/telegram_api_extraction_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.dart';

void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping TelegramApiExtractionSheet UI interaction tests
  group('TelegramApiExtractionSheet Widget Tests', () {
    late TestDatabase db;
    late AppPreferences prefs;
    late FakeTdlibService fakeTdlib;

    setUp(() async {
      // This code for preparing mock preferences and services before each test
      SharedPreferences.setMockInitialValues({});
      prefs = await AppPreferences.getInstance();
      db = TestDatabase();
      fakeTdlib = FakeTdlibService();
    });

    tearDown(() async {
      // This code for releasing database resources after test execution
      await db.close();
    });

    testWidgets('Renders header and falls back to manual entry on headless platform', (WidgetTester tester) async {
      // This code for pumping modal sheet widget into tester
      await tester.pumpWidget(
        buildTestApp(
          child: const TelegramApiExtractionSheet(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // This code for verifying modal header and manual fallback components
      expect(find.text('Auto-Connect Telegram API'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Enter Telegram API Credentials'), findsOneWidget);
      expect(find.text('Apply and Connect'), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsNWidgets(2));
    });

    testWidgets('Validates invalid numeric API ID on submit', (WidgetTester tester) async {
      // This code for testing validation rejection of non-numeric ID
      await tester.pumpWidget(
        buildTestApp(
          child: const TelegramApiExtractionSheet(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(CupertinoTextField);
      await tester.enterText(textFields.first, 'invalid_id');
      await tester.enterText(textFields.last, '0123456789abcdef0123456789abcdef');

      await tester.tap(find.text('Apply and Connect'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Please enter a valid numeric API ID'), findsOneWidget);
    });

    testWidgets('Validates invalid API Hash length on submit', (WidgetTester tester) async {
      // This code for testing validation rejection of short API hash
      await tester.pumpWidget(
        buildTestApp(
          child: const TelegramApiExtractionSheet(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(CupertinoTextField);
      await tester.enterText(textFields.first, '30662321');
      await tester.enterText(textFields.last, 'short_hash');

      await tester.tap(find.text('Apply and Connect'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('API Hash must be a 32-character hexadecimal string'), findsOneWidget);
    });

    testWidgets('Saves valid credentials to preferences and dismisses sheet', (WidgetTester tester) async {
      // This code for testing successful manual submission flow
      await tester.pumpWidget(
        buildTestApp(
          child: const TelegramApiExtractionSheet(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(CupertinoTextField);
      await tester.enterText(textFields.first, '30662321');
      await tester.enterText(textFields.last, '0123456789abcdef0123456789abcdef');

      await tester.tap(find.text('Apply and Connect'));
      await tester.pump(const Duration(milliseconds: 1000));

      expect(prefs.telegramApiId, equals(30662321));
      expect(prefs.telegramApiHash, equals('0123456789abcdef0123456789abcdef'));
    });
  });
}
