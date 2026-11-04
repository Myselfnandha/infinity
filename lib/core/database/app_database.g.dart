// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, MediaItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telegramFileIdMeta = const VerificationMeta(
    'telegramFileId',
  );
  @override
  late final GeneratedColumn<String> telegramFileId = GeneratedColumn<String>(
    'telegram_file_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telegramMessageIdMeta = const VerificationMeta(
    'telegramMessageId',
  );
  @override
  late final GeneratedColumn<int> telegramMessageId = GeneratedColumn<int>(
    'telegram_message_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telegramChatIdMeta = const VerificationMeta(
    'telegramChatId',
  );
  @override
  late final GeneratedColumn<int> telegramChatId = GeneratedColumn<int>(
    'telegram_chat_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telegramTopicIdMeta = const VerificationMeta(
    'telegramTopicId',
  );
  @override
  late final GeneratedColumn<int> telegramTopicId = GeneratedColumn<int>(
    'telegram_topic_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateTakenMeta = const VerificationMeta(
    'dateTaken',
  );
  @override
  late final GeneratedColumn<DateTime> dateTaken = GeneratedColumn<DateTime>(
    'date_taken',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isTrashedMeta = const VerificationMeta(
    'isTrashed',
  );
  @override
  late final GeneratedColumn<bool> isTrashed = GeneratedColumn<bool>(
    'is_trashed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_trashed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _sha256HashMeta = const VerificationMeta(
    'sha256Hash',
  );
  @override
  late final GeneratedColumn<String> sha256Hash = GeneratedColumn<String>(
    'sha256_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _perceptualHashMeta = const VerificationMeta(
    'perceptualHash',
  );
  @override
  late final GeneratedColumn<String> perceptualHash = GeneratedColumn<String>(
    'perceptual_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _encryptionKeyIdMeta = const VerificationMeta(
    'encryptionKeyId',
  );
  @override
  late final GeneratedColumn<String> encryptionKeyId = GeneratedColumn<String>(
    'encryption_key_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPinnedOfflineMeta = const VerificationMeta(
    'isPinnedOffline',
  );
  @override
  late final GeneratedColumn<bool> isPinnedOffline = GeneratedColumn<bool>(
    'is_pinned_offline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned_offline" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cloudStateMeta = const VerificationMeta(
    'cloudState',
  );
  @override
  late final GeneratedColumn<String> cloudState = GeneratedColumn<String>(
    'cloud_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LOCAL_ONLY'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filePath,
    thumbnailPath,
    telegramFileId,
    telegramMessageId,
    telegramChatId,
    telegramTopicId,
    mediaType,
    width,
    height,
    fileSize,
    duration,
    dateTaken,
    dateAdded,
    isFavorite,
    isTrashed,
    syncStatus,
    sha256Hash,
    perceptualHash,
    latitude,
    longitude,
    locationName,
    encryptionKeyId,
    isPinnedOffline,
    cloudState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('telegram_file_id')) {
      context.handle(
        _telegramFileIdMeta,
        telegramFileId.isAcceptableOrUnknown(
          data['telegram_file_id']!,
          _telegramFileIdMeta,
        ),
      );
    }
    if (data.containsKey('telegram_message_id')) {
      context.handle(
        _telegramMessageIdMeta,
        telegramMessageId.isAcceptableOrUnknown(
          data['telegram_message_id']!,
          _telegramMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('telegram_chat_id')) {
      context.handle(
        _telegramChatIdMeta,
        telegramChatId.isAcceptableOrUnknown(
          data['telegram_chat_id']!,
          _telegramChatIdMeta,
        ),
      );
    }
    if (data.containsKey('telegram_topic_id')) {
      context.handle(
        _telegramTopicIdMeta,
        telegramTopicId.isAcceptableOrUnknown(
          data['telegram_topic_id']!,
          _telegramTopicIdMeta,
        ),
      );
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('date_taken')) {
      context.handle(
        _dateTakenMeta,
        dateTaken.isAcceptableOrUnknown(data['date_taken']!, _dateTakenMeta),
      );
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    } else if (isInserting) {
      context.missing(_dateAddedMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_trashed')) {
      context.handle(
        _isTrashedMeta,
        isTrashed.isAcceptableOrUnknown(data['is_trashed']!, _isTrashedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sha256_hash')) {
      context.handle(
        _sha256HashMeta,
        sha256Hash.isAcceptableOrUnknown(data['sha256_hash']!, _sha256HashMeta),
      );
    }
    if (data.containsKey('perceptual_hash')) {
      context.handle(
        _perceptualHashMeta,
        perceptualHash.isAcceptableOrUnknown(
          data['perceptual_hash']!,
          _perceptualHashMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('encryption_key_id')) {
      context.handle(
        _encryptionKeyIdMeta,
        encryptionKeyId.isAcceptableOrUnknown(
          data['encryption_key_id']!,
          _encryptionKeyIdMeta,
        ),
      );
    }
    if (data.containsKey('is_pinned_offline')) {
      context.handle(
        _isPinnedOfflineMeta,
        isPinnedOffline.isAcceptableOrUnknown(
          data['is_pinned_offline']!,
          _isPinnedOfflineMeta,
        ),
      );
    }
    if (data.containsKey('cloud_state')) {
      context.handle(
        _cloudStateMeta,
        cloudState.isAcceptableOrUnknown(data['cloud_state']!, _cloudStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      telegramFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telegram_file_id'],
      ),
      telegramMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}telegram_message_id'],
      ),
      telegramChatId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}telegram_chat_id'],
      ),
      telegramTopicId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}telegram_topic_id'],
      ),
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
      dateTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_taken'],
      ),
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isTrashed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_trashed'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      sha256Hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256_hash'],
      ),
      perceptualHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}perceptual_hash'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      ),
      encryptionKeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encryption_key_id'],
      ),
      isPinnedOffline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned_offline'],
      )!,
      cloudState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_state'],
      )!,
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }
}

