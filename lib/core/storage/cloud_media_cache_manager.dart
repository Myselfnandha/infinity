// This code for managing local LRU disk cache and cloud media retention
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';
import '../settings/app_preferences.dart';

// This code for controlling on-device storage limits, LRU eviction, and offline media pinning
class CloudMediaCacheManager {
  final AppDatabase _db;
  final AppPreferences _prefs;

  CloudMediaCacheManager(this._db, this._prefs);

  // This code for obtaining the dedicated local cache directory for media downloads
  Future<Directory> getCacheDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'media_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // This code for calculating total local cache usage in bytes
  Future<int> calculateCacheSizeBytes() async {
    final dir = await getCacheDirectory();
    int totalBytes = 0;
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
    }
    return totalBytes;
  }

  // This code for evicting least-recently-used unpinned files when cache exceeds limit
  Future<int> enforceCacheLimits() async {
    final limitBytes = _prefs.cacheLimitMb * 1024 * 1024;
    int currentBytes = await calculateCacheSizeBytes();

    if (currentBytes <= limitBytes) {
      return 0;
    }

    final cacheDir = await getCacheDirectory();
    final evictable = await _db.getEvictableCacheItems(50);
    int evictedBytes = 0;

    for (final item in evictable) {
      if (currentBytes <= limitBytes) break;

      if (item.filePath != null) {
        // Enforce cache boundary protection: only evict and delete files residing inside media_cache
        // Camera roll / gallery originals are never deleted during automated cache management
        if (!p.isWithin(cacheDir.path, item.filePath!)) {
          continue;
        }

        final file = File(item.filePath!);
        if (await file.exists()) {
          final size = await file.length();
          await file.delete();
          evictedBytes += size;
          currentBytes -= size;
        }

        await (_db.update(_db.mediaItems)..where((tbl) => tbl.id.equals(item.id)))
            .write(
          const MediaItemsCompanion(
            filePath: Value(null),
            cloudState: Value('CLOUD_ONLY'),
          ),
        );
      }
    }

    return evictedBytes;
  }

  // This code for safely freeing device space by deleting local copies of synced files
  Future<int> freeUpDeviceSpace() async {
    final evictable = await _db.getEvictableCacheItems(1000);
    int freedBytes = 0;

    for (final item in evictable) {
      if (item.filePath != null) {
        final file = File(item.filePath!);
        if (await file.exists()) {
          try {
            final size = await file.length();
            await file.delete();
            freedBytes += size;
          } catch (_) {}
        }

        await (_db.update(_db.mediaItems)..where((tbl) => tbl.id.equals(item.id)))
            .write(
          const MediaItemsCompanion(
            filePath: Value(null),
            cloudState: Value('CLOUD_ONLY'),
          ),
        );
      }
    }

    return freedBytes;
  }

  // This code for toggling offline pinning to prevent LRU cache eviction
  Future<void> togglePinOffline(String id, bool pin) async {
    await _db.setPinnedOffline(id, pin);
  }
}
