import 'dart:io';
import 'package:drift/drift.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

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
      );

      await _db.insertMediaItem(companion);
      insertedCount++;
    }

    return insertedCount;
  }
}
