// This code for computing 64-bit gradient perceptual difference hashes (dHash) and near-duplicate detection
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../database/app_database.dart';

// This code for representing a cluster of near-duplicate media items
class DuplicateCluster {
  // This code for the reference or primary media item in the cluster
  final MediaItem primary;

  // This code for the list of near-duplicate media items associated with the primary
  final List<MediaItem> duplicates;

  // This code for the average Hamming distance across the duplicates in the cluster
  final int averageDistance;

  const DuplicateCluster({
    required this.primary,
    required this.duplicates,
    required this.averageDistance,
  });
}

// This code for calculating perceptual hashes and detecting duplicate photos
class PerceptualHashService {
  // This code for calculating 64-bit dHash from an image file path using background compute isolate
  static Future<String?> computeDHash(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    try {
      final bytes = await file.readAsBytes();
      return await computeDHashFromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  // This code for computing 64-bit dHash from raw image bytes
  static Future<String?> computeDHashFromBytes(Uint8List bytes) async {
    try {
      return await compute(_computeDHashWorker, bytes);
    } catch (_) {
      // Fallback to synchronous computation in current isolate if compute isolate fails
      return _computeDHashWorker(bytes);
    }
  }

  // This code for synchronous calculation of 64-bit gradient dHash from bytes
  static String? computeDHashSync(Uint8List bytes) {
    return _computeDHashWorker(bytes);
  }

  // This code for isolate worker that decodes image, resizes to 9x8, and computes gradient bits
  static String? _computeDHashWorker(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize to 9 columns by 8 rows (72 pixels)
      final resized = img.copyResize(image, width: 9, height: 8);
      final grayscale = img.grayscale(resized);

      BigInt hash = BigInt.zero;
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final left = grayscale.getPixel(x, y).r;
          final right = grayscale.getPixel(x + 1, y).r;
          if (left > right) {
            hash = (hash << 1) | BigInt.one;
          } else {
            hash = hash << 1;
          }
        }
      }
      return hash.toRadixString(16).padLeft(16, '0');
    } catch (_) {
      return null;
    }
  }

  // This code for calculating Hamming distance between two 16-hex perceptual hashes
  static int hammingDistance(String hash1, String hash2) {
    if (hash1.length != 16 || hash2.length != 16) return 64;
    final b1 = BigInt.tryParse(hash1, radix: 16);
    final b2 = BigInt.tryParse(hash2, radix: 16);
    if (b1 == null || b2 == null) return 64;

    final xor = b1 ^ b2;
    if (xor == BigInt.zero) return 0;
    return xor.toRadixString(2).replaceAll('0', '').length;
  }

  // This code for determining if two hashes are near-duplicates within a specified threshold
  static bool isNearDuplicate(String hash1, String hash2, {int threshold = 10}) {
    return hammingDistance(hash1, hash2) <= threshold;
  }

  // This code for clustering a list of media items into near-duplicate groups
  static List<DuplicateCluster> findDuplicates(
    List<MediaItem> items, {
    int threshold = 10,
  }) {
    final hashedItems = items
        .where((i) => i.perceptualHash != null && i.perceptualHash!.isNotEmpty)
        .toList();
    final List<DuplicateCluster> clusters = [];
    final Set<String> visitedIds = {};

    for (int i = 0; i < hashedItems.length; i++) {
      final current = hashedItems[i];
      if (visitedIds.contains(current.id)) continue;

      final List<MediaItem> duplicates = [];
      int totalDistance = 0;

      for (int j = i + 1; j < hashedItems.length; j++) {
        final candidate = hashedItems[j];
        if (visitedIds.contains(candidate.id)) continue;

        final dist = hammingDistance(current.perceptualHash!, candidate.perceptualHash!);
        if (dist <= threshold) {
          duplicates.add(candidate);
          totalDistance += dist;
          visitedIds.add(candidate.id);
        }
      }

      if (duplicates.isNotEmpty) {
        visitedIds.add(current.id);
        clusters.add(
          DuplicateCluster(
            primary: current,
            duplicates: duplicates,
            averageDistance: (totalDistance / duplicates.length).round(),
          ),
        );
      }
    }

    return clusters;
  }

  // This code for asynchronously backfilling missing perceptual hashes in the SQLite database
  static Future<int> backfillMissingHashes(AppDatabase db, {int batchSize = 50}) async {
    final unhashed = await (db.select(db.mediaItems)
          ..where((tbl) =>
              tbl.perceptualHash.isNull() &
              tbl.mediaType.equals('image') &
              tbl.isTrashed.equals(false) &
              tbl.filePath.isNotNull())
          ..limit(batchSize))
        .get();

    int backfilledCount = 0;
    for (final item in unhashed) {
      if (item.filePath == null) continue;
      final hash = await computeDHash(item.filePath!);
      if (hash != null) {
        await (db.update(db.mediaItems)..where((tbl) => tbl.id.equals(item.id)))
            .write(MediaItemsCompanion(perceptualHash: Value(hash)));
        backfilledCount++;
      }
    }
    return backfilledCount;
  }
}
