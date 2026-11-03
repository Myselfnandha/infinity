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
  });
}
