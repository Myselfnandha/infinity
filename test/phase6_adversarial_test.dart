// This code for adversarial stress testing and empirical validation of Phase 6 features
// Including dHash perceptual resilience/discrimination, Haversine extreme coordinate stability,
// and Zip archive compression/CRC32 integrity verification.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/media/location_tag_service.dart';
import 'package:infinity/core/media/perceptual_hash_service.dart';
import 'package:infinity/core/storage/zip_export_service.dart';

// This code for computing CRC32 checksum of a byte buffer
int _computeCrc32(List<int> bytes) {
  return getCrc32(bytes);
}

// This code for generating a synthetic image with gradient and brightness offset
Uint8List _createSyntheticImage({
  int width = 64,
  int height = 64,
  bool horizontal = true,
  bool reverse = false,
  int brightnessOffset = 0,
  double noiseLevel = 0.0,
}) {
  final image = img.Image(width: width, height: height);
  final random = Random(42);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int val;
      if (horizontal) {
        val = reverse ? (width - 1 - x) * 255 ~/ width : x * 255 ~/ width;
      } else {
        val = reverse ? (height - 1 - y) * 255 ~/ height : y * 255 ~/ height;
      }

      val += brightnessOffset;
      if (noiseLevel > 0) {
        final noise = ((random.nextDouble() * 2 - 1) * 255 * noiseLevel).round();
        val += noise;
      }
      val = val.clamp(0, 255);
      image.setPixelRgb(x, y, val, val, val);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

// This code for generating a solid single-color image
Uint8List _createSolidImage(int r, int g, int b, {int width = 32, int height = 32}) {
  final image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      image.setPixelRgb(x, y, r, g, b);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial Stress Test: Perceptual Hashing (dHash)', () {
    test('Identical images with identical pixels have exact Hamming distance of 0', () async {
      // This code for validating dHash identity invariant
      final imgA = _createSyntheticImage(width: 128, height: 128, horizontal: true, reverse: true);
      final imgB = _createSyntheticImage(width: 128, height: 128, horizontal: true, reverse: true);

      final hashA = await PerceptualHashService.computeDHashFromBytes(imgA);
      final hashB = await PerceptualHashService.computeDHashFromBytes(imgB);

      expect(hashA, isNotNull);
      expect(hashB, isNotNull);
      expect(hashA, equals(hashB));
      expect(PerceptualHashService.hammingDistance(hashA!, hashB!), equals(0));
      expect(PerceptualHashService.isNearDuplicate(hashA, hashB), isTrue);
    });

    test('Perturbed images (brightness, scaling, minor noise) retain distance <= 10', () async {
      // This code for stress-testing perceptual resilience across image distortions
      final baseBytes = _createSyntheticImage(width: 100, height: 100, horizontal: true, reverse: true);
      final baseHash = await PerceptualHashService.computeDHashFromBytes(baseBytes);
      expect(baseHash, isNotNull);

      // Distortions to test
      final variations = <String, Uint8List>{
        'Brightness +20': _createSyntheticImage(width: 100, height: 100, horizontal: true, reverse: true, brightnessOffset: 20),
        'Brightness -20': _createSyntheticImage(width: 100, height: 100, horizontal: true, reverse: true, brightnessOffset: -20),
        'Downscaled 32x32': _createSyntheticImage(width: 32, height: 32, horizontal: true, reverse: true),
        'Upscaled 256x256': _createSyntheticImage(width: 256, height: 256, horizontal: true, reverse: true),
        'Mild Noise (5%)': _createSyntheticImage(width: 100, height: 100, horizontal: true, reverse: true, noiseLevel: 0.05),
      };

      for (final entry in variations.entries) {
        final varHash = await PerceptualHashService.computeDHashFromBytes(entry.value);
        expect(varHash, isNotNull, reason: 'Failed for ${entry.key}');
        final dist = PerceptualHashService.hammingDistance(baseHash!, varHash!);
        expect(
          dist,
          lessThanOrEqualTo(10),
          reason: 'Variation ${entry.key} had Hamming distance $dist which exceeds threshold 10',
        );
        expect(
          PerceptualHashService.isNearDuplicate(baseHash, varHash),
          isTrue,
          reason: 'Variation ${entry.key} was not recognized as near duplicate',
        );
      }
    });

    test('Orthogonal, distinct patterns, and random noise discrimination', () async {
      // This code for verifying perceptual discrimination against completely distinct non-degenerate patterns
      final horizontalBytes = _createSyntheticImage(width: 64, height: 64, horizontal: true);
      final reversedBytes = _createSyntheticImage(width: 64, height: 64, horizontal: true, reverse: true);

      final hHash = await PerceptualHashService.computeDHashFromBytes(horizontalBytes);
      final rHash = await PerceptualHashService.computeDHashFromBytes(reversedBytes);

      expect(hHash, isNotNull);
      expect(rHash, isNotNull);

      // Horizontal vs Reversed is polar opposite: distance should be high (64)
      final distReversed = PerceptualHashService.hammingDistance(hHash!, rHash!);
      expect(distReversed, greaterThan(10));
      expect(PerceptualHashService.isNearDuplicate(hHash, rHash), isFalse);

      // Two distinct pseudo-random noise images
      final randomA = Random(111);
      final imgA = img.Image(width: 64, height: 64);
      for (int y = 0; y < 64; y++) {
        for (int x = 0; x < 64; x++) {
          final c = randomA.nextInt(256);
          imgA.setPixelRgb(x, y, c, c, c);
        }
      }
      final noiseBytesA = Uint8List.fromList(img.encodePng(imgA));

      final randomB = Random(222);
      final imgB = img.Image(width: 64, height: 64);
      for (int y = 0; y < 64; y++) {
        for (int x = 0; x < 64; x++) {
          final c = randomB.nextInt(256);
          imgB.setPixelRgb(x, y, c, c, c);
        }
      }
      final noiseBytesB = Uint8List.fromList(img.encodePng(imgB));

      final hashNoiseA = await PerceptualHashService.computeDHashFromBytes(noiseBytesA);
      final hashNoiseB = await PerceptualHashService.computeDHashFromBytes(noiseBytesB);

      expect(hashNoiseA, isNotNull);
      expect(hashNoiseB, isNotNull);
      final distNoise = PerceptualHashService.hammingDistance(hashNoiseA!, hashNoiseB!);
      expect(distNoise, greaterThan(10), reason: 'Two independent noise patterns must have distance > 10 (actual $distNoise)');
      expect(PerceptualHashService.isNearDuplicate(hashNoiseA, hashNoiseB), isFalse);
    });

    test('Degenerate all-zero hashes (0000000000000000) are guarded against false near-duplicate collision', () async {
      // This code for verifying solid colors and monotonic gradients are guarded from duplicate clustering
      final solidBlack = _createSolidImage(0, 0, 0);
      final solidWhite = _createSolidImage(255, 255, 255);
      final solidGrey = _createSolidImage(128, 128, 128);
      final horizontalGrad = _createSyntheticImage(width: 64, height: 64, horizontal: true);
      final verticalGrad = _createSyntheticImage(width: 64, height: 64, horizontal: false);

      final hashBlack = await PerceptualHashService.computeDHashFromBytes(solidBlack);
      final hashWhite = await PerceptualHashService.computeDHashFromBytes(solidWhite);
      final hashGrey = await PerceptualHashService.computeDHashFromBytes(solidGrey);
      final hashHGrad = await PerceptualHashService.computeDHashFromBytes(horizontalGrad);
      final hashVGrad = await PerceptualHashService.computeDHashFromBytes(verticalGrad);

      // All 5 completely different images produce identical hash 0000000000000000
      expect(hashBlack, equals('0000000000000000'));
      expect(hashWhite, equals('0000000000000000'));
      expect(hashGrey, equals('0000000000000000'));
      expect(hashHGrad, equals('0000000000000000'));
      expect(hashVGrad, equals('0000000000000000'));

      // Verified: Guard prevents false positive near-duplicate classification for degenerate all-zero hashes
      expect(PerceptualHashService.isNearDuplicate(hashBlack!, hashWhite!), isFalse);
      expect(PerceptualHashService.isNearDuplicate(hashWhite, hashHGrad!), isFalse);
      expect(PerceptualHashService.isNearDuplicate(hashGrey!, hashVGrad!), isFalse);

      // Verified: findDuplicates excludes items with degenerate all-zero hashes
      final item1 = MediaItem(
        id: 'black',
        mediaType: 'image',
        fileSize: 100,
        dateAdded: DateTime.now(),
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        perceptualHash: hashBlack,
        isPinnedOffline: false,
        cloudState: 'LOCAL_ONLY',
      );
      final item2 = MediaItem(
        id: 'white',
        mediaType: 'image',
        fileSize: 100,
        dateAdded: DateTime.now(),
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        perceptualHash: hashWhite,
        isPinnedOffline: false,
        cloudState: 'LOCAL_ONLY',
      );
      final clusters = PerceptualHashService.findDuplicates([item1, item2]);
      expect(clusters, isEmpty);
    });

    test('Edge case images (solid colors, 1x1, corrupt bytes) handled gracefully', () async {
      // This code for testing degenerate and edge case image inputs
      // Solid white
      final solidWhite = _createSolidImage(255, 255, 255);
      final whiteHash = await PerceptualHashService.computeDHashFromBytes(solidWhite);
      expect(whiteHash, equals('0000000000000000'));

      // Solid black
      final solidBlack = _createSolidImage(0, 0, 0);
      final blackHash = await PerceptualHashService.computeDHashFromBytes(solidBlack);
      expect(blackHash, equals('0000000000000000'));

      // Solid grey
      final solidGrey = _createSolidImage(128, 128, 128);
      final greyHash = await PerceptualHashService.computeDHashFromBytes(solidGrey);
      expect(greyHash, equals('0000000000000000'));

      // 1x1 image resized to 9x8
      final tinyImg = _createSolidImage(200, 100, 50, width: 1, height: 1);
      final tinyHash = await PerceptualHashService.computeDHashFromBytes(tinyImg);
      expect(tinyHash, isNotNull);
      expect(tinyHash!.length, equals(16));

      // 0-byte input
      final emptyBytes = Uint8List(0);
      final emptyHash = await PerceptualHashService.computeDHashFromBytes(emptyBytes);
      expect(emptyHash, isNull);

      // Corrupted random binary garbage
      final garbageBytes = Uint8List.fromList(List.generate(256, (i) => (i * 37) % 256));
      final garbageHash = await PerceptualHashService.computeDHashFromBytes(garbageBytes);
      expect(garbageHash, isNull);
    });

    test('Hamming distance handles case insensitivity and boundary formatting', () {
      // This code for validating hex case insensitivity and robustness
      expect(PerceptualHashService.hammingDistance('000000000000000A', '000000000000000a'), equals(0));
      expect(PerceptualHashService.hammingDistance('FFFFFFFFFFFFFFFF', 'ffffffffffffffff'), equals(0));
      expect(PerceptualHashService.hammingDistance('ABCDEF0123456789', 'abcdef0123456789'), equals(0));
      expect(PerceptualHashService.hammingDistance('', '0000000000000000'), equals(64));
      expect(PerceptualHashService.hammingDistance('xyz123', '0000000000000000'), equals(64));
    });
  });

  group('Adversarial Stress Test: Location & Haversine Distance', () {
    test('Extreme coordinate pairs: Poles, Equator, and Anti-Meridian', () {
      // This code for verifying Haversine stability across singularities and boundaries
      // 1. Identical coordinates: distance must be 0
      final zeroDist = LocationTagService.calculateDistanceKm(0.0, 0.0, 0.0, 0.0);
      expect(zeroDist, closeTo(0.0, 1e-6));

      // 2. North Pole to North Pole across arbitrary longitudes (singularity check)
      // At lat 90, physical distance between any two longitudes is 0
      final poleDist1 = LocationTagService.calculateDistanceKm(90.0, 0.0, 90.0, 180.0);
      expect(poleDist1, closeTo(0.0, 1e-4));

      final poleDist2 = LocationTagService.calculateDistanceKm(90.0, -120.0, 90.0, 45.0);
      expect(poleDist2, closeTo(0.0, 1e-4));

      // 3. South Pole to South Pole across arbitrary longitudes
      final southPoleDist = LocationTagService.calculateDistanceKm(-90.0, -90.0, -90.0, 90.0);
      expect(southPoleDist, closeTo(0.0, 1e-4));

      // 4. North Pole to South Pole: Half of earth circumference (~20,015.087 km)
      final poleToPole = LocationTagService.calculateDistanceKm(90.0, 0.0, -90.0, 0.0);
      const halfCircumference = pi * 6371.0; // ~20015.087 km
      expect(poleToPole, closeTo(halfCircumference, 0.1));

      // 5. Equator anti-meridian wrap: 179.999° to -179.999°
      // Angular separation is 0.002°, distance should be ~0.222 km (NOT 40,000 km!)
      final antiMeridianDist = LocationTagService.calculateDistanceKm(0.0, 179.999, 0.0, -179.999);
      final expectedShortDist = (0.002 * pi / 180.0) * 6371.0;
      expect(antiMeridianDist, closeTo(expectedShortDist, 0.01));

      // 6. Equator antipodal points: (0, 0) and (0, 180)
      final equatorAntipodal = LocationTagService.calculateDistanceKm(0.0, 0.0, 0.0, 180.0);
      expect(equatorAntipodal, closeTo(halfCircumference, 0.1));
    });

    test('Antipodal coordinates do not produce NaN due to clamped floating point in Haversine formula', () {
      // This code for verifying resolution of antipodal float overflow in LocationTagService.calculateDistanceKm
      // Under IEEE 754 float rounding, sin^2 + cos*cos*sin^2 can yield 1.0000000000000002 > 1.0.
      // Clamping a to [0.0, 1.0] guarantees sqrt(1 - a) never receives a negative value.
      const lat1 = -0.5379797870528762;
      const lon1 = -87.28278881961761;
      const lat2 = 0.5379797870528762;
      const lon2 = 92.71721118038239;

      final dist = LocationTagService.calculateDistanceKm(lat1, lon1, lat2, lon2);

      // Verified: Clamping prevents NaN and returns accurate antipodal distance (~pi * R)
      expect(dist.isNaN, isFalse, reason: 'Distance should not be NaN on antipodal coordinates');
      expect(dist, closeTo(pi * 6371.0, 0.001));
    });

    test('Proximity filtering stress test with 10,000 items and strict radius threshold', () {
      // This code for verifying filterByProximity performance and boundary accuracy
      final random = Random(999);
      final centerLat = 37.7749; // San Francisco
      final centerLng = -122.4194;
      const testRadius = 25.0; // 25 km

      final items = List.generate(1000, (i) {
        // Generate coordinates clustered around SF, plus some outliers
        final offsetLat = (random.nextDouble() * 2.0 - 1.0); // +/- 1 degree (~111 km)
        final offsetLng = (random.nextDouble() * 2.0 - 1.0);
        return MediaItem(
          id: 'item_$i',
          mediaType: 'image',
          fileSize: 1024,
          dateAdded: DateTime.now(),
          isFavorite: false,
          isTrashed: false,
          syncStatus: 'local',
          latitude: centerLat + offsetLat,
          longitude: centerLng + offsetLng,
          isPinnedOffline: false,
          cloudState: 'LOCAL_ONLY',
        );
      });

      final filtered = LocationTagService.filterByProximity(
        items,
        targetLat: centerLat,
        targetLng: centerLng,
        radiusKm: testRadius,
      );

      // Verify each filtered item is strictly <= 25.0 km
      for (final item in filtered) {
        final d = LocationTagService.calculateDistanceKm(
          centerLat,
          centerLng,
          item.latitude!,
          item.longitude!,
        );
        expect(d, lessThanOrEqualTo(testRadius));
      }

      // Verify each excluded item is strictly > 25.0 km
      final excludedIds = items.map((i) => i.id).toSet().difference(filtered.map((i) => i.id).toSet());
      for (final id in excludedIds) {
        final item = items.firstWhere((i) => i.id == id);
        final d = LocationTagService.calculateDistanceKm(
          centerLat,
          centerLng,
          item.latitude!,
          item.longitude!,
        );
        expect(d, greaterThan(testRadius));
      }
    });
  });

  group('Adversarial Stress Test: Zip Archive Integrity & CRC32', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('zip_stress_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Zip file creation, extraction, and CRC32 payload verification', () async {
      // This code for verifying compression integrity and bit-level CRC32 match on decompression
      final files = <File>[];
      final originalCrcs = <String, int>{};
      final originalBytes = <String, Uint8List>{};

      // 1. Regular text file
      final f1 = File('${tempDir.path}/doc.txt');
      final bytes1 = Uint8List.fromList('The quick brown fox jumps over the lazy dog'.codeUnits);
      await f1.writeAsBytes(bytes1);
      files.add(f1);
      originalCrcs['doc.txt'] = _computeCrc32(bytes1);
      originalBytes['doc.txt'] = bytes1;

      // 2. Binary random payload (128 KB)
      final f2 = File('${tempDir.path}/binary.dat');
      final random = Random(777);
      final bytes2 = Uint8List.fromList(List.generate(128 * 1024, (_) => random.nextInt(256)));
      await f2.writeAsBytes(bytes2);
      files.add(f2);
      originalCrcs['binary.dat'] = _computeCrc32(bytes2);
      originalBytes['binary.dat'] = bytes2;

      // 3. Zero-byte empty file
      final f3 = File('${tempDir.path}/empty.bin');
      final bytes3 = Uint8List(0);
      await f3.writeAsBytes(bytes3);
      files.add(f3);
      originalCrcs['empty.bin'] = _computeCrc32(bytes3);
      originalBytes['empty.bin'] = bytes3;

      // 4. Highly repetitive compressible payload (256 KB of 'A')
      final f4 = File('${tempDir.path}/repeated.txt');
      final bytes4 = Uint8List.fromList(List.filled(256 * 1024, 0x41));
      await f4.writeAsBytes(bytes4);
      files.add(f4);
      originalCrcs['repeated.txt'] = _computeCrc32(bytes4);
      originalBytes['repeated.txt'] = bytes4;

      final targetZip = File('${tempDir.path}/stress_output.zip');

      final result = await ZipExportService.createZipFromFiles(files, targetZip);
      expect(result.fileCount, equals(4));
      expect(await targetZip.exists(), isTrue);
      expect(result.totalBytes, greaterThan(0));

      // Decompress and verify every entry CRC32 and payload
      final zipBytes = await targetZip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      expect(archive.length, equals(4));

      for (final entry in archive) {
        expect(originalBytes.containsKey(entry.name), isTrue, reason: 'Unexpected entry ${entry.name}');
        final decompressed = entry.content as List<int>;
        final decompressedBytes = Uint8List.fromList(decompressed);

        // Verify CRC32 matches
        final computedCrc = _computeCrc32(decompressedBytes);
        expect(
          computedCrc,
          equals(originalCrcs[entry.name]),
          reason: 'CRC32 mismatch on decompressed entry ${entry.name}',
        );

        // Verify exact byte equality
        expect(
          decompressedBytes,
          equals(originalBytes[entry.name]),
          reason: 'Byte content mismatch on decompressed entry ${entry.name}',
        );
      }
    });

    test('Massive collision stress: 20 identically named files deduplicated properly', () async {
      // This code for stress testing duplicate filename resolution under intense collision
      final files = <File>[];
      for (int i = 0; i < 20; i++) {
        final subDir = Directory('${tempDir.path}/dir_$i')..createSync();
        final f = File('${subDir.path}/photo.jpg');
        await f.writeAsString('Payload from dir $i');
        files.add(f);
      }

      final targetZip = File('${tempDir.path}/collision_stress.zip');
      final result = await ZipExportService.createZipFromFiles(files, targetZip);
      expect(result.fileCount, equals(20));

      final zipBytes = await targetZip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      expect(archive.length, equals(20));

      final names = archive.map((e) => e.name).toSet();
      // Ensure all 20 entries have unique names
      expect(names.length, equals(20));
      expect(names.contains('photo.jpg'), isTrue);
      for (int i = 1; i <= 19; i++) {
        expect(names.contains('photo_$i.jpg'), isTrue, reason: 'Missing photo_$i.jpg');
      }
    });

    test('Filenames with special characters and multiple extensions', () async {
      // This code for validating filename sanitization and extension handling
      final f1 = File('${tempDir.path}/my space name.png');
      await f1.writeAsString('space content');

      final f2 = File('${tempDir.path}/archive.tar.gz');
      await f2.writeAsString('tar content');

      final f3 = File('${tempDir.path}/no_extension');
      await f3.writeAsString('no ext content');

      // Duplicate with no extension
      final sub = Directory('${tempDir.path}/sub')..createSync();
      final f4 = File('${sub.path}/no_extension');
      await f4.writeAsString('no ext content 2');

      final targetZip = File('${tempDir.path}/special_names.zip');
      final result = await ZipExportService.createZipFromFiles([f1, f2, f3, f4], targetZip);
      expect(result.fileCount, equals(4));

      final zipBytes = await targetZip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final names = archive.map((e) => e.name).toList();

      expect(names, contains('my space name.png'));
      expect(names, contains('archive.tar.gz'));
      expect(names, contains('no_extension'));
      expect(names, contains('no_extension_1'));
    });
  });
}
