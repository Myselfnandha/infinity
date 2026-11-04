import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class MediaItems extends Table {
  TextColumn get id => text()();
  TextColumn get filePath => text().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get telegramFileId => text().nullable()();
  IntColumn get telegramMessageId => integer().nullable()();
  IntColumn get telegramChatId => integer().nullable()();
  IntColumn get telegramTopicId => integer().nullable()();
  TextColumn get mediaType => text()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get fileSize => integer()();
  IntColumn get duration => integer().nullable()();
  DateTimeColumn get dateTaken => dateTime().nullable()();
  DateTimeColumn get dateAdded => dateTime()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isTrashed => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();
  TextColumn get sha256Hash => text().nullable()();
  TextColumn get perceptualHash => text().nullable()();
  // This code for storing GPS latitude coordinate in decimal degrees
  RealColumn get latitude => real().nullable()();
  // This code for storing GPS longitude coordinate in decimal degrees
  RealColumn get longitude => real().nullable()();
  // This code for storing human-readable locality tag (e.g. 'San Francisco, USA')
  TextColumn get locationName => text().nullable()();
  TextColumn get encryptionKeyId => text().nullable()();
  BoolColumn get isPinnedOffline => boolean().withDefault(const Constant(false))();
  TextColumn get cloudState => text().withDefault(const Constant('LOCAL_ONLY'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Albums extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get topicId => integer().nullable()();
  TextColumn get coverMediaId => text().nullable()();
  DateTimeColumn get dateCreated => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class MediaAlbumRelations extends Table {
  TextColumn get mediaId => text()();
  TextColumn get albumId => text()();

  @override
  Set<Column> get primaryKey => {mediaId, albumId};
}

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get mediaId => text()();
  TextColumn get taskType => text()();
  TextColumn get status => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [MediaItems, Albums, MediaAlbumRelations, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(mediaItems, mediaItems.latitude);
            await m.addColumn(mediaItems, mediaItems.longitude);
            await m.addColumn(mediaItems, mediaItems.locationName);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'infinity_vault');
  }

  Stream<List<MediaItem>> watchAllMedia() {
    return (select(mediaItems)
          ..where((tbl) => tbl.isTrashed.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: coalesce([tbl.dateTaken, tbl.dateAdded]),
                mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Stream<List<MediaItem>> watchFavorites() {
    return (select(mediaItems)
          ..where((tbl) => tbl.isFavorite.equals(true) & tbl.isTrashed.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: coalesce([tbl.dateTaken, tbl.dateAdded]),
                mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Stream<List<MediaItem>> watchTrash() {
    return (select(mediaItems)
          ..where((tbl) => tbl.isTrashed.equals(true))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.dateAdded, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Stream<List<Album>> watchAlbums() {
    return (select(albums)..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder)]))
        .watch();
  }

  // This code for watching non-photo documents and general files in the vault
  Stream<List<MediaItem>> watchFiles() {
    return (select(mediaItems)
          ..where((tbl) =>
              tbl.isTrashed.equals(false) &
              (tbl.mediaType.equals('document') |
                  tbl.mediaType.equals('file') |
                  tbl.mediaType.equals('archive') |
                  tbl.mediaType.equals('audio')))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.dateAdded, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // This code for dynamically querying and filtering media and files with search predicates
  Stream<List<MediaItem>> searchMedia({
    String? query,
    String? mediaType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isFavorite,
    bool? isPinnedOffline,
    bool? hasLocation,
  }) {
    return (select(mediaItems)
          ..where((tbl) {
            Expression<bool> predicate = tbl.isTrashed.equals(false);

            if (query != null && query.trim().isNotEmpty) {
              final pattern = '%${query.trim()}%';
              predicate = predicate &
                  (tbl.filePath.like(pattern) |
                      tbl.id.like(pattern) |
                      tbl.locationName.like(pattern));
            }

            if (mediaType != null && mediaType.isNotEmpty && mediaType != 'all') {
              if (mediaType == 'files') {
                predicate = predicate &
                    (tbl.mediaType.equals('document') |
                        tbl.mediaType.equals('file') |
                        tbl.mediaType.equals('archive') |
                        tbl.mediaType.equals('audio'));
              } else {
                predicate = predicate & tbl.mediaType.equals(mediaType);
              }
            }

            if (startDate != null) {
              predicate = predicate &
                  coalesce([tbl.dateTaken, tbl.dateAdded])
                      .isBiggerOrEqualValue(startDate);
            }

            if (endDate != null) {
              predicate = predicate &
                  coalesce([tbl.dateTaken, tbl.dateAdded])
                      .isSmallerOrEqualValue(endDate);
            }

            if (isFavorite == true) {
              predicate = predicate & tbl.isFavorite.equals(true);
            }

            if (isPinnedOffline == true) {
              predicate = predicate & tbl.isPinnedOffline.equals(true);
            }

            if (hasLocation == true) {
              predicate = predicate &
                  tbl.latitude.isNotNull() &
                  tbl.longitude.isNotNull();
            }

            return predicate;
          })
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: coalesce([tbl.dateTaken, tbl.dateAdded]),
                mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // This code for updating perceptual difference hash of an item
  Future<void> updatePerceptualHash(String id, String hash) {
    return (update(mediaItems)..where((tbl) => tbl.id.equals(id)))
        .write(MediaItemsCompanion(perceptualHash: Value(hash)));
  }

  // This code for updating location coordinates and locality name of an item
  Future<void> updateLocation(
      String id, double latitude, double longitude, String? locationName) {
    return (update(mediaItems)..where((tbl) => tbl.id.equals(id))).write(
      MediaItemsCompanion(
        latitude: Value(latitude),
        longitude: Value(longitude),
        locationName:
            locationName != null ? Value(locationName) : const Value.absent(),
      ),
    );
  }

  // This code for fetching image items that have not had their perceptual hash calculated
  Future<List<MediaItem>> getImagesWithoutPerceptualHash({int limit = 100}) {
    return (select(mediaItems)
          ..where((tbl) =>
              tbl.perceptualHash.isNull() &
              tbl.mediaType.equals('image') &
              tbl.isTrashed.equals(false) &
              tbl.filePath.isNotNull())
          ..limit(limit))
        .get();
  }

  // This code for streaming images that have perceptual hashes for duplicate clustering
  Stream<List<MediaItem>> watchDuplicateCandidates() {
    return (select(mediaItems)
          ..where((tbl) =>
              tbl.perceptualHash.isNotNull() &
              tbl.isTrashed.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: coalesce([tbl.dateTaken, tbl.dateAdded]),
                mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<int> insertMediaItem(MediaItemsCompanion item) =>
      into(mediaItems).insertOnConflictUpdate(item);

  Future<int> insertAlbum(AlbumsCompanion album) =>
      into(albums).insertOnConflictUpdate(album);

  Future<void> linkMediaToAlbum(String mediaId, String albumId) {
    return into(mediaAlbumRelations).insertOnConflictUpdate(
      MediaAlbumRelationsCompanion.insert(
        mediaId: mediaId,
        albumId: albumId,
      ),
    );
  }

  Stream<List<MediaItem>> watchMediaForAlbum(String albumId) {
    final query = select(mediaItems).join([
      innerJoin(
        mediaAlbumRelations,
        mediaAlbumRelations.mediaId.equalsExp(mediaItems.id),
      ),
    ])
      ..where(mediaAlbumRelations.albumId.equals(albumId) &
          mediaItems.isTrashed.equals(false))
      ..orderBy([
        OrderingTerm(
          expression: coalesce([mediaItems.dateTaken, mediaItems.dateAdded]),
          mode: OrderingMode.desc,
        )
      ]);

    return query.map((row) => row.readTable(mediaItems)).watch();
  }

  Future<void> setFavorite(String id, bool favorite) {
    return (update(mediaItems)..where((tbl) => tbl.id.equals(id)))
        .write(MediaItemsCompanion(isFavorite: Value(favorite)));
  }

  Future<void> setTrashed(String id, bool trashed) {
    return (update(mediaItems)..where((tbl) => tbl.id.equals(id)))
        .write(MediaItemsCompanion(isTrashed: Value(trashed)));
  }

  Future<void> updateSyncStatus(String id, String status,
      {String? telegramFileId, int? telegramMessageId, int? telegramChatId, int? telegramTopicId}) {
    return (update(mediaItems)..where((tbl) => tbl.id.equals(id))).write(
      MediaItemsCompanion(
        syncStatus: Value(status),
        telegramFileId: telegramFileId != null ? Value(telegramFileId) : const Value.absent(),
        telegramMessageId:
            telegramMessageId != null ? Value(telegramMessageId) : const Value.absent(),
        telegramChatId: telegramChatId != null ? Value(telegramChatId) : const Value.absent(),
        telegramTopicId:
            telegramTopicId != null ? Value(telegramTopicId) : const Value.absent(),
      ),
    );
  }

  Future<MediaItem?> getMediaByHash(String hash) {
    return (select(mediaItems)..where((tbl) => tbl.sha256Hash.equals(hash)))
        .getSingleOrNull();
  }

  Future<MediaItem?> getMediaItem(String id) {
    return (select(mediaItems)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<MediaItem>> getUnsyncedMedia() {
    return (select(mediaItems)
          ..where((tbl) =>
              tbl.syncStatus.equals('local') & tbl.isTrashed.equals(false)))
        .get();
  }

  Future<void> setPinnedOffline(String id, bool pinned) {
    return (update(mediaItems)..where((tbl) => tbl.id.equals(id)))
        .write(MediaItemsCompanion(isPinnedOffline: Value(pinned)));
  }

  Future<void> setCloudState(String id, String state) {
    return (update(mediaItems)..where((tbl) => tbl.id.equals(id)))
        .write(MediaItemsCompanion(cloudState: Value(state)));
  }

  Stream<List<SyncQueueData>> watchPendingSyncTasks() {
    return (select(syncQueue)
          ..where((tbl) =>
              tbl.status.equals('pending') | tbl.status.equals('inProgress'))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.priority, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  Future<int> insertSyncTask(SyncQueueCompanion task) {
    return into(syncQueue).insertOnConflictUpdate(task);
  }

  Future<void> updateTaskStatus(
    String id,
    String status, {
    String? errorMessage,
    double? progress,
    DateTime? lastAttemptAt,
    int? retryCount,
  }) {
    return (update(syncQueue)..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueCompanion(
        status: Value(status),
        errorMessage: errorMessage != null ? Value(errorMessage) : const Value.absent(),
        progress: progress != null ? Value(progress) : const Value.absent(),
        lastAttemptAt:
            lastAttemptAt != null ? Value(lastAttemptAt) : const Value.absent(),
        retryCount: retryCount != null ? Value(retryCount) : const Value.absent(),
      ),
    );
  }

  Future<int> deleteSyncTask(String id) {
    return (delete(syncQueue)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<MediaItem>> getEvictableCacheItems(int limit) {
    return (select(mediaItems)
          ..where((tbl) =>
              tbl.syncStatus.equals('synced') &
              tbl.isPinnedOffline.equals(false) &
              tbl.filePath.isNotNull())
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.dateAdded, mode: OrderingMode.asc)
          ])
          ..limit(limit))
        .get();
  }
}
