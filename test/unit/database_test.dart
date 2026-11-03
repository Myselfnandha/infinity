// This code for testing SQLite Drift database operations, relations, and trash lifecycle
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
  });
}

