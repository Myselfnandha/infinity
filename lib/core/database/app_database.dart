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
  TextColumn get encryptionKeyId => text().nullable()();

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
  int get schemaVersion => 1;

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
}
