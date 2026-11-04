// This code for testing cloud media cache management, LRU eviction policies, storage calculation, and offline pinning
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/core/storage/cloud_media_cache_manager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This code for mocking path_provider to use an isolated temporary test directory
class FakePathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String path;
  FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

// This code for isolating database in-memory for cache manager tests
class TestAppDatabase extends AppDatabase {
  TestAppDatabase() : super.forTesting(NativeDatabase.memory());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CloudMediaCacheManager Unit Tests', () {
    late Directory tempDir;
    late Directory mediaCacheDir;
    late TestAppDatabase db;
    late SharedPreferences prefsInstance;
    late AppPreferences prefs;
    late CloudMediaCacheManager cacheManager;

    setUp(() async {
      // This code for creating isolated temporary directories and mock preferences
      tempDir = Directory.systemTemp.createTempSync('infinity_cache_test_');
      mediaCacheDir = Directory('${tempDir.path}/media_cache')..createSync(recursive: true);
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

      db = TestAppDatabase();
      SharedPreferences.setMockInitialValues({
        'cache_limit_mb': 10, // 10 MB limit for testing
      });
      prefsInstance = await SharedPreferences.getInstance();
      prefs = AppPreferences(prefsInstance);
      cacheManager = CloudMediaCacheManager(db, prefs);
    });

    tearDown(() async {
      // This code for releasing database and cleaning up file system fixtures
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('1. calculateCacheSizeBytes correctly sums all files in the cache directory', () async {
      // This code for creating fixture files and verifying accurate size computation
      final file1 = File('${mediaCacheDir.path}/img_1.jpg');
      final file2 = File('${mediaCacheDir.path}/img_2.jpg');
      await file1.writeAsBytes(List.filled(1024 * 500, 1)); // 500 KB
      await file2.writeAsBytes(List.filled(1024 * 700, 2)); // 700 KB

      final totalBytes = await cacheManager.calculateCacheSizeBytes();
      expect(totalBytes, equals(1024 * 1200));
    });

    test('2. enforceCacheLimits does not evict any files when usage is below limit', () async {
      // This code for confirming no evictions occur when storage stays within limits
      final file = File('${mediaCacheDir.path}/safe.jpg');
      await file.writeAsBytes(List.filled(1024 * 1024, 1)); // 1 MB (limit is 10 MB)

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'item_safe',
              mediaType: 'image',
              fileSize: 1024 * 1024,
              dateAdded: DateTime.now(),
              filePath: drift.Value(file.path),
              syncStatus: const drift.Value('synced'),
              cloudState: const drift.Value('AVAILABLE_LOCALLY'),
            ),
          );

      final evictedBytes = await cacheManager.enforceCacheLimits();
      expect(evictedBytes, equals(0));
      expect(file.existsSync(), isTrue);
    });

