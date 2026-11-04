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

    int insertedCount = 0;
    for (final asset in assets) {
      final File? file = await asset.file;
      if (file == null) continue;

      final String mediaType = asset.type == AssetType.video ? 'video' : 'image';

      // This code for extracting GPS coordinates from asset or EXIF fallback
      double? lat = asset.latitude != 0.0 ? asset.latitude : null;
      double? lng = asset.longitude != 0.0 ? asset.longitude : null;
      if ((lat == null || lng == null) && mediaType == 'image') {
        final exif = await ExifParserService.parseFile(file.path);
        if (exif.latitude != null && exif.longitude != null) {
          lat = exif.latitude;
          lng = exif.longitude;
        }
      }

      // This code for resolving offline human-readable locality name
      String? locality;
      if (lat != null && lng != null) {
        locality = LocationTagService.resolveLocalityTag(lat, lng);
      }

      // This code for computing 64-bit gradient perceptual hash for duplicate detection
      String? pHash;
      if (mediaType == 'image') {
        pHash = await PerceptualHashService.computeDHash(file.path);
      }

      final companion = MediaItemsCompanion.insert(
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
      );

      await _db.insertMediaItem(companion);
      insertedCount++;
    }

    return insertedCount;
  }
}
