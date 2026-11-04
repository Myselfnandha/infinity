// This code for widget testing AlbumsScreen, AlbumDetailScreen, and TrashScreen album management
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/di/providers.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/features/albums/album_detail_screen.dart';
import 'package:infinity/features/albums/albums_screen.dart';
import 'package:infinity/features/albums/trash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.dart';

// This code for executing albums screens widget tests
void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping Albums, AlbumDetail, and Trash widget tests
  group('Albums Screens Widget Tests', () {
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
      // This code for closing database resources after test execution
      await db.close();
    });

    // This code for testing standard album category cards and new album creation dialog
    testWidgets('AlbumsScreen renders standard vault albums and opens new album dialog', (WidgetTester tester) async {
      // This code for pumping AlbumsScreen into tester
      await tester.pumpWidget(
        buildTestApp(
          child: const AlbumsScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            albumsProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert default system category cards
      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Screenshots'), findsOneWidget);
      expect(find.text('Duplicates'), findsOneWidget);
      expect(find.text('Files'), findsOneWidget);
      expect(find.text('Trash'), findsOneWidget);

      // Tap + button to trigger new album dialog
      final plusButton = find.byIcon(CupertinoIcons.add);
      expect(plusButton, findsOneWidget);
      await tester.tap(plusButton);
      await tester.pump();

      // Assert AlertDialog elements
      expect(find.text('New Album'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Enter album title and create
      await tester.enterText(find.byType(CupertinoTextField), 'Trip to Japan');
      await tester.tap(find.text('Create'));
      await tester.pump();

      expect(fakeTdlib.createdTopics, contains('Trip to Japan'));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // This code for testing AlbumsScreen tapping category card navigation
    testWidgets('AlbumsScreen tapping category card navigates to category album', (WidgetTester tester) async {
      // This code for pumping AlbumsScreen with navigation host
      await tester.pumpWidget(
        buildTestApp(
          child: const AlbumsScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            albumsProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Photos category card
      await tester.tap(find.text('Photos'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Assert AlbumDetailScreen pushed with Photos title
      expect(find.byType(AlbumDetailScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // This code for testing AlbumDetailScreen empty state
    testWidgets('AlbumDetailScreen renders title and displays empty album message when no items', (WidgetTester tester) async {
      // This code for pumping AlbumDetailScreen with empty items
      await tester.pumpWidget(
        buildTestApp(
          child: const AlbumDetailScreen(title: 'Vacation Photos'),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert title and empty album message
      expect(find.text('Vacation Photos'), findsOneWidget);
      expect(find.text('No media in Vacation Photos'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // This code for testing AlbumDetailScreen populated items and selection mode toggle
    testWidgets('AlbumDetailScreen renders media items in grid and toggles selection mode', (WidgetTester tester) async {
      // This code for inserting image item
      final now = DateTime.now();
      final item = MediaItem(
        id: 'album_item_1',
        filePath: '/mock/album_pic.jpg',
        mediaType: 'image',
        fileSize: 2048,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
      );
      await db.insertMediaItem(item.toCompanion(false));

      // This code for pumping AlbumDetailScreen for Photos category
      await tester.pumpWidget(
        buildTestApp(
          child: const AlbumDetailScreen(title: 'Photos'),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert items rendered in grid and Select button exists
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Select'), findsOneWidget);

      // Enter selection mode
      await tester.tap(find.text('Select'));
      await tester.pump();

      // Assert selection toolbar and Done button appear
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('0 Selected'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // This code for testing TrashScreen empty state
    testWidgets('TrashScreen displays empty state when trash is empty', (WidgetTester tester) async {
      // This code for pumping TrashScreen with empty trash stream
      await tester.pumpWidget(
        buildTestApp(
          child: const TrashScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            trashProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert empty trash presentation
      expect(find.text('Trash'), findsOneWidget);
      expect(find.text('Trash is Empty'), findsOneWidget);
      expect(find.text('Deleted photos and videos stay here until emptied'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // This code for testing TrashScreen restore all action
    testWidgets('TrashScreen renders trashed items and allows restoring them', (WidgetTester tester) async {
      // This code for creating trashed media item
      final now = DateTime.now();
      final trashedItem = MediaItem(
        id: 'trash_restore_item',
        filePath: '/mock/deleted.jpg',
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: now,
        isFavorite: false,
        isTrashed: true,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
      );
      await db.insertMediaItem(trashedItem.toCompanion(false));

      // This code for pumping TrashScreen with populated trash stream
      await tester.pumpWidget(
        buildTestApp(
          child: const TrashScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            trashProvider.overrideWith((ref) => Stream.value([trashedItem])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert empty state is gone and action buttons appear
      expect(find.text('Trash is Empty'), findsNothing);
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('Restore All'), findsOneWidget);
      expect(find.text('1 items in Trash'), findsOneWidget);

      // Tap Restore All
      await tester.tap(find.text('Restore All'));
      await tester.pump();

      // Verify item updated in database to isTrashed = false
      final restored = await db.getMediaItem('trash_restore_item');
      expect(restored!.isTrashed, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // This code for testing TrashScreen empty trash confirmation and deletion
    testWidgets('TrashScreen confirms and executes Empty Trash to purge items from database', (WidgetTester tester) async {
      // This code for creating trashed media item
      final now = DateTime.now();
      final trashedItem = MediaItem(
        id: 'trash_purge_item',
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: now,
        isFavorite: false,
        isTrashed: true,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
      );
      await db.insertMediaItem(trashedItem.toCompanion(false));

      // This code for pumping TrashScreen
      await tester.pumpWidget(
        buildTestApp(
          child: const TrashScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            trashProvider.overrideWith((ref) => Stream.value([trashedItem])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Empty button in navigation bar
      await tester.tap(find.text('Empty'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Assert action sheet appears
      expect(find.text('Empty Trash?'), findsOneWidget);

      // Tap Empty Trash destructive button in action sheet
      await tester.tap(find.text('Empty Trash'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify item deleted completely from database
      final purged = await db.getMediaItem('trash_purge_item');
      expect(purged, isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // This code for testing individual item restore via action sheet tap
    testWidgets('TrashScreen allows tapping single item to restore it individually via action sheet', (WidgetTester tester) async {
      // This code for creating trashed media item
      final now = DateTime.now();
      final trashedItem = MediaItem(
        id: 'trash_single_restore',
        filePath: '/mock/single_restore.jpg',
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: now,
        isFavorite: false,
        isTrashed: true,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
      );
      await db.insertMediaItem(trashedItem.toCompanion(false));

      // This code for pumping TrashScreen
      await tester.pumpWidget(
        buildTestApp(
          child: const TrashScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            trashProvider.overrideWith((ref) => Stream.value([trashedItem])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on the grid tile
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Assert action sheet with Restore Photo appears
      expect(find.text('Restore Photo'), findsOneWidget);

      // Tap Restore Photo
      await tester.tap(find.text('Restore Photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify item updated in database to isTrashed = false
      final restored = await db.getMediaItem('trash_single_restore');
      expect(restored!.isTrashed, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