    test('3. enforceCacheLimits evicts oldest unpinned files when limit is exceeded', () async {
      // This code for creating files that exceed the 10 MB limit (e.g. 12 MB) and verifying LRU eviction
      final oldFile = File('${mediaCacheDir.path}/old.jpg');
      final newFile = File('${mediaCacheDir.path}/new.jpg');
      await oldFile.writeAsBytes(List.filled(1024 * 1024 * 6, 1)); // 6 MB
      await newFile.writeAsBytes(List.filled(1024 * 1024 * 6, 2)); // 6 MB (Total 12 MB > 10 MB)

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'item_old',
              mediaType: 'image',
              fileSize: 1024 * 1024 * 6,
              dateAdded: DateTime.now().subtract(const Duration(days: 2)),
              filePath: drift.Value(oldFile.path),
              syncStatus: const drift.Value('synced'),
              cloudState: const drift.Value('AVAILABLE_LOCALLY'),
            ),
          );

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'item_new',
              mediaType: 'image',
              fileSize: 1024 * 1024 * 6,
              dateAdded: DateTime.now(),
              filePath: drift.Value(newFile.path),
              syncStatus: const drift.Value('synced'),
              cloudState: const drift.Value('AVAILABLE_LOCALLY'),
            ),
          );

      final evictedBytes = await cacheManager.enforceCacheLimits();
      expect(evictedBytes, equals(1024 * 1024 * 6));
      expect(oldFile.existsSync(), isFalse);
      expect(newFile.existsSync(), isTrue);
    });

    test('4. enforceCacheLimits updates database state to CLOUD_ONLY and clears filePath', () async {
      // This code for verifying database row mutation after file eviction
      final file = File('${mediaCacheDir.path}/evict_me.jpg');
      await file.writeAsBytes(List.filled(1024 * 1024 * 12, 1)); // 12 MB

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'item_evict',
              mediaType: 'image',
              fileSize: 1024 * 1024 * 12,
              dateAdded: DateTime.now(),
              filePath: drift.Value(file.path),
              syncStatus: const drift.Value('synced'),
              cloudState: const drift.Value('AVAILABLE_LOCALLY'),
            ),
          );

      await cacheManager.enforceCacheLimits();

      final updated = await db.getMediaItem('item_evict');
      expect(updated, isNotNull);
      expect(updated!.filePath, isNull);
      expect(updated.cloudState, equals('CLOUD_ONLY'));
    });

    test('5. enforceCacheLimits protects pinned files from eviction even when over budget', () async {
      // This code for asserting that isPinnedOffline == true shields media from LRU purge
      final pinnedFile = File('${mediaCacheDir.path}/pinned.jpg');
      await pinnedFile.writeAsBytes(List.filled(1024 * 1024 * 15, 1)); // 15 MB > 10 MB

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'item_pinned',
              mediaType: 'image',
              fileSize: 1024 * 1024 * 15,
              dateAdded: DateTime.now().subtract(const Duration(days: 10)),
              filePath: drift.Value(pinnedFile.path),
              syncStatus: const drift.Value('synced'),
              cloudState: const drift.Value('AVAILABLE_LOCALLY'),
              isPinnedOffline: const drift.Value(true),
            ),
          );

      final evictedBytes = await cacheManager.enforceCacheLimits();
      expect(evictedBytes, equals(0));
      expect(pinnedFile.existsSync(), isTrue);
    });

    test('6. enforceCacheLimits protects unsynced local media from eviction', () async {
      // This code for asserting local un-synced files are never evicted before reaching Telegram
      final unsyncedFile = File('${mediaCacheDir.path}/unsynced.jpg');
      await unsyncedFile.writeAsBytes(List.filled(1024 * 1024 * 15, 1)); // 15 MB > 10 MB

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'item_unsynced',
              mediaType: 'image',
              fileSize: 1024 * 1024 * 15,
              dateAdded: DateTime.now().subtract(const Duration(days: 5)),
              filePath: drift.Value(unsyncedFile.path),
              syncStatus: const drift.Value('local'),
              cloudState: const drift.Value('LOCAL_ONLY'),
            ),
          );

      final evictedBytes = await cacheManager.enforceCacheLimits();
      expect(evictedBytes, equals(0));
      expect(unsyncedFile.existsSync(), isTrue);
    });

    test('7. freeUpDeviceSpace purges all synced unpinned files to immediately recover space', () async {
      // This code for testing manual "Free up space" feature on synced media
      final syncedFile1 = File('${mediaCacheDir.path}/synced1.jpg');
      final syncedFile2 = File('${mediaCacheDir.path}/synced2.jpg');
      await syncedFile1.writeAsBytes(List.filled(1024 * 1024 * 2, 1)); // 2 MB
      await syncedFile2.writeAsBytes(List.filled(1024 * 1024 * 3, 2)); // 3 MB

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'item_sync_1',
              mediaType: 'image',
              fileSize: 1024 * 1024 * 2,
              dateAdded: DateTime.now(),
              filePath: drift.Value(syncedFile1.path),
              syncStatus: const drift.Value('synced'),
              cloudState: const drift.Value('AVAILABLE_LOCALLY'),
            ),
          );

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'item_sync_2',
              mediaType: 'image',
              fileSize: 1024 * 1024 * 3,
              dateAdded: DateTime.now(),
              filePath: drift.Value(syncedFile2.path),
              syncStatus: const drift.Value('synced'),
              cloudState: const drift.Value('AVAILABLE_LOCALLY'),
            ),
          );

      final freedBytes = await cacheManager.freeUpDeviceSpace();
      expect(freedBytes, equals(1024 * 1024 * 5));
      expect(syncedFile1.existsSync(), isFalse);
      expect(syncedFile2.existsSync(), isFalse);

      final item1 = await db.getMediaItem('item_sync_1');
      final item2 = await db.getMediaItem('item_sync_2');
      expect(item1!.filePath, isNull);
      expect(item1.cloudState, equals('CLOUD_ONLY'));
      expect(item2!.filePath, isNull);
      expect(item2.cloudState, equals('CLOUD_ONLY'));
    });

    test('8. togglePinOffline updates database pin status', () async {
      // This code for verifying toggle pin offline state persistence
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'pin_toggle_item',
              mediaType: 'image',
              fileSize: 1024,
              dateAdded: DateTime.now(),
              isPinnedOffline: const drift.Value(false),
            ),
          );

      await cacheManager.togglePinOffline('pin_toggle_item', true);
      var item = await db.getMediaItem('pin_toggle_item');
      expect(item!.isPinnedOffline, isTrue);

      await cacheManager.togglePinOffline('pin_toggle_item', false);
      item = await db.getMediaItem('pin_toggle_item');
      expect(item!.isPinnedOffline, isFalse);
    });
  });
}