class MediaItem extends DataClass implements Insertable<MediaItem> {
  final String id;
  final String? filePath;
  final String? thumbnailPath;
  final String? telegramFileId;
  final int? telegramMessageId;
  final int? telegramChatId;
  final int? telegramTopicId;
  final String mediaType;
  final int? width;
  final int? height;
  final int fileSize;
  final int? duration;
  final DateTime? dateTaken;
  final DateTime dateAdded;
  final bool isFavorite;
  final bool isTrashed;
  final String syncStatus;
  final String? sha256Hash;
  final String? perceptualHash;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? encryptionKeyId;
  final bool isPinnedOffline;
  final String cloudState;
  const MediaItem({
    required this.id,
    this.filePath,
    this.thumbnailPath,
    this.telegramFileId,
    this.telegramMessageId,
    this.telegramChatId,
    this.telegramTopicId,
    required this.mediaType,
    this.width,
    this.height,
    required this.fileSize,
    this.duration,
    this.dateTaken,
    required this.dateAdded,
    required this.isFavorite,
    required this.isTrashed,
    required this.syncStatus,
    this.sha256Hash,
    this.perceptualHash,
    this.latitude,
    this.longitude,
    this.locationName,
    this.encryptionKeyId,
    required this.isPinnedOffline,
    required this.cloudState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || telegramFileId != null) {
      map['telegram_file_id'] = Variable<String>(telegramFileId);
    }
    if (!nullToAbsent || telegramMessageId != null) {
      map['telegram_message_id'] = Variable<int>(telegramMessageId);
    }
    if (!nullToAbsent || telegramChatId != null) {
      map['telegram_chat_id'] = Variable<int>(telegramChatId);
    }
    if (!nullToAbsent || telegramTopicId != null) {
      map['telegram_topic_id'] = Variable<int>(telegramTopicId);
    }
    map['media_type'] = Variable<String>(mediaType);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    map['file_size'] = Variable<int>(fileSize);
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    if (!nullToAbsent || dateTaken != null) {
      map['date_taken'] = Variable<DateTime>(dateTaken);
    }
    map['date_added'] = Variable<DateTime>(dateAdded);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_trashed'] = Variable<bool>(isTrashed);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || sha256Hash != null) {
      map['sha256_hash'] = Variable<String>(sha256Hash);
    }
    if (!nullToAbsent || perceptualHash != null) {
      map['perceptual_hash'] = Variable<String>(perceptualHash);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || locationName != null) {
      map['location_name'] = Variable<String>(locationName);
    }
    if (!nullToAbsent || encryptionKeyId != null) {
      map['encryption_key_id'] = Variable<String>(encryptionKeyId);
    }
    map['is_pinned_offline'] = Variable<bool>(isPinnedOffline);
    map['cloud_state'] = Variable<String>(cloudState);
    return map;
  }

  MediaItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsCompanion(
      id: Value(id),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      telegramFileId: telegramFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(telegramFileId),
      telegramMessageId: telegramMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(telegramMessageId),
      telegramChatId: telegramChatId == null && nullToAbsent
          ? const Value.absent()
          : Value(telegramChatId),
      telegramTopicId: telegramTopicId == null && nullToAbsent
          ? const Value.absent()
          : Value(telegramTopicId),
      mediaType: Value(mediaType),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      fileSize: Value(fileSize),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      dateTaken: dateTaken == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTaken),
      dateAdded: Value(dateAdded),
      isFavorite: Value(isFavorite),
      isTrashed: Value(isTrashed),
      syncStatus: Value(syncStatus),
      sha256Hash: sha256Hash == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256Hash),
      perceptualHash: perceptualHash == null && nullToAbsent
          ? const Value.absent()
          : Value(perceptualHash),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      locationName: locationName == null && nullToAbsent
          ? const Value.absent()
          : Value(locationName),
      encryptionKeyId: encryptionKeyId == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptionKeyId),
      isPinnedOffline: Value(isPinnedOffline),
      cloudState: Value(cloudState),
    );
  }

  factory MediaItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItem(
      id: serializer.fromJson<String>(json['id']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      telegramFileId: serializer.fromJson<String?>(json['telegramFileId']),
      telegramMessageId: serializer.fromJson<int?>(json['telegramMessageId']),
      telegramChatId: serializer.fromJson<int?>(json['telegramChatId']),
      telegramTopicId: serializer.fromJson<int?>(json['telegramTopicId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      duration: serializer.fromJson<int?>(json['duration']),
      dateTaken: serializer.fromJson<DateTime?>(json['dateTaken']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isTrashed: serializer.fromJson<bool>(json['isTrashed']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      sha256Hash: serializer.fromJson<String?>(json['sha256Hash']),
      perceptualHash: serializer.fromJson<String?>(json['perceptualHash']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      locationName: serializer.fromJson<String?>(json['locationName']),
      encryptionKeyId: serializer.fromJson<String?>(json['encryptionKeyId']),
      isPinnedOffline: serializer.fromJson<bool>(json['isPinnedOffline']),
      cloudState: serializer.fromJson<String>(json['cloudState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'filePath': serializer.toJson<String?>(filePath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'telegramFileId': serializer.toJson<String?>(telegramFileId),
      'telegramMessageId': serializer.toJson<int?>(telegramMessageId),
      'telegramChatId': serializer.toJson<int?>(telegramChatId),
      'telegramTopicId': serializer.toJson<int?>(telegramTopicId),
      'mediaType': serializer.toJson<String>(mediaType),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'fileSize': serializer.toJson<int>(fileSize),
      'duration': serializer.toJson<int?>(duration),
      'dateTaken': serializer.toJson<DateTime?>(dateTaken),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isTrashed': serializer.toJson<bool>(isTrashed),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'sha256Hash': serializer.toJson<String?>(sha256Hash),
      'perceptualHash': serializer.toJson<String?>(perceptualHash),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'locationName': serializer.toJson<String?>(locationName),
      'encryptionKeyId': serializer.toJson<String?>(encryptionKeyId),
      'isPinnedOffline': serializer.toJson<bool>(isPinnedOffline),
      'cloudState': serializer.toJson<String>(cloudState),
    };
  }

  MediaItem copyWith({
    String? id,
    Value<String?> filePath = const Value.absent(),
    Value<String?> thumbnailPath = const Value.absent(),
    Value<String?> telegramFileId = const Value.absent(),
    Value<int?> telegramMessageId = const Value.absent(),
    Value<int?> telegramChatId = const Value.absent(),
    Value<int?> telegramTopicId = const Value.absent(),
    String? mediaType,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    int? fileSize,
    Value<int?> duration = const Value.absent(),
    Value<DateTime?> dateTaken = const Value.absent(),
    DateTime? dateAdded,
    bool? isFavorite,
    bool? isTrashed,
    String? syncStatus,
    Value<String?> sha256Hash = const Value.absent(),
    Value<String?> perceptualHash = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> locationName = const Value.absent(),
    Value<String?> encryptionKeyId = const Value.absent(),
    bool? isPinnedOffline,
    String? cloudState,
  }) => MediaItem(
    id: id ?? this.id,
    filePath: filePath.present ? filePath.value : this.filePath,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    telegramFileId: telegramFileId.present
        ? telegramFileId.value
        : this.telegramFileId,
    telegramMessageId: telegramMessageId.present
        ? telegramMessageId.value
        : this.telegramMessageId,
    telegramChatId: telegramChatId.present
        ? telegramChatId.value
        : this.telegramChatId,
    telegramTopicId: telegramTopicId.present
        ? telegramTopicId.value
        : this.telegramTopicId,
    mediaType: mediaType ?? this.mediaType,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    fileSize: fileSize ?? this.fileSize,
    duration: duration.present ? duration.value : this.duration,
    dateTaken: dateTaken.present ? dateTaken.value : this.dateTaken,
    dateAdded: dateAdded ?? this.dateAdded,
    isFavorite: isFavorite ?? this.isFavorite,
    isTrashed: isTrashed ?? this.isTrashed,
    syncStatus: syncStatus ?? this.syncStatus,
    sha256Hash: sha256Hash.present ? sha256Hash.value : this.sha256Hash,
    perceptualHash: perceptualHash.present
        ? perceptualHash.value
        : this.perceptualHash,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    locationName: locationName.present ? locationName.value : this.locationName,
    encryptionKeyId: encryptionKeyId.present
        ? encryptionKeyId.value
        : this.encryptionKeyId,
    isPinnedOffline: isPinnedOffline ?? this.isPinnedOffline,
    cloudState: cloudState ?? this.cloudState,
  );
  MediaItem copyWithCompanion(MediaItemsCompanion data) {
    return MediaItem(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      telegramFileId: data.telegramFileId.present
          ? data.telegramFileId.value
          : this.telegramFileId,
      telegramMessageId: data.telegramMessageId.present
          ? data.telegramMessageId.value
          : this.telegramMessageId,
      telegramChatId: data.telegramChatId.present
          ? data.telegramChatId.value
          : this.telegramChatId,
      telegramTopicId: data.telegramTopicId.present
          ? data.telegramTopicId.value
          : this.telegramTopicId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      duration: data.duration.present ? data.duration.value : this.duration,
      dateTaken: data.dateTaken.present ? data.dateTaken.value : this.dateTaken,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isTrashed: data.isTrashed.present ? data.isTrashed.value : this.isTrashed,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      sha256Hash: data.sha256Hash.present
          ? data.sha256Hash.value
          : this.sha256Hash,
      perceptualHash: data.perceptualHash.present
          ? data.perceptualHash.value
          : this.perceptualHash,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      encryptionKeyId: data.encryptionKeyId.present
          ? data.encryptionKeyId.value
          : this.encryptionKeyId,
      isPinnedOffline: data.isPinnedOffline.present
          ? data.isPinnedOffline.value
          : this.isPinnedOffline,
      cloudState: data.cloudState.present
          ? data.cloudState.value
          : this.cloudState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItem(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('telegramFileId: $telegramFileId, ')
          ..write('telegramMessageId: $telegramMessageId, ')
          ..write('telegramChatId: $telegramChatId, ')
          ..write('telegramTopicId: $telegramTopicId, ')
          ..write('mediaType: $mediaType, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fileSize: $fileSize, ')
          ..write('duration: $duration, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isTrashed: $isTrashed, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('perceptualHash: $perceptualHash, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('locationName: $locationName, ')
          ..write('encryptionKeyId: $encryptionKeyId, ')
          ..write('isPinnedOffline: $isPinnedOffline, ')
          ..write('cloudState: $cloudState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    filePath,
    thumbnailPath,
    telegramFileId,
    telegramMessageId,
    telegramChatId,
    telegramTopicId,
    mediaType,
    width,
    height,
    fileSize,
    duration,
    dateTaken,
    dateAdded,
    isFavorite,
    isTrashed,
    syncStatus,
    sha256Hash,
    perceptualHash,
    latitude,
    longitude,
    locationName,
    encryptionKeyId,
    isPinnedOffline,
    cloudState,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItem &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.telegramFileId == this.telegramFileId &&
          other.telegramMessageId == this.telegramMessageId &&
          other.telegramChatId == this.telegramChatId &&
          other.telegramTopicId == this.telegramTopicId &&
          other.mediaType == this.mediaType &&
          other.width == this.width &&
          other.height == this.height &&
          other.fileSize == this.fileSize &&
          other.duration == this.duration &&
          other.dateTaken == this.dateTaken &&
          other.dateAdded == this.dateAdded &&
          other.isFavorite == this.isFavorite &&
          other.isTrashed == this.isTrashed &&
          other.syncStatus == this.syncStatus &&
          other.sha256Hash == this.sha256Hash &&
          other.perceptualHash == this.perceptualHash &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.locationName == this.locationName &&
          other.encryptionKeyId == this.encryptionKeyId &&
          other.isPinnedOffline == this.isPinnedOffline &&
          other.cloudState == this.cloudState);
}

class MediaItemsCompanion extends UpdateCompanion<MediaItem> {
  final Value<String> id;
  final Value<String?> filePath;
  final Value<String?> thumbnailPath;
  final Value<String?> telegramFileId;
  final Value<int?> telegramMessageId;
  final Value<int?> telegramChatId;
  final Value<int?> telegramTopicId;
  final Value<String> mediaType;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int> fileSize;
  final Value<int?> duration;
  final Value<DateTime?> dateTaken;
  final Value<DateTime> dateAdded;
  final Value<bool> isFavorite;
  final Value<bool> isTrashed;
  final Value<String> syncStatus;
  final Value<String?> sha256Hash;
  final Value<String?> perceptualHash;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> locationName;
  final Value<String?> encryptionKeyId;
  final Value<bool> isPinnedOffline;
  final Value<String> cloudState;
  final Value<int> rowid;
  const MediaItemsCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.telegramFileId = const Value.absent(),
    this.telegramMessageId = const Value.absent(),
    this.telegramChatId = const Value.absent(),
    this.telegramTopicId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.duration = const Value.absent(),
    this.dateTaken = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isTrashed = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.sha256Hash = const Value.absent(),
    this.perceptualHash = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.locationName = const Value.absent(),
    this.encryptionKeyId = const Value.absent(),
    this.isPinnedOffline = const Value.absent(),
    this.cloudState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    required String id,
    this.filePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.telegramFileId = const Value.absent(),
    this.telegramMessageId = const Value.absent(),
    this.telegramChatId = const Value.absent(),
    this.telegramTopicId = const Value.absent(),
    required String mediaType,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    required int fileSize,
    this.duration = const Value.absent(),
    this.dateTaken = const Value.absent(),
    required DateTime dateAdded,
    this.isFavorite = const Value.absent(),
    this.isTrashed = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.sha256Hash = const Value.absent(),
    this.perceptualHash = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.locationName = const Value.absent(),
    this.encryptionKeyId = const Value.absent(),
    this.isPinnedOffline = const Value.absent(),
    this.cloudState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mediaType = Value(mediaType),
       fileSize = Value(fileSize),
       dateAdded = Value(dateAdded);
  static Insertable<MediaItem> custom({
    Expression<String>? id,
    Expression<String>? filePath,
    Expression<String>? thumbnailPath,
    Expression<String>? telegramFileId,
    Expression<int>? telegramMessageId,
    Expression<int>? telegramChatId,
    Expression<int>? telegramTopicId,
    Expression<String>? mediaType,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? fileSize,
    Expression<int>? duration,
    Expression<DateTime>? dateTaken,
    Expression<DateTime>? dateAdded,
    Expression<bool>? isFavorite,
    Expression<bool>? isTrashed,
    Expression<String>? syncStatus,
    Expression<String>? sha256Hash,
    Expression<String>? perceptualHash,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? locationName,
    Expression<String>? encryptionKeyId,
    Expression<bool>? isPinnedOffline,
    Expression<String>? cloudState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (telegramFileId != null) 'telegram_file_id': telegramFileId,
      if (telegramMessageId != null) 'telegram_message_id': telegramMessageId,
      if (telegramChatId != null) 'telegram_chat_id': telegramChatId,
      if (telegramTopicId != null) 'telegram_topic_id': telegramTopicId,
      if (mediaType != null) 'media_type': mediaType,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (fileSize != null) 'file_size': fileSize,
      if (duration != null) 'duration': duration,
      if (dateTaken != null) 'date_taken': dateTaken,
      if (dateAdded != null) 'date_added': dateAdded,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isTrashed != null) 'is_trashed': isTrashed,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (sha256Hash != null) 'sha256_hash': sha256Hash,
      if (perceptualHash != null) 'perceptual_hash': perceptualHash,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationName != null) 'location_name': locationName,
      if (encryptionKeyId != null) 'encryption_key_id': encryptionKeyId,
      if (isPinnedOffline != null) 'is_pinned_offline': isPinnedOffline,
      if (cloudState != null) 'cloud_state': cloudState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaItemsCompanion copyWith({
    Value<String>? id,
    Value<String?>? filePath,
    Value<String?>? thumbnailPath,
    Value<String?>? telegramFileId,
    Value<int?>? telegramMessageId,
    Value<int?>? telegramChatId,
    Value<int?>? telegramTopicId,
    Value<String>? mediaType,
    Value<int?>? width,
    Value<int?>? height,
    Value<int>? fileSize,
    Value<int?>? duration,
    Value<DateTime?>? dateTaken,
    Value<DateTime>? dateAdded,
    Value<bool>? isFavorite,
    Value<bool>? isTrashed,
    Value<String>? syncStatus,
    Value<String?>? sha256Hash,
    Value<String?>? perceptualHash,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? locationName,
    Value<String?>? encryptionKeyId,
    Value<bool>? isPinnedOffline,
    Value<String>? cloudState,
    Value<int>? rowid,
  }) {
    return MediaItemsCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      telegramFileId: telegramFileId ?? this.telegramFileId,
      telegramMessageId: telegramMessageId ?? this.telegramMessageId,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      telegramTopicId: telegramTopicId ?? this.telegramTopicId,
      mediaType: mediaType ?? this.mediaType,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      dateTaken: dateTaken ?? this.dateTaken,
      dateAdded: dateAdded ?? this.dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
      isTrashed: isTrashed ?? this.isTrashed,
      syncStatus: syncStatus ?? this.syncStatus,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      perceptualHash: perceptualHash ?? this.perceptualHash,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      encryptionKeyId: encryptionKeyId ?? this.encryptionKeyId,
      isPinnedOffline: isPinnedOffline ?? this.isPinnedOffline,
      cloudState: cloudState ?? this.cloudState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (telegramFileId.present) {
      map['telegram_file_id'] = Variable<String>(telegramFileId.value);
    }
    if (telegramMessageId.present) {
      map['telegram_message_id'] = Variable<int>(telegramMessageId.value);
    }
    if (telegramChatId.present) {
      map['telegram_chat_id'] = Variable<int>(telegramChatId.value);
    }
    if (telegramTopicId.present) {
      map['telegram_topic_id'] = Variable<int>(telegramTopicId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (dateTaken.present) {
      map['date_taken'] = Variable<DateTime>(dateTaken.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isTrashed.present) {
      map['is_trashed'] = Variable<bool>(isTrashed.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (sha256Hash.present) {
      map['sha256_hash'] = Variable<String>(sha256Hash.value);
    }
    if (perceptualHash.present) {
      map['perceptual_hash'] = Variable<String>(perceptualHash.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (encryptionKeyId.present) {
      map['encryption_key_id'] = Variable<String>(encryptionKeyId.value);
    }
    if (isPinnedOffline.present) {
      map['is_pinned_offline'] = Variable<bool>(isPinnedOffline.value);
    }
    if (cloudState.present) {
      map['cloud_state'] = Variable<String>(cloudState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('telegramFileId: $telegramFileId, ')
          ..write('telegramMessageId: $telegramMessageId, ')
          ..write('telegramChatId: $telegramChatId, ')
          ..write('telegramTopicId: $telegramTopicId, ')
          ..write('mediaType: $mediaType, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fileSize: $fileSize, ')
          ..write('duration: $duration, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isTrashed: $isTrashed, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('perceptualHash: $perceptualHash, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('locationName: $locationName, ')
          ..write('encryptionKeyId: $encryptionKeyId, ')
          ..write('isPinnedOffline: $isPinnedOffline, ')
          ..write('cloudState: $cloudState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlbumsTable extends Albums with TableInfo<$AlbumsTable, Album> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<int> topicId = GeneratedColumn<int>(
    'topic_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverMediaIdMeta = const VerificationMeta(
    'coverMediaId',
  );
  @override
  late final GeneratedColumn<String> coverMediaId = GeneratedColumn<String>(
    'cover_media_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateCreatedMeta = const VerificationMeta(
    'dateCreated',
  );
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
    'date_created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    topicId,
    coverMediaId,
    dateCreated,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<Album> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    }
    if (data.containsKey('cover_media_id')) {
      context.handle(
        _coverMediaIdMeta,
        coverMediaId.isAcceptableOrUnknown(
          data['cover_media_id']!,
          _coverMediaIdMeta,
        ),
      );
    }
    if (data.containsKey('date_created')) {
      context.handle(
        _dateCreatedMeta,
        dateCreated.isAcceptableOrUnknown(
          data['date_created']!,
          _dateCreatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateCreatedMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Album map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Album(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}topic_id'],
      ),
      coverMediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_media_id'],
      ),
      dateCreated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_created'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AlbumsTable createAlias(String alias) {
    return $AlbumsTable(attachedDatabase, alias);
  }
}

class Album extends DataClass implements Insertable<Album> {
  final String id;
  final String title;
  final int? topicId;
  final String? coverMediaId;
  final DateTime dateCreated;
  final int sortOrder;
  const Album({
    required this.id,
    required this.title,
    this.topicId,
    this.coverMediaId,
    required this.dateCreated,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<int>(topicId);
    }
    if (!nullToAbsent || coverMediaId != null) {
      map['cover_media_id'] = Variable<String>(coverMediaId);
    }
    map['date_created'] = Variable<DateTime>(dateCreated);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AlbumsCompanion toCompanion(bool nullToAbsent) {
    return AlbumsCompanion(
      id: Value(id),
      title: Value(title),
      topicId: topicId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicId),
      coverMediaId: coverMediaId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverMediaId),
      dateCreated: Value(dateCreated),
      sortOrder: Value(sortOrder),
    );
  }

  factory Album.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Album(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      topicId: serializer.fromJson<int?>(json['topicId']),
      coverMediaId: serializer.fromJson<String?>(json['coverMediaId']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'topicId': serializer.toJson<int?>(topicId),
      'coverMediaId': serializer.toJson<String?>(coverMediaId),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Album copyWith({
    String? id,
    String? title,
    Value<int?> topicId = const Value.absent(),
    Value<String?> coverMediaId = const Value.absent(),
    DateTime? dateCreated,
    int? sortOrder,
  }) => Album(
    id: id ?? this.id,
    title: title ?? this.title,
    topicId: topicId.present ? topicId.value : this.topicId,
    coverMediaId: coverMediaId.present ? coverMediaId.value : this.coverMediaId,
    dateCreated: dateCreated ?? this.dateCreated,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Album copyWithCompanion(AlbumsCompanion data) {
    return Album(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      coverMediaId: data.coverMediaId.present
          ? data.coverMediaId.value
          : this.coverMediaId,
      dateCreated: data.dateCreated.present
          ? data.dateCreated.value
          : this.dateCreated,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Album(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('topicId: $topicId, ')
          ..write('coverMediaId: $coverMediaId, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, topicId, coverMediaId, dateCreated, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Album &&
          other.id == this.id &&
          other.title == this.title &&
          other.topicId == this.topicId &&
          other.coverMediaId == this.coverMediaId &&
          other.dateCreated == this.dateCreated &&
          other.sortOrder == this.sortOrder);
}

class AlbumsCompanion extends UpdateCompanion<Album> {
  final Value<String> id;
  final Value<String> title;
  final Value<int?> topicId;
  final Value<String?> coverMediaId;
  final Value<DateTime> dateCreated;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AlbumsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.topicId = const Value.absent(),
    this.coverMediaId = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlbumsCompanion.insert({
    required String id,
    required String title,
    this.topicId = const Value.absent(),
    this.coverMediaId = const Value.absent(),
    required DateTime dateCreated,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       dateCreated = Value(dateCreated);
  static Insertable<Album> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? topicId,
    Expression<String>? coverMediaId,
    Expression<DateTime>? dateCreated,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (topicId != null) 'topic_id': topicId,
      if (coverMediaId != null) 'cover_media_id': coverMediaId,
      if (dateCreated != null) 'date_created': dateCreated,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlbumsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int?>? topicId,
    Value<String?>? coverMediaId,
    Value<DateTime>? dateCreated,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AlbumsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      topicId: topicId ?? this.topicId,
      coverMediaId: coverMediaId ?? this.coverMediaId,
      dateCreated: dateCreated ?? this.dateCreated,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<int>(topicId.value);
    }
    if (coverMediaId.present) {
      map['cover_media_id'] = Variable<String>(coverMediaId.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('topicId: $topicId, ')
          ..write('coverMediaId: $coverMediaId, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaAlbumRelationsTable extends MediaAlbumRelations
    with TableInfo<$MediaAlbumRelationsTable, MediaAlbumRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaAlbumRelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [mediaId, albumId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_album_relations';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaAlbumRelation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId, albumId};
  @override
  MediaAlbumRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaAlbumRelation(
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      )!,
    );
  }

  @override
  $MediaAlbumRelationsTable createAlias(String alias) {
    return $MediaAlbumRelationsTable(attachedDatabase, alias);
  }
}

class MediaAlbumRelation extends DataClass
    implements Insertable<MediaAlbumRelation> {
  final String mediaId;
  final String albumId;
  const MediaAlbumRelation({required this.mediaId, required this.albumId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<String>(mediaId);
    map['album_id'] = Variable<String>(albumId);
    return map;
  }

  MediaAlbumRelationsCompanion toCompanion(bool nullToAbsent) {
    return MediaAlbumRelationsCompanion(
      mediaId: Value(mediaId),
      albumId: Value(albumId),
    );
  }

  factory MediaAlbumRelation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaAlbumRelation(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      albumId: serializer.fromJson<String>(json['albumId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'albumId': serializer.toJson<String>(albumId),
    };
  }

  MediaAlbumRelation copyWith({String? mediaId, String? albumId}) =>
      MediaAlbumRelation(
        mediaId: mediaId ?? this.mediaId,
        albumId: albumId ?? this.albumId,
      );
  MediaAlbumRelation copyWithCompanion(MediaAlbumRelationsCompanion data) {
    return MediaAlbumRelation(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaAlbumRelation(')
          ..write('mediaId: $mediaId, ')
          ..write('albumId: $albumId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaId, albumId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaAlbumRelation &&
          other.mediaId == this.mediaId &&
          other.albumId == this.albumId);
}

class MediaAlbumRelationsCompanion extends UpdateCompanion<MediaAlbumRelation> {
  final Value<String> mediaId;
  final Value<String> albumId;
  final Value<int> rowid;
  const MediaAlbumRelationsCompanion({
    this.mediaId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaAlbumRelationsCompanion.insert({
    required String mediaId,
    required String albumId,
    this.rowid = const Value.absent(),
  }) : mediaId = Value(mediaId),
       albumId = Value(albumId);
  static Insertable<MediaAlbumRelation> custom({
    Expression<String>? mediaId,
    Expression<String>? albumId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (albumId != null) 'album_id': albumId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaAlbumRelationsCompanion copyWith({
    Value<String>? mediaId,
    Value<String>? albumId,
    Value<int>? rowid,
  }) {
    return MediaAlbumRelationsCompanion(
      mediaId: mediaId ?? this.mediaId,
      albumId: albumId ?? this.albumId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaAlbumRelationsCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('albumId: $albumId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskTypeMeta = const VerificationMeta(
    'taskType',
  );
  @override
  late final GeneratedColumn<String> taskType = GeneratedColumn<String>(
    'task_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaId,
    taskType,
    status,
    retryCount,
    priority,
    progress,
    errorMessage,
    createdAt,
    lastAttemptAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('task_type')) {
      context.handle(
        _taskTypeMeta,
        taskType.isAcceptableOrUnknown(data['task_type']!, _taskTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_taskTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      taskType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;
  final String mediaId;
  final String taskType;
  final String status;
  final int retryCount;
  final int priority;
  final double progress;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  const SyncQueueData({
    required this.id,
    required this.mediaId,
    required this.taskType,
    required this.status,
    required this.retryCount,
    required this.priority,
    required this.progress,
    this.errorMessage,
    required this.createdAt,
    this.lastAttemptAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['media_id'] = Variable<String>(mediaId);
    map['task_type'] = Variable<String>(taskType);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    map['priority'] = Variable<int>(priority);
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      mediaId: Value(mediaId),
      taskType: Value(taskType),
      status: Value(status),
      retryCount: Value(retryCount),
      priority: Value(priority),
      progress: Value(progress),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      taskType: serializer.fromJson<String>(json['taskType']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      priority: serializer.fromJson<int>(json['priority']),
      progress: serializer.fromJson<double>(json['progress']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mediaId': serializer.toJson<String>(mediaId),
      'taskType': serializer.toJson<String>(taskType),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'priority': serializer.toJson<int>(priority),
      'progress': serializer.toJson<double>(progress),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
    };
  }

  SyncQueueData copyWith({
    String? id,
    String? mediaId,
    String? taskType,
    String? status,
    int? retryCount,
    int? priority,
    double? progress,
    Value<String?> errorMessage = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
  }) => SyncQueueData(
    id: id ?? this.id,
    mediaId: mediaId ?? this.mediaId,
    taskType: taskType ?? this.taskType,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    priority: priority ?? this.priority,
    progress: progress ?? this.progress,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      priority: data.priority.present ? data.priority.value : this.priority,
      progress: data.progress.present ? data.progress.value : this.progress,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('mediaId: $mediaId, ')
          ..write('taskType: $taskType, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('priority: $priority, ')
          ..write('progress: $progress, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mediaId,
    taskType,
    status,
    retryCount,
    priority,
    progress,
    errorMessage,
    createdAt,
    lastAttemptAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.mediaId == this.mediaId &&
          other.taskType == this.taskType &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.priority == this.priority &&
          other.progress == this.progress &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> mediaId;
  final Value<String> taskType;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<int> priority;
  final Value<double> progress;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.taskType = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.priority = const Value.absent(),
    this.progress = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String mediaId,
    required String taskType,
    required String status,
    this.retryCount = const Value.absent(),
    this.priority = const Value.absent(),
    this.progress = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mediaId = Value(mediaId),
       taskType = Value(taskType),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? mediaId,
    Expression<String>? taskType,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<int>? priority,
    Expression<double>? progress,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaId != null) 'media_id': mediaId,
      if (taskType != null) 'task_type': taskType,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (priority != null) 'priority': priority,
      if (progress != null) 'progress': progress,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? mediaId,
    Value<String>? taskType,
    Value<String>? status,
    Value<int>? retryCount,
    Value<int>? priority,
    Value<double>? progress,
    Value<String?>? errorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      taskType: taskType ?? this.taskType,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<String>(taskType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('mediaId: $mediaId, ')
          ..write('taskType: $taskType, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('priority: $priority, ')
          ..write('progress: $progress, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  late final $AlbumsTable albums = $AlbumsTable(this);
  late final $MediaAlbumRelationsTable mediaAlbumRelations =
      $MediaAlbumRelationsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    mediaItems,
    albums,
    mediaAlbumRelations,
    syncQueue,
  ];
}

typedef $$MediaItemsTableCreateCompanionBuilder = MediaItemsCompanion Function({
  required String id,
  Value<String?> filePath,
  Value<String?> thumbnailPath,
  Value<String?> telegramFileId,
  Value<int?> telegramMessageId,
  Value<int?> telegramChatId,
  Value<int?> telegramTopicId,
  required String mediaType,
  Value<int?> width,
  Value<int?> height,
  required int fileSize,
  Value<int?> duration,
  Value<DateTime?> dateTaken,
  required DateTime dateAdded,
  Value<bool> isFavorite,
  Value<bool> isTrashed,
  Value<String> syncStatus,
  Value<String?> sha256Hash,
  Value<String?> perceptualHash,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> locationName,
  Value<String?> encryptionKeyId,
  Value<bool> isPinnedOffline,
  Value<String> cloudState,
  Value<int> rowid,
});
typedef $$MediaItemsTableUpdateCompanionBuilder = MediaItemsCompanion Function({
  Value<String> id,
  Value<String?> filePath,
  Value<String?> thumbnailPath,
  Value<String?> telegramFileId,
  Value<int?> telegramMessageId,
  Value<int?> telegramChatId,
  Value<int?> telegramTopicId,
  Value<String> mediaType,
  Value<int?> width,
  Value<int?> height,
  Value<int> fileSize,
  Value<int?> duration,
  Value<DateTime?> dateTaken,
  Value<DateTime> dateAdded,
  Value<bool> isFavorite,
  Value<bool> isTrashed,
  Value<String> syncStatus,
  Value<String?> sha256Hash,
  Value<String?> perceptualHash,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> locationName,
  Value<String?> encryptionKeyId,
  Value<bool> isPinnedOffline,
  Value<String> cloudState,
  Value<int> rowid,
});

class $$MediaItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telegramFileId => $composableBuilder(
    column: $table.telegramFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get telegramMessageId => $composableBuilder(
    column: $table.telegramMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get telegramChatId => $composableBuilder(
    column: $table.telegramChatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get telegramTopicId => $composableBuilder(
    column: $table.telegramTopicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTrashed => $composableBuilder(
    column: $table.isTrashed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get perceptualHash => $composableBuilder(
    column: $table.perceptualHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptionKeyId => $composableBuilder(
    column: $table.encryptionKeyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinnedOffline => $composableBuilder(
    column: $table.isPinnedOffline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudState => $composableBuilder(
    column: $table.cloudState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telegramFileId => $composableBuilder(
    column: $table.telegramFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get telegramMessageId => $composableBuilder(
    column: $table.telegramMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get telegramChatId => $composableBuilder(
    column: $table.telegramChatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get telegramTopicId => $composableBuilder(
    column: $table.telegramTopicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTrashed => $composableBuilder(
    column: $table.isTrashed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get perceptualHash => $composableBuilder(
    column: $table.perceptualHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptionKeyId => $composableBuilder(
    column: $table.encryptionKeyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinnedOffline => $composableBuilder(
    column: $table.isPinnedOffline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudState => $composableBuilder(
    column: $table.cloudState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get telegramFileId => $composableBuilder(
    column: $table.telegramFileId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get telegramMessageId => $composableBuilder(
    column: $table.telegramMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get telegramChatId => $composableBuilder(
    column: $table.telegramChatId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get telegramTopicId => $composableBuilder(
    column: $table.telegramTopicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<DateTime> get dateTaken =>
      $composableBuilder(column: $table.dateTaken, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTrashed =>
      $composableBuilder(column: $table.isTrashed, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get perceptualHash => $composableBuilder(
    column: $table.perceptualHash,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get encryptionKeyId => $composableBuilder(
    column: $table.encryptionKeyId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinnedOffline => $composableBuilder(
    column: $table.isPinnedOffline,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudState => $composableBuilder(
    column: $table.cloudState,
    builder: (column) => column,
  );
}

class $$MediaItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaItemsTable,
          MediaItem,
          $$MediaItemsTableFilterComposer,
          $$MediaItemsTableOrderingComposer,
          $$MediaItemsTableAnnotationComposer,
          $$MediaItemsTableCreateCompanionBuilder,
          $$MediaItemsTableUpdateCompanionBuilder,
          (
            MediaItem,
            BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem>,
          ),
          MediaItem,
          PrefetchHooks Function()
        > {
  $$MediaItemsTableTableManager(_$AppDatabase db, $MediaItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> telegramFileId = const Value.absent(),
                Value<int?> telegramMessageId = const Value.absent(),
                Value<int?> telegramChatId = const Value.absent(),
                Value<int?> telegramTopicId = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<DateTime?> dateTaken = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isTrashed = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> sha256Hash = const Value.absent(),
                Value<String?> perceptualHash = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<String?> encryptionKeyId = const Value.absent(),
                Value<bool> isPinnedOffline = const Value.absent(),
                Value<String> cloudState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaItemsCompanion(
                id: id,
                filePath: filePath,
                thumbnailPath: thumbnailPath,
                telegramFileId: telegramFileId,
                telegramMessageId: telegramMessageId,
                telegramChatId: telegramChatId,
                telegramTopicId: telegramTopicId,
                mediaType: mediaType,
                width: width,
                height: height,
                fileSize: fileSize,
                duration: duration,
                dateTaken: dateTaken,
                dateAdded: dateAdded,
                isFavorite: isFavorite,
                isTrashed: isTrashed,
                syncStatus: syncStatus,
                sha256Hash: sha256Hash,
                perceptualHash: perceptualHash,
                latitude: latitude,
                longitude: longitude,
                locationName: locationName,
                encryptionKeyId: encryptionKeyId,
                isPinnedOffline: isPinnedOffline,
                cloudState: cloudState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> filePath = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> telegramFileId = const Value.absent(),
                Value<int?> telegramMessageId = const Value.absent(),
                Value<int?> telegramChatId = const Value.absent(),
                Value<int?> telegramTopicId = const Value.absent(),
                required String mediaType,
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                required int fileSize,
                Value<int?> duration = const Value.absent(),
                Value<DateTime?> dateTaken = const Value.absent(),
                required DateTime dateAdded,
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isTrashed = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> sha256Hash = const Value.absent(),
                Value<String?> perceptualHash = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<String?> encryptionKeyId = const Value.absent(),
                Value<bool> isPinnedOffline = const Value.absent(),
                Value<String> cloudState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaItemsCompanion.insert(
                id: id,
                filePath: filePath,
                thumbnailPath: thumbnailPath,
                telegramFileId: telegramFileId,
                telegramMessageId: telegramMessageId,
                telegramChatId: telegramChatId,
                telegramTopicId: telegramTopicId,
                mediaType: mediaType,
                width: width,
                height: height,
                fileSize: fileSize,
                duration: duration,
                dateTaken: dateTaken,
                dateAdded: dateAdded,
                isFavorite: isFavorite,
                isTrashed: isTrashed,
                syncStatus: syncStatus,
                sha256Hash: sha256Hash,
                perceptualHash: perceptualHash,
                latitude: latitude,
                longitude: longitude,
                locationName: locationName,
                encryptionKeyId: encryptionKeyId,
                isPinnedOffline: isPinnedOffline,
                cloudState: cloudState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaItemsTable, MediaItem>(table),
                  BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaItemsTable,
      MediaItem,
      $$MediaItemsTableFilterComposer,
      $$MediaItemsTableOrderingComposer,
      $$MediaItemsTableAnnotationComposer,
      $$MediaItemsTableCreateCompanionBuilder,
      $$MediaItemsTableUpdateCompanionBuilder,
      (MediaItem, BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem>),
      MediaItem,
      PrefetchHooks Function()
    >;
typedef $$AlbumsTableCreateCompanionBuilder = AlbumsCompanion Function({
  required String id,
  required String title,
  Value<int?> topicId,
  Value<String?> coverMediaId,
  required DateTime dateCreated,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$AlbumsTableUpdateCompanionBuilder = AlbumsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<int?> topicId,
  Value<String?> coverMediaId,
  Value<DateTime> dateCreated,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$AlbumsTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverMediaId => $composableBuilder(
    column: $table.coverMediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlbumsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverMediaId => $composableBuilder(
    column: $table.coverMediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlbumsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get coverMediaId => $composableBuilder(
    column: $table.coverMediaId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$AlbumsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumsTable,
          Album,
          $$AlbumsTableFilterComposer,
          $$AlbumsTableOrderingComposer,
          $$AlbumsTableAnnotationComposer,
          $$AlbumsTableCreateCompanionBuilder,
          $$AlbumsTableUpdateCompanionBuilder,
          (Album, BaseReferences<_$AppDatabase, $AlbumsTable, Album>),
          Album,
          PrefetchHooks Function()
        > {
  $$AlbumsTableTableManager(_$AppDatabase db, $AlbumsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int?> topicId = const Value.absent(),
                Value<String?> coverMediaId = const Value.absent(),
                Value<DateTime> dateCreated = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlbumsCompanion(
                id: id,
                title: title,
                topicId: topicId,
                coverMediaId: coverMediaId,
                dateCreated: dateCreated,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<int?> topicId = const Value.absent(),
                Value<String?> coverMediaId = const Value.absent(),
                required DateTime dateCreated,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlbumsCompanion.insert(
                id: id,
                title: title,
                topicId: topicId,
                coverMediaId: coverMediaId,
                dateCreated: dateCreated,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlbumsTable, Album>(table),
                  BaseReferences<_$AppDatabase, $AlbumsTable, Album>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlbumsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumsTable,
      Album,
      $$AlbumsTableFilterComposer,
      $$AlbumsTableOrderingComposer,
      $$AlbumsTableAnnotationComposer,
      $$AlbumsTableCreateCompanionBuilder,
      $$AlbumsTableUpdateCompanionBuilder,
      (Album, BaseReferences<_$AppDatabase, $AlbumsTable, Album>),
      Album,
      PrefetchHooks Function()
    >;
typedef $$MediaAlbumRelationsTableCreateCompanionBuilder =
    MediaAlbumRelationsCompanion Function({
      required String mediaId,
      required String albumId,
      Value<int> rowid,
    });
typedef $$MediaAlbumRelationsTableUpdateCompanionBuilder =
    MediaAlbumRelationsCompanion Function({
      Value<String> mediaId,
      Value<String> albumId,
      Value<int> rowid,
    });

class $$MediaAlbumRelationsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaAlbumRelationsTable> {
  $$MediaAlbumRelationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaAlbumRelationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaAlbumRelationsTable> {
  $$MediaAlbumRelationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaAlbumRelationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaAlbumRelationsTable> {
  $$MediaAlbumRelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);
}

class $$MediaAlbumRelationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaAlbumRelationsTable,
          MediaAlbumRelation,
          $$MediaAlbumRelationsTableFilterComposer,
          $$MediaAlbumRelationsTableOrderingComposer,
          $$MediaAlbumRelationsTableAnnotationComposer,
          $$MediaAlbumRelationsTableCreateCompanionBuilder,
          $$MediaAlbumRelationsTableUpdateCompanionBuilder,
          (
            MediaAlbumRelation,
            BaseReferences<
              _$AppDatabase,
              $MediaAlbumRelationsTable,
              MediaAlbumRelation
            >,
          ),
          MediaAlbumRelation,
          PrefetchHooks Function()
        > {
  $$MediaAlbumRelationsTableTableManager(
    _$AppDatabase db,
    $MediaAlbumRelationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaAlbumRelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaAlbumRelationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MediaAlbumRelationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> mediaId = const Value.absent(),
                Value<String> albumId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaAlbumRelationsCompanion(
                mediaId: mediaId,
                albumId: albumId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mediaId,
                required String albumId,
                Value<int> rowid = const Value.absent(),
              }) => MediaAlbumRelationsCompanion.insert(
                mediaId: mediaId,
                albumId: albumId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaAlbumRelationsTable, MediaAlbumRelation>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $MediaAlbumRelationsTable,
                    MediaAlbumRelation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaAlbumRelationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaAlbumRelationsTable,
      MediaAlbumRelation,
      $$MediaAlbumRelationsTableFilterComposer,
      $$MediaAlbumRelationsTableOrderingComposer,
      $$MediaAlbumRelationsTableAnnotationComposer,
      $$MediaAlbumRelationsTableCreateCompanionBuilder,
      $$MediaAlbumRelationsTableUpdateCompanionBuilder,
      (
        MediaAlbumRelation,
        BaseReferences<
          _$AppDatabase,
          $MediaAlbumRelationsTable,
          MediaAlbumRelation
        >,
      ),
      MediaAlbumRelation,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String id,
  required String mediaId,
  required String taskType,
  required String status,
  Value<int> retryCount,
  Value<int> priority,
  Value<double> progress,
  Value<String?> errorMessage,
  required DateTime createdAt,
  Value<DateTime?> lastAttemptAt,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> id,
  Value<String> mediaId,
  Value<String> taskType,
  Value<String> status,
  Value<int> retryCount,
  Value<int> priority,
  Value<double> progress,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<DateTime?> lastAttemptAt,
  Value<int> rowid,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get taskType =>
      $composableBuilder(column: $table.taskType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<String> taskType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                mediaId: mediaId,
                taskType: taskType,
                status: status,
                retryCount: retryCount,
                priority: priority,
                progress: progress,
                errorMessage: errorMessage,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mediaId,
                required String taskType,
                required String status,
                Value<int> retryCount = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                mediaId: mediaId,
                taskType: taskType,
                status: status,
                retryCount: retryCount,
                priority: priority,
                progress: progress,
                errorMessage: errorMessage,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueTable, SyncQueueData>(table),
                  BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
  $$AlbumsTableTableManager get albums =>
      $$AlbumsTableTableManager(_db, _db.albums);
  $$MediaAlbumRelationsTableTableManager get mediaAlbumRelations =>
      $$MediaAlbumRelationsTableTableManager(_db, _db.mediaAlbumRelations);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
