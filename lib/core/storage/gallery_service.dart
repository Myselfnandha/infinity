import 'dart:io';
import 'package:drift/drift.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../media/exif_parser_service.dart';
import '../media/location_tag_service.dart';
import '../media/perceptual_hash_service.dart';

class GalleryService {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  GalleryService(this._db);

  Future<bool> requestPermissions() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    return state.isAuth || state.hasAccess;
  }

  Future<int> scanDeviceMedia({int limit = 200}) async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return 0;

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );

    if (albums.isEmpty) return 0;

    final AssetPathEntity recentAlbum = albums.first;
    final List<AssetEntity> assets = await recentAlbum.getAssetListPaged(
      page: 0,
      size: limit,
    );

    final List<MediaItemsCompanion> companions = [];
    for (final asset in assets) {
      try {
        final File? file = await asset.file;
        if (file == null) continue;

        final String mediaType = asset.type == AssetType.video ? 'video' : 'image';

        double? lat = asset.latitude != 0.0 ? asset.latitude : null;
        double? lng = asset.longitude != 0.0 ? asset.longitude : null;
        if ((lat == null || lng == null) && mediaType == 'image') {
          final exif = await ExifParserService.parseFile(file.path);
          if (exif.latitude != null && exif.longitude != null) {
            lat = exif.latitude;
            lng = exif.longitude;
          }
        }

        String? locality;
        if (lat != null && lng != null) {
          locality = LocationTagService.resolveLocalityTag(lat, lng);
        }

        String? pHash;
        if (mediaType == 'image') {
          try {
            final thumbBytes = await asset.thumbnailDataWithSize(const ThumbnailSize(64, 64));
            if (thumbBytes != null && thumbBytes.isNotEmpty) {
              pHash = await PerceptualHashService.computeDHashFromBytes(thumbBytes);
            } else {
              pHash = await PerceptualHashService.computeDHash(file.path);
            }
          } catch (_) {
            pHash = null;
          }
        }

        companions.add(
          MediaItemsCompanion.insert(
            id: asset.id.isNotEmpty ? asset.id : _uuid.v4(),
            filePath: Value(file.path),
            mediaType: mediaType,
            width: Value(asset.width),
            height: Value(asset.height),
            fileSize: await file.length(),
            duration: Value(asset.duration),
            dateTaken: Value(asset.createDateTime),
            dateAdded: asset.modifiedDateTime,
            isFavorite: Value(asset.isFavorite),
            syncStatus: const Value('local'),
            latitude: Value(lat),
            longitude: Value(lng),
            locationName: Value(locality),
            perceptualHash: Value(pHash),
          ),
        );
      } catch (_) {
        continue;
      }
    }

    // This code for batch inserting media item companions into SQLite in a single transaction
    if (companions.isNotEmpty) {
      await _db.batch((b) {
        b.insertAllOnConflictUpdate(_db.mediaItems, companions);
      });
    }

    return companions.length;
  }
}
