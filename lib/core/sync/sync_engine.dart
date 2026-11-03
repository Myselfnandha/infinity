// This code for managing background sync queue, Telegram upload pipeline, and network condition guards
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../settings/app_preferences.dart';
import '../storage/cloud_media_cache_manager.dart';
import '../telegram/tdlib_service.dart';

// This code for orchestrating the media synchronization engine
class SyncEngine {
  final AppDatabase _db;
  final TdlibService _tdlib;
  final AppPreferences _prefs;
  final CloudMediaCacheManager _cacheManager;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  bool _isProcessing = false;
  StreamSubscription? _queueSubscription;

  SyncEngine(this._db, this._tdlib, this._prefs, this._cacheManager);

  // This code for starting the reactive queue processor stream listener
  void startQueueProcessor() {
    _queueSubscription?.cancel();
    _queueSubscription = _db.watchPendingSyncTasks().listen((tasks) {
      if (tasks.isNotEmpty && !_isProcessing) {
        processNextTask();
      }
    });
  }

  // This code for stopping the sync queue processor
  void stopQueueProcessor() {
    _queueSubscription?.cancel();
  }

  // This code for enqueuing a media item for upload to Telegram
  Future<void> queueUpload({
    required String mediaId,
    int priority = 0,
  }) async {
    final existing = await (_db.select(_db.syncQueue)
          ..where((tbl) =>
              tbl.mediaId.equals(mediaId) &
              (tbl.status.equals('pending') | tbl.status.equals('inProgress'))))
        .getSingleOrNull();

    if (existing != null) return;

    await _db.insertSyncTask(
      SyncQueueCompanion.insert(
        id: _uuid.v4(),
        mediaId: mediaId,
        taskType: 'upload',
        status: 'pending',
        priority: Value(priority),
        createdAt: DateTime.now(),
      ),
    );

    await _db.setCloudState(mediaId, 'QUEUED');
  }

  // This code for verifying whether current active network matches sync preferences (e.g. Wi-Fi only)
  Future<bool> _canSyncUnderCurrentNetwork() async {
    final connectivity = await Connectivity().checkConnectivity();
    final isWifi = connectivity.contains(ConnectivityResult.wifi);
    final isMobile = connectivity.contains(ConnectivityResult.mobile);

    if (_prefs.isWifiOnly && !isWifi) {
      return false;
    }

    if (!isWifi && !isMobile) {
      return false;
    }

    return true;
  }

  // This code for generating SHA-256 hash to deduplicate media files before uploading
  Future<String> calculateSha256(String filePath) async {
    final file = File(filePath);
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString();
  }

  // This code for processing the next pending upload task with retries and exponential backoff
  Future<void> processNextTask() async {
    if (_isProcessing) return;

    final canSync = await _canSyncUnderCurrentNetwork();
    if (!canSync) return;

    _isProcessing = true;

    try {
      final tasks = await (_db.select(_db.syncQueue)
            ..where((tbl) => tbl.status.equals('pending'))
            ..orderBy([
              (tbl) => OrderingTerm(expression: tbl.priority, mode: OrderingMode.desc),
              (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc)
            ])
            ..limit(1))
          .get();

      if (tasks.isEmpty) {
        _isProcessing = false;
        return;
      }

      final task = tasks.first;
      final media = await _db.getMediaItem(task.mediaId);

      if (media == null || media.filePath == null) {
        await _db.updateTaskStatus(
          task.id,
          'failed',
          errorMessage: 'Media file not found on device',
          lastAttemptAt: DateTime.now(),
        );
        _isProcessing = false;
        return;
      }

      await _db.updateTaskStatus(
        task.id,
        'inProgress',
        lastAttemptAt: DateTime.now(),
      );
      await _db.setCloudState(media.id, 'UPLOADING');

      final fileHash = await calculateSha256(media.filePath!);
      final existingDeduplicated = await _db.getMediaByHash(fileHash);

      if (existingDeduplicated != null &&
          existingDeduplicated.id != media.id &&
          existingDeduplicated.telegramMessageId != null) {
        await _db.updateSyncStatus(
          media.id,
          'synced',
          telegramFileId: existingDeduplicated.telegramFileId,
          telegramMessageId: existingDeduplicated.telegramMessageId,
          telegramChatId: existingDeduplicated.telegramChatId,
          telegramTopicId: existingDeduplicated.telegramTopicId,
        );
        await (_db.update(_db.mediaItems)..where((tbl) => tbl.id.equals(media.id)))
            .write(MediaItemsCompanion(sha256Hash: Value(fileHash)));
        await _db.setCloudState(media.id, 'AVAILABLE_LOCALLY');
        await _db.deleteSyncTask(task.id);
        _isProcessing = false;
        processNextTask();
        return;
      }

      final topicId = _tdlib.topicMap[1] ?? 1;
      final message = await _tdlib.uploadMedia(
        filePath: media.filePath!,
        mediaType: media.mediaType,
        topicId: topicId,
        caption: '#infinity #${media.mediaType}',
      );

      if (message != null) {
        await _db.updateSyncStatus(
          media.id,
          'synced',
          telegramMessageId: message.id,
          telegramChatId: message.chatId,
          telegramTopicId: topicId,
        );
        await (_db.update(_db.mediaItems)..where((tbl) => tbl.id.equals(media.id)))
            .write(MediaItemsCompanion(sha256Hash: Value(fileHash)));
        await _db.setCloudState(media.id, 'AVAILABLE_LOCALLY');
        await _db.deleteSyncTask(task.id);
        await _cacheManager.enforceCacheLimits();
      } else {
        await _handleTaskFailure(task, 'Upload returned null message');
      }
    } catch (e) {
      final tasks = await (_db.select(_db.syncQueue)
            ..where((tbl) => tbl.status.equals('inProgress'))
            ..limit(1))
          .get();
      if (tasks.isNotEmpty) {
        await _handleTaskFailure(tasks.first, e.toString());
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _handleTaskFailure(SyncQueueData task, String error) async {
    final nextRetry = task.retryCount + 1;
    if (nextRetry > 5) {
      await _db.updateTaskStatus(
        task.id,
        'failed',
        errorMessage: error,
        lastAttemptAt: DateTime.now(),
        retryCount: nextRetry,
      );
      await _db.setCloudState(task.mediaId, 'FAILED');
    } else {
      final backoffSeconds = pow(2, nextRetry).toInt() * 2 + _random.nextInt(3);
      await _db.updateTaskStatus(
        task.id,
        'pending',
        errorMessage: error,
        lastAttemptAt: DateTime.now().add(Duration(seconds: backoffSeconds)),
        retryCount: nextRetry,
      );
      await _db.setCloudState(task.mediaId, 'QUEUED');
    }
  }

  Future<void> autoQueueUnsynced() async {
    final unsynced = await _db.getUnsyncedMedia();
    for (final item in unsynced) {
      await queueUpload(mediaId: item.id, priority: 0);
    }
  }
}
