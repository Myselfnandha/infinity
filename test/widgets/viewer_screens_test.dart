// This code for widget testing MediaViewerScreen and ExifInfoSheet inspection interactions
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/features/viewer/exif_info_sheet.dart';
import 'package:infinity/features/viewer/media_viewer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.dart';

// This code for executing viewer screens widget tests
void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping MediaViewerScreen and ExifInfoSheet widget tests
  group('Viewer Screens Widget Tests', () {
    late TestDatabase db;
    late AppPreferences prefs;
    late FakeTdlibService fakeTdlib;
    late Directory tempDir;
    late File testImageFile;

    setUp(() async {
      // This code for initializing mock preferences, database, and temporary image file
      SharedPreferences.setMockInitialValues({});
      prefs = await AppPreferences.getInstance();
      db = TestDatabase();
      fakeTdlib = FakeTdlibService();
      tempDir = await Directory.systemTemp.createTemp('viewer_test_');

      final image = img.Image(width: 64, height: 64);
      img.fill(image, color: img.ColorRgb8(50, 100, 150));
      testImageFile = File('${tempDir.path}/viewer_photo.png')
        ..writeAsBytesSync(img.encodePng(image));
    });

    tearDown(() async {
      // This code for cleaning up test database and directory artifacts
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    // This code for verifying basic rendering of toolbar actions
    testWidgets('MediaViewerScreen renders image and toolbar buttons', (WidgetTester tester) async {
      // This code for creating media item associated with test file
      final now = DateTime.now();
      final item = MediaItem(
        id: 'viewer_img_1',
        filePath: testImageFile.path,
        mediaType: 'image',
        width: 1920,
        height: 1080,
        fileSize: testImageFile.lengthSync(),
        dateAdded: now,
        dateTaken: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        cloudState: 'LOCAL_ONLY',
        isPinnedOffline: false,
      );
      await db.insertMediaItem(item.toCompanion(false));

      // This code for pumping viewer screen
      await tester.pumpWidget(
        buildTestApp(
          child: MediaViewerScreen(item: item),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // This code for asserting toolbar icons: info, heart, pin, trash
      expect(find.byIcon(CupertinoIcons.info_circle), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.pin), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);
    });

    // This code for testing favoriting toggle interaction
    testWidgets('MediaViewerScreen toggles favorite state in database', (WidgetTester tester) async {
      // This code for creating media item
      final now = DateTime.now();
      final item = MediaItem(
        id: 'viewer_fav_toggle',
        filePath: testImageFile.path,
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
      );
      await db.insertMediaItem(item.toCompanion(false));

      // This code for pumping viewer
      await tester.pumpWidget(
        buildTestApp(
          child: MediaViewerScreen(item: item),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();

      // Tap favorite button to favorite
      await tester.tap(find.byIcon(CupertinoIcons.heart));
      await tester.pump();

      // Verify database updated
      final updated = await db.getMediaItem('viewer_fav_toggle');
      expect(updated!.isFavorite, isTrue);
      expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
    });

    // This code for testing offline pin state toggle interaction
    testWidgets('MediaViewerScreen toggles offline pin state in database', (WidgetTester tester) async {
      // This code for creating media item
      final now = DateTime.now();
      final item = MediaItem(
        id: 'viewer_pin_toggle',
        filePath: testImageFile.path,
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
      );
      await db.insertMediaItem(item.toCompanion(false));

      // This code for pumping viewer
      await tester.pumpWidget(
        buildTestApp(
          child: MediaViewerScreen(item: item),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();

      // Tap pin button to pin offline
      await tester.tap(find.byIcon(CupertinoIcons.pin));
      await tester.pump();

      // Verify database updated
      final updated = await db.getMediaItem('viewer_pin_toggle');
      expect(updated!.isPinnedOffline, isTrue);
      expect(find.byIcon(CupertinoIcons.pin_fill), findsOneWidget);
    });

    // This code for testing moving media item to trash and popping viewer screen
    testWidgets('MediaViewerScreen moves item to trash on trash icon tap and pops screen', (WidgetTester tester) async {
      // This code for preparing media item to trash
      final now = DateTime.now();
      final item = MediaItem(
        id: 'viewer_trash_test_item',
        filePath: testImageFile.path,
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
      );
      await db.insertMediaItem(item.toCompanion(false));

      // This code for pumping host screen that navigates to viewer
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => CupertinoButton(
              child: const Text('Open Viewer Button'),
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => MediaViewerScreen(item: item),
                  ),
                );
              },
            ),
          ),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();

      // Open viewer
      await tester.tap(find.text('Open Viewer Button'));
      await tester.pumpAndSettle();
      expect(find.byType(MediaViewerScreen), findsOneWidget);

      // Tap trash button
      await tester.tap(find.byIcon(CupertinoIcons.trash));
      await tester.pumpAndSettle();

      // Viewer popped back to host
      expect(find.byType(MediaViewerScreen), findsNothing);
      expect(find.text('Open Viewer Button'), findsOneWidget);

      // Item marked trashed in database
      final updated = await db.getMediaItem('viewer_trash_test_item');
      expect(updated!.isTrashed, isTrue);
    });

    // This code for testing swiping through multiple media items in PageView
    testWidgets('MediaViewerScreen swiping PageView navigates through multi-item list', (WidgetTester tester) async {
      // This code for preparing multiple items
      final now = DateTime.now();
      final item1 = MediaItem(
        id: 'item_page_1',
        filePath: testImageFile.path,
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
      );
      final item2 = MediaItem(
        id: 'item_page_2',
        filePath: testImageFile.path,
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
      );

      // This code for pumping MediaViewerScreen with multiple items
      await tester.pumpWidget(
        buildTestApp(
          child: MediaViewerScreen(item: item1, items: [item1, item2], initialIndex: 0),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initial page index indicator
      expect(find.text('1 of 2'), findsOneWidget);

      // Fling horizontally to advance to page 2
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      // Updated page index indicator
      expect(find.text('2 of 2'), findsOneWidget);
    });

    // This code for testing Exif sheet popup from info toolbar button
    testWidgets('MediaViewerScreen tapping info icon opens ExifInfoSheet modal popup', (WidgetTester tester) async {
      // This code for preparing media item
      final now = DateTime.now();
      final item = MediaItem(
        id: 'viewer_info_popup_item',
        filePath: testImageFile.path,
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
      );

      // This code for pumping viewer
      await tester.pumpWidget(
        buildTestApp(
          child: MediaViewerScreen(item: item),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap info button
      await tester.tap(find.byIcon(CupertinoIcons.info_circle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Assert modal sheet appears
      expect(find.byType(ExifInfoSheet), findsOneWidget);
      expect(find.text('Details & EXIF'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // This code for testing back button popping viewer screen
    testWidgets('MediaViewerScreen tapping back button pops screen', (WidgetTester tester) async {
      final now = DateTime.now();
      final item = MediaItem(
        id: 'viewer_back_pop_item',
        filePath: testImageFile.path,
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => CupertinoButton(
              child: const Text('Root Host Screen'),
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => MediaViewerScreen(item: item),
                  ),
                );
              },
            ),
          ),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();

      // Open viewer
      await tester.tap(find.text('Root Host Screen'));
      await tester.pumpAndSettle();
      expect(find.byType(MediaViewerScreen), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();

      expect(find.byType(MediaViewerScreen), findsNothing);
      expect(find.text('Root Host Screen'), findsOneWidget);
    });

    // This code for verifying ExifInfoSheet metadata presentation
    testWidgets('ExifInfoSheet displays file dimensions, size, and location metadata', (WidgetTester tester) async {
      // This code for preparing media item with location and dimension metadata
      final now = DateTime(2025, 6, 15, 14, 30);
      final item = MediaItem(
        id: 'exif_sheet_item',
        filePath: testImageFile.path,
        mediaType: 'image',
        width: 3840,
        height: 2160,
        fileSize: 4194304, // 4.0 MB
        dateAdded: now,
        dateTaken: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
        latitude: 37.7749,
        longitude: -122.4194,
        locationName: 'San Francisco, USA',
      );

      // This code for pumping ExifInfoSheet
      await tester.pumpWidget(
        buildTestApp(
          child: ExifInfoSheet(item: item),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert header and item metadata
      expect(find.text('Details & EXIF'), findsOneWidget);
      expect(find.text('3840 × 2160 px'), findsOneWidget);
      expect(find.text('4.00 MB'), findsOneWidget);
      expect(find.text('San Francisco, USA'), findsOneWidget);
    });
  });
}
