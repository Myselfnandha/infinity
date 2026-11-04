// This code for comprehensive unit and integration testing of Phase 6 features:
// Perceptual Hashing (dHash & Hamming Distance), Location-Based Search (Haversine & Locality Mapping),
// Multi-File Zip Export (Compression & Collision Deduplication), and Drift Schema v2 SQLite Queries.

import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/media/location_tag_service.dart';
import 'package:infinity/core/media/perceptual_hash_service.dart';
import 'package:infinity/core/storage/zip_export_service.dart';

// This code for providing an isolated in-memory database instance for testing
class TestPhase6Database extends AppDatabase {
  TestPhase6Database() : super.forTesting(NativeDatabase.memory());
}

// This code for generating synthetic test images with gradient patterns
Uint8List _generateGradientImageBytes({int width = 32, int height = 32, int offset = 0, bool reverse = false}) {
  final image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final intensity = reverse
          ? ((width - 1 - x) * 255 ~/ width + offset).clamp(0, 255)
          : (x * 255 ~/ width + offset).clamp(0, 255);
      image.setPixelRgb(x, y, intensity, intensity, intensity);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6: Perceptual Hashing & Duplicate Detection Tests', () {
    test('Hamming distance calculation between identical and differing hashes', () {
      // This code for validating Hamming distance edge cases and popcount arithmetic
      expect(PerceptualHashService.hammingDistance('0000000000000000', '0000000000000000'), equals(0));
      expect(PerceptualHashService.hammingDistance('ffffffffffffffff', 'ffffffffffffffff'), equals(0));
      expect(PerceptualHashService.hammingDistance('0000000000000001', '0000000000000000'), equals(1));
      expect(PerceptualHashService.hammingDistance('0000000000000003', '0000000000000000'), equals(2));
      expect(PerceptualHashService.hammingDistance('ffffffffffffffff', '0000000000000000'), equals(64));

      // Invalid length or malformed hashes return maximum distance 64
      expect(PerceptualHashService.hammingDistance('invalid', '0000000000000000'), equals(64));
    });

    test('isNearDuplicate correctly applies distance threshold', () {
      // This code for checking threshold boundary conditions
      const hashA = '1111222233334444';
      // Same hash: distance 0 <= 10 -> true
      expect(PerceptualHashService.isNearDuplicate(hashA, hashA, threshold: 10), isTrue);

      // Distance 1: near duplicate
      const hashB = '1111222233334445';
      expect(PerceptualHashService.isNearDuplicate(hashA, hashB, threshold: 10), isTrue);

      // Distance 64: distinct
      const hashC = 'eeeebbbbaaaa9999';
      expect(PerceptualHashService.isNearDuplicate(hashA, hashC, threshold: 10), isFalse);
    });

    test('dHash computation produces consistent 16-hex hash from image bytes', () async {
      // This code for validating 64-bit gradient dHash calculation from raw image bytes
      final bytes1 = _generateGradientImageBytes(offset: 0);
      final hash1 = await PerceptualHashService.computeDHashFromBytes(bytes1);

      expect(hash1, isNotNull);
      expect(hash1!.length, equals(16));
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(hash1), isTrue);

      // Identical image produces identical hash (Hamming distance 0)
      final bytes1Duplicate = _generateGradientImageBytes(offset: 0);
      final hash1Duplicate = await PerceptualHashService.computeDHashFromBytes(bytes1Duplicate);
      expect(hash1, equals(hash1Duplicate));
      expect(PerceptualHashService.hammingDistance(hash1, hash1Duplicate!), equals(0));

      // Slightly perturbed image produces small Hamming distance <= 5
      final bytesSlightlyAltered = _generateGradientImageBytes(offset: 4);
      final hashSlightlyAltered = await PerceptualHashService.computeDHashFromBytes(bytesSlightlyAltered);
      expect(hashSlightlyAltered, isNotNull);
      final distAltered = PerceptualHashService.hammingDistance(hash1, hashSlightlyAltered!);
      expect(distAltered, lessThanOrEqualTo(5));

      // Reversed gradient image produces large Hamming distance > 10
      final bytesReversed = _generateGradientImageBytes(reverse: true);
      final hashReversed = await PerceptualHashService.computeDHashFromBytes(bytesReversed);
      expect(hashReversed, isNotNull);
      final distReversed = PerceptualHashService.hammingDistance(hash1, hashReversed!);
      expect(distReversed, greaterThan(10));
    });

    test('findDuplicates groups near-duplicate media items into clusters', () {
      // This code for verifying duplicate clustering logic
      final now = DateTime.now();
      final item1 = MediaItem(
        id: 'img_1',
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        perceptualHash: 'aaaaaaaaaaaaaaaa',
        isPinnedOffline: false,
        cloudState: 'LOCAL_ONLY',
      );

      final item2 = MediaItem(
        id: 'img_2', // 1 bit flip from item1
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        perceptualHash: 'aaaaaaaaaaaaaaab',
        isPinnedOffline: false,
        cloudState: 'LOCAL_ONLY',
      );

      final item3 = MediaItem(
        id: 'img_3', // completely different
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        perceptualHash: '5555555555555555',
        isPinnedOffline: false,
        cloudState: 'LOCAL_ONLY',
      );

      final clusters = PerceptualHashService.findDuplicates([item1, item2, item3], threshold: 10);
      expect(clusters.length, equals(1));
      expect(clusters.first.primary.id, equals('img_1'));
      expect(clusters.first.duplicates.length, equals(1));
      expect(clusters.first.duplicates.first.id, equals('img_2'));
      expect(clusters.first.averageDistance, lessThanOrEqualTo(10));
    });
  });

  group('Phase 6: Location-Based Search & Locality Mapping Tests', () {
    test('calculateDistanceKm computes accurate Haversine distance', () {
      // This code for verifying geodesic spherical distance between Paris and London
      // Paris: (48.8566, 2.3522), London: (51.5074, -0.1278) -> ~343 km
      final dist = LocationTagService.calculateDistanceKm(
        48.8566,
        2.3522,
        51.5074,
        -0.1278,
      );
      expect(dist, inInclusiveRange(335.0, 355.0));

      // Distance between identical coordinates is 0
      final zeroDist = LocationTagService.calculateDistanceKm(37.7749, -122.4194, 37.7749, -122.4194);
      expect(zeroDist, closeTo(0.0, 0.001));
    });

    test('resolveLocalityTag maps GPS coordinates to nearest offline locality', () {
      // This code for verifying offline reverse geocoding to known world localities
      // San Francisco coordinates
      final sf = LocationTagService.resolveLocalityTag(37.7749, -122.4194);
      expect(sf, equals('San Francisco, USA'));

      // Near Tokyo (within 10 km)
      final tokyo = LocationTagService.resolveLocalityTag(35.6895, 139.6917);
      expect(tokyo, equals('Tokyo, Japan'));

      // Near Paris
      final paris = LocationTagService.resolveLocalityTag(48.8584, 2.2945); // Eiffel Tower
      expect(paris, equals('Paris, France'));

      // Null Island in middle of South Atlantic Ocean (no city within 50 km)
      final remoteOcean = LocationTagService.resolveLocalityTag(0.0, 0.0);
      expect(remoteOcean, isNull);
    });

    test('filterByProximity filters media items within specified radius', () {
      // This code for verifying coordinate proximity filtering
      final now = DateTime.now();
      final itemSf = MediaItem(
        id: 'sf_item',
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        latitude: 37.7749,
        longitude: -122.4194,
        locationName: 'San Francisco, USA',
        isPinnedOffline: false,
        cloudState: 'LOCAL_ONLY',
      );

      final itemOakland = MediaItem(
        id: 'oakland_item', // ~15 km from SF
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        latitude: 37.8044,
        longitude: -122.2712,
        locationName: 'San Francisco, USA',
        isPinnedOffline: false,
        cloudState: 'LOCAL_ONLY',
      );

      final itemParis = MediaItem(
        id: 'paris_item',
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        latitude: 48.8566,
        longitude: 2.3522,
        locationName: 'Paris, France',
        isPinnedOffline: false,
        cloudState: 'LOCAL_ONLY',
      );

      final itemNoLoc = MediaItem(
        id: 'noloc_item',
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        isPinnedOffline: false,
        cloudState: 'LOCAL_ONLY',
      );

      // Filter within 25 km of San Francisco
      final results = LocationTagService.filterByProximity(
        [itemSf, itemOakland, itemParis, itemNoLoc],
        targetLat: 37.7749,
        targetLng: -122.4194,
        radiusKm: 25.0,
      );

      expect(results.length, equals(2));
      expect(results.map((i) => i.id), containsAll(['sf_item', 'oakland_item']));
      expect(results.map((i) => i.id), isNot(contains('paris_item')));
      expect(results.map((i) => i.id), isNot(contains('noloc_item')));
    });
  });

  group('Phase 6: Multi-File Zip Export Tests', () {
    late Directory tempTestDir;

    setUp(() async {
      tempTestDir = await Directory.systemTemp.createTemp('infinity_zip_test_');
    });

    tearDown(() async {
      if (await tempTestDir.exists()) {
        await tempTestDir.delete(recursive: true);
      }
    });

    test('createZipFromFiles packs files and preserves uncompressed content', () async {
      // This code for verifying zip archive generation and content integrity
      final file1 = File('${tempTestDir.path}/photo1.txt');
      await file1.writeAsString('Infinity Vault Secret Photo 1');

      final file2 = File('${tempTestDir.path}/photo2.txt');
      await file2.writeAsString('Infinity Vault Secret Photo 2');

      final zipDestination = File('${tempTestDir.path}/bundle.zip');

      final result = await ZipExportService.createZipFromFiles(
        [file1, file2],
        zipDestination,
      );

      expect(result.fileCount, equals(2));
      expect(result.totalBytes, greaterThan(0));
      expect(await zipDestination.exists(), isTrue);

      // Unpack and verify contents with archive ZipDecoder
      final zipBytes = await zipDestination.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      expect(archive.length, equals(2));

      final names = archive.map((e) => e.name).toList();
      expect(names, containsAll(['photo1.txt', 'photo2.txt']));

      final unzippedPhoto1 = archive.firstWhere((e) => e.name == 'photo1.txt');
      expect(String.fromCharCodes(unzippedPhoto1.content as List<int>), equals('Infinity Vault Secret Photo 1'));
    });

    test('createZipFromFiles resolves duplicate filename collisions cleanly', () async {
      // This code for testing filename collision handling when bundling files from different folders
      final subDirA = Directory('${tempTestDir.path}/a')..createSync();
      final subDirB = Directory('${tempTestDir.path}/b')..createSync();

      final fileA = File('${subDirA.path}/image.jpg');
      await fileA.writeAsString('image A');

      final fileB = File('${subDirB.path}/image.jpg');
      await fileB.writeAsString('image B');

      final zipDestination = File('${tempTestDir.path}/collision_bundle.zip');

      final result = await ZipExportService.createZipFromFiles(
        [fileA, fileB],
        zipDestination,
      );

      expect(result.fileCount, equals(2));

      final zipBytes = await zipDestination.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final names = archive.map((e) => e.name).toList();

      expect(names, containsAll(['image.jpg', 'image_1.jpg']));
    });
  });

  group('Phase 6: Drift Database Schema v2 & Location/Duplicate Query Tests', () {
    late TestPhase6Database db;

    setUp(() {
      db = TestPhase6Database();
    });

    tearDown(() async {
      await db.close();
    });

    test('Schema v2 inserts item with coordinates, locality, and perceptualHash', () async {
      // This code for inserting and querying schema v2 columns
      final now = DateTime.now();
      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'v2_media_1',
          filePath: const drift.Value('/vault/photos/paris.jpg'),
          mediaType: 'image',
          fileSize: 2048576,
          dateAdded: now,
          latitude: const drift.Value(48.8566),
          longitude: const drift.Value(2.3522),
          locationName: const drift.Value('Paris, France'),
          perceptualHash: const drift.Value('1a2b3c4d5e6f7081'),
        ),
      );

      final item = await db.getMediaItem('v2_media_1');
      expect(item, isNotNull);
      expect(item!.latitude, closeTo(48.8566, 0.0001));
      expect(item.longitude, closeTo(2.3522, 0.0001));
      expect(item.locationName, equals('Paris, France'));
      expect(item.perceptualHash, equals('1a2b3c4d5e6f7081'));
    });

    test('searchMedia queries by locationName and hasLocation filter', () async {
      // This code for verifying database search predicates by locality and coordinates
      final now = DateTime.now();
      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'loc_tokyo',
          filePath: const drift.Value('/vault/photos/tokyo.jpg'),
          mediaType: 'image',
          fileSize: 1048576,
          dateAdded: now,
          latitude: const drift.Value(35.6762),
          longitude: const drift.Value(139.6503),
          locationName: const drift.Value('Tokyo, Japan'),
        ),
      );

      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'loc_none',
          filePath: const drift.Value('/vault/photos/indoor.jpg'),
          mediaType: 'image',
          fileSize: 1048576,
          dateAdded: now,
        ),
      );

      // Search by location name query
      final tokyoResults = await db.searchMedia(query: 'Tokyo').first;
      expect(tokyoResults.length, equals(1));
      expect(tokyoResults.first.id, equals('loc_tokyo'));

      // Filter by hasLocation: true
      final locationOnly = await db.searchMedia(hasLocation: true).first;
      expect(locationOnly.length, equals(1));
      expect(locationOnly.first.id, equals('loc_tokyo'));
    });

    test('updateLocation and updatePerceptualHash mutate item correctly', () async {
      // This code for verifying database mutations for location and dHash
      final now = DateTime.now();
      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'mutate_item',
          filePath: const drift.Value('/vault/photos/test.jpg'),
          mediaType: 'image',
          fileSize: 500000,
          dateAdded: now,
        ),
      );

      await db.updateLocation('mutate_item', 37.7749, -122.4194, 'San Francisco, USA');
      await db.updatePerceptualHash('mutate_item', 'fedcba9876543210');

      final updated = await db.getMediaItem('mutate_item');
      expect(updated, isNotNull);
      expect(updated!.latitude, closeTo(37.7749, 0.0001));
      expect(updated.locationName, equals('San Francisco, USA'));
      expect(updated.perceptualHash, equals('fedcba9876543210'));
    });

    test('watchDuplicateCandidates streams items with non-null perceptualHash', () async {
      // This code for verifying streaming of duplicate candidates
      final now = DateTime.now();
      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'dup_cand_1',
          filePath: const drift.Value('/vault/photos/dup1.jpg'),
          mediaType: 'image',
          fileSize: 1000,
          dateAdded: now,
          perceptualHash: const drift.Value('1111222233334444'),
        ),
      );

      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: 'dup_cand_none',
          filePath: const drift.Value('/vault/photos/dup2.jpg'),
          mediaType: 'image',
          fileSize: 1000,
          dateAdded: now,
        ),
      );

      final candidates = await db.watchDuplicateCandidates().first;
      expect(candidates.length, equals(1));
      expect(candidates.first.id, equals('dup_cand_1'));
    });
  });
}
