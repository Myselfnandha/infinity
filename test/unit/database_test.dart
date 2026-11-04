// This code for testing SQLite Drift database operations, relations, search queries, and trash lifecycle
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/database/app_database.dart';

// This code for providing an isolated in-memory database instance
class TestAppDatabase extends AppDatabase {
  TestAppDatabase() : super.forTesting(NativeDatabase.memory());
}

void main() {
  group('AppDatabase Tests', () {
    late TestAppDatabase db;

    setUp(() {
      db = TestAppDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('Insert media item and watch favorites stream', () async {
      // This code for inserting a media row and verifying favoriting functionality
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'item_1',
              mediaType: 'image',
              fileSize: 1048576,
              dateAdded: DateTime.now(),
              isFavorite: const drift.Value(true),
            ),
          );

      final favorites = await db.watchFavorites().first;
      expect(favorites.length, equals(1));
      expect(favorites.first.id, equals('item_1'));
      expect(favorites.first.isFavorite, isTrue);
    });

    test('Moving item to trash filters from allMedia and appears in watchTrash', () async {
      // This code for verifying trash lifecycle behavior
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'item_2',
              mediaType: 'image',
              fileSize: 204800,
              dateAdded: DateTime.now(),
              isTrashed: const drift.Value(false),
            ),
          );

      var allMedia = await db.watchAllMedia().first;
      expect(allMedia.any((m) => m.id == 'item_2'), isTrue);

      await db.setTrashed('item_2', true);

      allMedia = await db.watchAllMedia().first;
      expect(allMedia.any((m) => m.id == 'item_2'), isFalse);

      final trash = await db.watchTrash().first;
      expect(trash.any((m) => m.id == 'item_2'), isTrue);

      // Restore from trash
      await db.setTrashed('item_2', false);
      allMedia = await db.watchAllMedia().first;
      expect(allMedia.any((m) => m.id == 'item_2'), isTrue);
    });

    test('watchFiles filters for documents and excludes images and videos', () async {
      // This code for inserting mixed media types and verifying document filtration
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'photo_1',
              mediaType: 'image',
              fileSize: 1000,
              dateAdded: DateTime.now(),
            ),
          );
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'doc_1',
              filePath: const drift.Value('/storage/docs/Contract.pdf'),
              mediaType: 'document',
              fileSize: 50000,
              dateAdded: DateTime.now(),
            ),
          );
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'archive_1',
              filePath: const drift.Value('/storage/docs/Backup.zip'),
              mediaType: 'archive',
              fileSize: 250000,
              dateAdded: DateTime.now(),
            ),
          );

      final files = await db.watchFiles().first;
      expect(files.length, equals(2));
      expect(files.any((f) => f.id == 'doc_1'), isTrue);
      expect(files.any((f) => f.id == 'archive_1'), isTrue);
      expect(files.any((f) => f.id == 'photo_1'), isFalse);
    });

    test('searchMedia correctly applies text query and type predicates', () async {
      // This code for testing dynamic search predicates across media items
      final now = DateTime.now();
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'vacation_sunset',
              filePath: const drift.Value('/camera/sunset_beach.jpg'),
              mediaType: 'image',
              fileSize: 2000000,
              dateAdded: now,
              dateTaken: drift.Value(now.subtract(const Duration(days: 2))),
              isFavorite: const drift.Value(true),
            ),
          );
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'mountain_hike',
              filePath: const drift.Value('/camera/mountain_view.mp4'),
              mediaType: 'video',
              fileSize: 15000000,
              dateAdded: now,
              dateTaken: drift.Value(now.subtract(const Duration(days: 5))),
              isFavorite: const drift.Value(false),
            ),
          );

      // Search by query text
      final queryResults = await db.searchMedia(query: 'sunset').first;
      expect(queryResults.length, equals(1));
      expect(queryResults.first.id, equals('vacation_sunset'));

      // Search by media type
      final videoResults = await db.searchMedia(mediaType: 'video').first;
      expect(videoResults.length, equals(1));
      expect(videoResults.first.id, equals('mountain_hike'));

      // Search by favorite flag
      final favResults = await db.searchMedia(isFavorite: true).first;
      expect(favResults.length, equals(1));
      expect(favResults.first.id, equals('vacation_sunset'));

      // Search with date bounds
      final recentResults = await db.searchMedia(
        startDate: now.subtract(const Duration(days: 3)),
      ).first;
      expect(recentResults.length, equals(1));
      expect(recentResults.first.id, equals('vacation_sunset'));
    });

    test('SyncQueue respects FIFO and priority ordering', () async {
      // This code for testing outbox queue prioritization and sorting
      final now = DateTime.now();
      await db.insertSyncTask(
        SyncQueueCompanion.insert(
          id: 'task_low_priority',
          mediaId: 'item_low',
          taskType: 'upload',
          status: 'pending',
          priority: const drift.Value(0),
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
      );
      await db.insertSyncTask(
        SyncQueueCompanion.insert(
          id: 'task_high_priority',
          mediaId: 'item_high',
          taskType: 'upload',
          status: 'pending',
          priority: const drift.Value(10), // User-initiated upload
          createdAt: now,
        ),
      );

      final pending = await db.watchPendingSyncTasks().first;
      expect(pending.length, equals(2));
      // High priority task should be first despite being created later
      expect(pending.first.id, equals('task_high_priority'));
      expect(pending.last.id, equals('task_low_priority'));
    });

    test('getMediaByHash verifies deduplication detection', () async {
      // This code for testing SHA-256 deduplication lookup
      const sha256 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'existing_item',
              mediaType: 'image',
              fileSize: 1024,
              dateAdded: DateTime.now(),
              sha256Hash: const drift.Value(sha256),
            ),
          );

      final found = await db.getMediaByHash(sha256);
      expect(found, isNotNull);
      expect(found!.id, equals('existing_item'));

      final notFound = await db.getMediaByHash('non_existent_hash');
      expect(notFound, isNull);
    });

    test('insertAlbum, linkMediaToAlbum, and watchMediaForAlbum relations', () async {
      // This code for testing album entity creation and media relation mapping
      await db.insertAlbum(
        AlbumsCompanion.insert(
          id: 'album_vacation',
          title: 'Summer Vacation',
          dateCreated: DateTime.now(),
        ),
      );

      final albums = await db.watchAlbums().first;
      expect(albums.length, equals(1));
      expect(albums.first.title, equals('Summer Vacation'));

      // Insert media item and link to album
      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'photo_beach',
          mediaType: 'image',
          fileSize: 5000,
          dateAdded: DateTime.now(),
        ),
      );
      await db.linkMediaToAlbum('photo_beach', 'album_vacation');

      final albumMedia = await db.watchMediaForAlbum('album_vacation').first;
      expect(albumMedia.length, equals(1));
      expect(albumMedia.first.id, equals('photo_beach'));
    });

    test('updateLocation, updatePerceptualHash, and getImagesWithoutPerceptualHash', () async {
      // This code for testing media metadata updates and perceptual hash queries
      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'photo_locate',
          filePath: const drift.Value('/storage/pic.jpg'),
          mediaType: 'image',
          fileSize: 3000,
          dateAdded: DateTime.now(),
        ),
      );

      final unhashed = await db.getImagesWithoutPerceptualHash();
      expect(unhashed.any((i) => i.id == 'photo_locate'), isTrue);

      await db.updatePerceptualHash('photo_locate', '1010101010101010');
      final unhashedAfter = await db.getImagesWithoutPerceptualHash();
      expect(unhashedAfter.any((i) => i.id == 'photo_locate'), isFalse);

      final duplicateCandidates = await db.watchDuplicateCandidates().first;
      expect(duplicateCandidates.any((i) => i.id == 'photo_locate'), isTrue);

      await db.updateLocation('photo_locate', 40.7128, -74.0060, 'New York, USA');
      final updated = await db.getMediaItem('photo_locate');
      expect(updated!.latitude, closeTo(40.7128, 0.001));
      expect(updated.longitude, closeTo(-74.0060, 0.001));
      expect(updated.locationName, equals('New York, USA'));
    });

    test('setPinnedOffline, setCloudState, and getEvictableCacheItems', () async {
      // This code for testing cache management states and evictable item querying
      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'synced_item',
          filePath: const drift.Value('/cache/synced.jpg'),
          mediaType: 'image',
          fileSize: 4000,
          dateAdded: DateTime.now(),
          syncStatus: const drift.Value('synced'),
        ),
      );

      var evictable = await db.getEvictableCacheItems(10);
      expect(evictable.any((i) => i.id == 'synced_item'), isTrue);

      // Pin offline
      await db.setPinnedOffline('synced_item', true);
      evictable = await db.getEvictableCacheItems(10);
      expect(evictable.any((i) => i.id == 'synced_item'), isFalse);

      // Set cloud state
      await db.setCloudState('synced_item', 'CLOUD_ONLY');
      final item = await db.getMediaItem('synced_item');
      expect(item!.cloudState, equals('CLOUD_ONLY'));
      expect(item.isPinnedOffline, isTrue);
    });

    test('getUnsyncedMedia and updateSyncStatus operations', () async {
      // This code for testing query for unsynced local files and status transitions
      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'unsynced_item',
          mediaType: 'image',
          fileSize: 2000,
          dateAdded: DateTime.now(),
          syncStatus: const drift.Value('local'),
        ),
      );

      final unsynced = await db.getUnsyncedMedia();
      expect(unsynced.any((i) => i.id == 'unsynced_item'), isTrue);

      await db.updateSyncStatus(
        'unsynced_item',
        'synced',
        telegramFileId: 'tg_file_99',
        telegramMessageId: 1234,
        telegramChatId: -100123456,
        telegramTopicId: 101,
      );

      final syncedItem = await db.getMediaItem('unsynced_item');
      expect(syncedItem!.syncStatus, equals('synced'));
      expect(syncedItem.telegramFileId, equals('tg_file_99'));
      expect(syncedItem.telegramMessageId, equals(1234));
      expect(syncedItem.telegramChatId, equals(-100123456));
      expect(syncedItem.telegramTopicId, equals(101));
    });

    test('deleteSyncTask and updateTaskStatus', () async {
      // This code for testing sync task updates, retries, and task deletion
      await db.insertSyncTask(
        SyncQueueCompanion.insert(
          id: 'task_to_update',
          mediaId: 'item_x',
          taskType: 'upload',
          status: 'pending',
          createdAt: DateTime.now(),
        ),
      );

      await db.updateTaskStatus(
        'task_to_update',
        'failed',
        errorMessage: 'Network timeout',
        progress: 0.5,
        retryCount: 1,
      );

      var tasks = await db.watchPendingSyncTasks().first;
      expect(tasks.any((t) => t.id == 'task_to_update'), isFalse); // only 'pending'/'inProgress'

      final deletedCount = await db.deleteSyncTask('task_to_update');
      expect(deletedCount, equals(1));
    });

    test('searchMedia filters by files type, offline pin, location presence, and endDate', () async {
      // This code for testing comprehensive searchMedia filter combination
      final pastDate = DateTime(2025, 1, 10);
      final futureDate = DateTime(2025, 12, 10);

      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'doc_contract',
          mediaType: 'document',
          fileSize: 5000,
          dateAdded: pastDate,
          isPinnedOffline: const drift.Value(true),
          latitude: const drift.Value(37.7749),
          longitude: const drift.Value(-122.4194),
          locationName: const drift.Value('San Francisco, USA'),
        ),
      );

      // Filter by mediaType: files
      final fileResults = await db.searchMedia(mediaType: 'files').first;
      expect(fileResults.any((m) => m.id == 'doc_contract'), isTrue);

      // Filter by isPinnedOffline: true
      final pinnedResults = await db.searchMedia(isPinnedOffline: true).first;
      expect(pinnedResults.any((m) => m.id == 'doc_contract'), isTrue);

      // Filter by hasLocation: true
      final locationResults = await db.searchMedia(hasLocation: true).first;
      expect(locationResults.any((m) => m.id == 'doc_contract'), isTrue);

      // Filter by endDate before pastDate should yield empty
      final emptyResults = await db.searchMedia(endDate: pastDate.subtract(const Duration(days: 1))).first;
      expect(emptyResults.any((m) => m.id == 'doc_contract'), isFalse);

      // Filter by endDate after pastDate should yield item
      final validEndResults = await db.searchMedia(endDate: futureDate).first;
      expect(validEndResults.any((m) => m.id == 'doc_contract'), isTrue);
    });
  });
}
