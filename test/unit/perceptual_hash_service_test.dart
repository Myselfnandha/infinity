// This code for comprehensive unit testing of PerceptualHashService, 64-bit dHash computation, clustering, and database backfilling
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/media/perceptual_hash_service.dart';

// This code for providing an isolated in-memory SQLite database instance
class TestAppDatabase extends AppDatabase {
  TestAppDatabase() : super.forTesting(NativeDatabase.memory());
}

// This code for executing PerceptualHashService unit tests
void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping PerceptualHashService unit tests
  group('PerceptualHashService Unit Tests', () {
    late Directory tempDir;
    late TestAppDatabase db;

    setUp(() async {
      // This code for initializing temporary test directory and database
      tempDir = await Directory.systemTemp.createTemp('phash_test_');
      db = TestAppDatabase();
    });

    tearDown(() async {
      // This code for cleaning up test database and temporary directory
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    // This code for testing computeDHash with existing and non-existing image files
    test('computeDHash computes valid 16-hex hash for image file and handles missing/corrupt files', () async {
      // This code for verifying non-existent file returns null
      final missingHash = await PerceptualHashService.computeDHash('${tempDir.path}/nonexistent.jpg');
      expect(missingHash, isNull);

      // This code for verifying corrupt file returns null
      final corruptFile = File('${tempDir.path}/corrupt.jpg')..writeAsBytesSync([0x00, 0x11, 0x22]);
      final corruptHash = await PerceptualHashService.computeDHash(corruptFile.path);
      expect(corruptHash, isNull);

      // This code for generating valid image file on disk
      final image = img.Image(width: 32, height: 32);
      for (int y = 0; y < 32; y++) {
        for (int x = 0; x < 32; x++) {
          image.setPixelRgb(x, y, x * 7, y * 7, (x + y) * 3);
        }
      }
      final validFile = File('${tempDir.path}/valid.png')..writeAsBytesSync(img.encodePng(image));

      // This code for calculating dHash from file path
      final validHash = await PerceptualHashService.computeDHash(validFile.path);
      expect(validHash, isNotNull);
      expect(validHash!.length, equals(16));
      expect(RegExp(r'^[0-9a-fA-F]{16}$').hasMatch(validHash), isTrue);
    });

    // This code for testing computeDHashSync and computeDHashFromBytes
    test('computeDHashSync and computeDHashFromBytes compute deterministic 16-hex hash', () async {
      // This code for creating test pattern image
      final image = img.Image(width: 32, height: 32);
      img.fill(image, color: img.ColorRgb8(100, 150, 200));
      final bytes = img.encodePng(image);

      final hashAsync = await PerceptualHashService.computeDHashFromBytes(bytes);
      final hashSync = PerceptualHashService.computeDHashSync(bytes);

      expect(hashAsync, isNotNull);
      expect(hashSync, isNotNull);
      expect(hashAsync, equals(hashSync));
      expect(hashAsync!.length, equals(16));
    });

    // This code for testing hammingDistance calculation
    test('hammingDistance measures bit variance and guards against invalid inputs', () {
      // This code for testing identical hashes
      expect(PerceptualHashService.hammingDistance('ffff0000ffff0000', 'ffff0000ffff0000'), equals(0));

      // This code for testing known 1-bit difference
      expect(PerceptualHashService.hammingDistance('0000000000000000', '0000000000000001'), equals(1));

      // This code for testing invalid length inputs returning 64
      expect(PerceptualHashService.hammingDistance('short', 'ffff0000ffff0000'), equals(64));

      // This code for testing invalid non-hex characters returning 64
      expect(PerceptualHashService.hammingDistance('zzzzzzzzzzzzzzzz', 'ffff0000ffff0000'), equals(64));
    });

    // This code for testing isNearDuplicate and degenerate flat-hash guard
    test('isNearDuplicate detects duplicates and rejects all-zero flat hashes', () {
      // Similar hashes within threshold
      expect(
        PerceptualHashService.isNearDuplicate('1234567890abcdef', '1234567890abcdee', threshold: 10),
        isTrue,
      );

      // Dissimilar hashes
      expect(
        PerceptualHashService.isNearDuplicate('0000000000000000', 'ffffffffffffffff', threshold: 10),
        isFalse,
      );

      // Degenerate all-zero flat hashes must return false
      expect(
        PerceptualHashService.isNearDuplicate('0000000000000000', '0000000000000000'),
        isFalse,
      );
    });

    // This code for testing findDuplicates clustering
    test('findDuplicates clusters matching items and computes average distance', () {
      final now = DateTime.now();
      final itemA1 = MediaItem(
        id: 'item_a1',
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        cloudState: 'LOCAL_ONLY',
        isPinnedOffline: false,
        perceptualHash: '1234567890abcdef',
      );
      final itemA2 = MediaItem(
        id: 'item_a2',
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        cloudState: 'LOCAL_ONLY',
        isPinnedOffline: false,
        perceptualHash: '1234567890abcdee', // 1 bit diff
      );
      final itemB = MediaItem(
        id: 'item_b',
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        cloudState: 'LOCAL_ONLY',
        isPinnedOffline: false,
        perceptualHash: 'ffffffff00000000', // far away
      );
      final itemFlat = MediaItem(
        id: 'item_flat',
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        cloudState: 'LOCAL_ONLY',
        isPinnedOffline: false,
        perceptualHash: '0000000000000000', // flat zero hash
      );

      final clusters = PerceptualHashService.findDuplicates([itemA1, itemA2, itemB, itemFlat]);
      expect(clusters.length, equals(1));
      expect(clusters.first.primary.id, equals('item_a1'));
      expect(clusters.first.duplicates.length, equals(1));
      expect(clusters.first.duplicates.first.id, equals('item_a2'));
      expect(clusters.first.averageDistance, equals(1));
    });

    // This code for testing backfillMissingHashes database integration
    test('backfillMissingHashes computes and updates perceptualHash for unhashed media items', () async {
      // This code for creating valid image file on disk
      final image = img.Image(width: 32, height: 32);
      img.fill(image, color: img.ColorRgb8(200, 50, 100));
      final testFile = File('${tempDir.path}/backfill_image.png')..writeAsBytesSync(img.encodePng(image));

      // This code for inserting image item without hash into database
      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'unhashed_item_1',
          filePath: drift.Value(testFile.path),
          mediaType: 'image',
          fileSize: testFile.lengthSync(),
          dateAdded: DateTime.now(),
        ),
      );

      // This code for verifying item currently has null perceptualHash
      var itemBefore = await db.getMediaItem('unhashed_item_1');
      expect(itemBefore!.perceptualHash, isNull);

      // This code for running backfill operation
      final count = await PerceptualHashService.backfillMissingHashes(db);
      expect(count, equals(1));

      // This code for verifying item now has computed perceptualHash in database
      var itemAfter = await db.getMediaItem('unhashed_item_1');
      expect(itemAfter!.perceptualHash, isNotNull);
      expect(itemAfter.perceptualHash!.length, equals(16));

      // Subsequent backfill run finds 0 unhashed items
      final countSecond = await PerceptualHashService.backfillMissingHashes(db);
      expect(countSecond, equals(0));
    });
  });
}
