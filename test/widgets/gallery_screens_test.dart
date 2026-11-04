// This code for widget testing PhotosTimelineScreen and FavoritesScreen photo grids and selection states
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/di/providers.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/features/gallery/favorites_screen.dart';
import 'package:infinity/features/gallery/photos_timeline_screen.dart';
import 'package:infinity/features/viewer/media_viewer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.dart';

// This code for executing gallery screens widget tests
void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping PhotosTimelineScreen and FavoritesScreen widget tests
  group('Gallery Screens Widget Tests', () {
    late TestDatabase db;
    late AppPreferences prefs;
    late FakeTdlibService fakeTdlib;

    setUp(() async {
      // This code for preparing mock preferences and isolated database before each test
      SharedPreferences.setMockInitialValues({});
      prefs = await AppPreferences.getInstance();
      db = TestDatabase();
      fakeTdlib = FakeTdlibService();
    });

    tearDown(() async {
      // This code for closing database resources after each test
      await db.close();
    });

    // This code for verifying empty state presentation when database contains no photos
    testWidgets('PhotosTimelineScreen renders empty state when database has no media', (WidgetTester tester) async {
      // This code for pumping empty timeline into widget tester
      await tester.pumpWidget(
        buildTestApp(
          child: const PhotosTimelineScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            allMediaProvider.overrideWith((ref) => Stream.value([])),
            pendingTasksProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // This code for verifying empty state presentation
      expect(find.text('Infinity Photos'), findsOneWidget);
      expect(find.text('No media loaded yet'), findsOneWidget);
      expect(find.text('Drag down to refresh or scan device media'), findsOneWidget);
      expect(find.byType(CupertinoButton), findsWidgets);
    });

    // This code for verifying media rendering and selection mode toggle
    testWidgets('PhotosTimelineScreen renders media items and toggles selection mode', (WidgetTester tester) async {
      // This code for generating sample media items
      final now = DateTime.now();
      final sampleItems = [
        MediaItem(
          id: 'timeline_photo_1',
          mediaType: 'image',
          fileSize: 1024 * 500,
          dateAdded: now,
          dateTaken: now,
          isFavorite: false,
          isTrashed: false,
          syncStatus: 'local',
          cloudState: 'LOCAL_ONLY',
          isPinnedOffline: false,
        ),
        MediaItem(
          id: 'timeline_photo_2',
          mediaType: 'image',
          fileSize: 1024 * 800,
          dateAdded: now,
          dateTaken: now,
          isFavorite: false,
          isTrashed: false,
          syncStatus: 'synced',
          cloudState: 'SYNCED',
          isPinnedOffline: false,
        ),
      ];

      // This code for pumping timeline widget with populated data stream
      await tester.pumpWidget(
        buildTestApp(
          child: const PhotosTimelineScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            allMediaProvider.overrideWith((ref) => Stream.value(sampleItems)),
            pendingTasksProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify header and that empty state message is gone
      expect(find.text('Infinity Photos'), findsOneWidget);
      expect(find.text('No Photos in Vault'), findsNothing);

      // Verify Select button is present in navigation bar
      final selectButton = find.text('Select');
      expect(selectButton, findsOneWidget);

      // Tap Select to enter selection mode
      await tester.tap(selectButton);
      await tester.pump();

      // Verify selection mode toolbar and Cancel button appear
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('0 Selected'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);

      // Tap Cancel to exit selection mode
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.text('Select'), findsOneWidget);
    });

    // This code for testing Select All and batch favoriting in PhotosTimelineScreen
    testWidgets('PhotosTimelineScreen select all button selects items and batch favorites them in database', (WidgetTester tester) async {
      // This code for generating sample media items and inserting into test database
      final now = DateTime.now();
      final item1 = MediaItem(
        id: 'batch_fav_1',
        mediaType: 'image',
        fileSize: 1024 * 500,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        cloudState: 'LOCAL_ONLY',
        isPinnedOffline: false,
      );
      final item2 = MediaItem(
        id: 'batch_fav_2',
        mediaType: 'image',
        fileSize: 1024 * 800,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
      );
      await db.insertMediaItem(item1.toCompanion(false));
      await db.insertMediaItem(item2.toCompanion(false));

      // This code for pumping timeline widget
      await tester.pumpWidget(
        buildTestApp(
          child: const PhotosTimelineScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            allMediaProvider.overrideWith((ref) => Stream.value([item1, item2])),
            pendingTasksProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter selection mode
      await tester.tap(find.text('Select'));
      await tester.pump();

      // Tap Select All
      await tester.tap(find.text('Select All'));
      await tester.pump();

      // Verify counter
      expect(find.text('2 Selected'), findsOneWidget);

      // Tap favorite toolbar button
      await tester.tap(find.byIcon(CupertinoIcons.heart));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify database updated
      final updated1 = await db.getMediaItem('batch_fav_1');
      final updated2 = await db.getMediaItem('batch_fav_2');
      expect(updated1!.isFavorite, isTrue);
      expect(updated2!.isFavorite, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // This code for testing batch trashing in PhotosTimelineScreen
    testWidgets('PhotosTimelineScreen batch trashes selected items in database', (WidgetTester tester) async {
      // This code for inserting items into database
      final now = DateTime.now();
      final item1 = MediaItem(
        id: 'batch_trash_1',
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        cloudState: 'LOCAL_ONLY',
        isPinnedOffline: false,
      );
      await db.insertMediaItem(item1.toCompanion(false));

      // This code for pumping timeline
      await tester.pumpWidget(
        buildTestApp(
          child: const PhotosTimelineScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            allMediaProvider.overrideWith((ref) => Stream.value([item1])),
            pendingTasksProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter selection mode
      await tester.tap(find.text('Select'));
      await tester.pump();

      // Tap Select All
      await tester.tap(find.text('Select All'));
      await tester.pump();

      // Tap trash button in selection mode
      await tester.tap(find.byIcon(CupertinoIcons.trash));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify database updated
      final updated = await db.getMediaItem('batch_trash_1');
      expect(updated!.isTrashed, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // This code for testing tapping a photo tile outside selection mode opening MediaViewerScreen
    testWidgets('PhotosTimelineScreen tapping photo tile outside selection mode opens MediaViewerScreen', (WidgetTester tester) async {
      final now = DateTime.now();
      final item = MediaItem(
        id: 'timeline_open_viewer_item',
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        cloudState: 'LOCAL_ONLY',
        isPinnedOffline: false,
      );
      await db.insertMediaItem(item.toCompanion(false));

      await tester.pumpWidget(
        buildTestApp(
          child: const PhotosTimelineScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            allMediaProvider.overrideWith((ref) => Stream.value([item])),
            pendingTasksProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on the photo item
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Assert MediaViewerScreen opened
      expect(find.byType(MediaViewerScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // This code for testing FavoritesScreen empty state
    testWidgets('FavoritesScreen displays empty state placeholder when no favorites exist', (WidgetTester tester) async {
      // This code for pumping FavoritesScreen with no favorite items
      await tester.pumpWidget(
        buildTestApp(
          child: const FavoritesScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            favoritesProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // This code for asserting empty state UI elements
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('No favorites yet'), findsOneWidget);
      expect(find.text('Tap the heart icon on any photo to favorite it'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
    });

    // This code for testing FavoritesScreen populated grid
    testWidgets('FavoritesScreen renders favorite items in grid', (WidgetTester tester) async {
      // This code for inserting favorite media items
      final favItems = [
        MediaItem(
          id: 'fav_item_1',
          filePath: '/mock/fav1.jpg',
          mediaType: 'image',
          fileSize: 2048,
          dateAdded: DateTime.now(),
          isFavorite: true,
          isTrashed: false,
          syncStatus: 'synced',
          cloudState: 'SYNCED',
          isPinnedOffline: false,
        ),
      ];

      // This code for pumping FavoritesScreen with favorite data
      await tester.pumpWidget(
        buildTestApp(
          child: const FavoritesScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          additionalOverrides: [
            favoritesProvider.overrideWith((ref) => Stream.value(favItems)),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // This code for verifying favorite item is rendered in GridView
      expect(find.text('No favorites yet'), findsNothing);
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
