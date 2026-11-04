// This code for widget testing SearchScreen query filters, scope pills, date ranges, and result grids
import 'package:drift/drift.dart' as drift;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/features/search/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.dart';

void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping SearchScreen widget interaction tests
  group('SearchScreen Widget Tests', () {
    late TestDatabase db;
    late AppPreferences prefs;
    late FakeTdlibService fakeTdlib;

    setUp(() async {
      // This code for preparing mock preferences and database before each test
      SharedPreferences.setMockInitialValues({});
      prefs = await AppPreferences.getInstance();
      db = TestDatabase();
      fakeTdlib = FakeTdlibService();
    });

    tearDown(() async {
      // This code for releasing database resources after test execution
      await db.close();
    });

    testWidgets('SearchScreen renders navigation bar, search bar, scope pills, and initial empty placeholder', (WidgetTester tester) async {
      // This code for pumping SearchScreen into widget tester
      await tester.pumpWidget(
        buildTestApp(
          child: const SearchScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert header and search input
      expect(find.text('Search Vault'), findsOneWidget);
      expect(find.byType(CupertinoSearchTextField), findsOneWidget);

      // Assert scope filter pills
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Places'), findsOneWidget);
      expect(find.text('Duplicates'), findsOneWidget);
      expect(find.text('Files'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Pinned'), findsOneWidget);

      // Assert date chips
      expect(find.text('Any Time'), findsOneWidget);
      expect(find.text('Past 7 Days'), findsOneWidget);

      // Assert initial empty guidance text
      expect(find.text('Search by name, category, or date range'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('SearchScreen filters and displays matching items for text query and media scope', (WidgetTester tester) async {
      // This code for inserting sample media items into database
      final now = DateTime.now();
      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'hawaii_sunset',
          filePath: const drift.Value('/storage/hawaii_sunset.jpg'),
          mediaType: 'image',
          fileSize: 1024 * 1024,
          dateAdded: now,
          locationName: const drift.Value('Hawaii, USA'),
        ),
      );
      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'paris_eiffel',
          filePath: const drift.Value('/storage/paris_tower.jpg'),
          mediaType: 'image',
          fileSize: 2048 * 1024,
          dateAdded: now,
          locationName: const drift.Value('Paris, France'),
        ),
      );

      // This code for pumping SearchScreen
      await tester.pumpWidget(
        buildTestApp(
          child: const SearchScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter query 'Hawaii' into search field
      await tester.enterText(find.byType(CupertinoSearchTextField), 'Hawaii');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert results text indicates 1 item found
      expect(find.text('1 item found'), findsOneWidget);

      // Change query to nonexistent text
      await tester.enterText(find.byType(CupertinoSearchTextField), 'Tokyo');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No matching items found'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('SearchScreen toggles scope pills and updates active selection', (WidgetTester tester) async {
      // This code for testing scope pill taps
      await tester.pumpWidget(
        buildTestApp(
          child: const SearchScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Videos' pill
      await tester.tap(find.text('Videos'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // When scope changed with no query, displays 'No matching items found' because db is empty
      expect(find.text('No matching items found'), findsOneWidget);

      // Tap 'All' pill to return
      await tester.tap(find.text('All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Search by name, category, or date range'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
