import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:handy_tdlib_next/handy_tdlib_next.dart' hide File;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../settings/app_preferences.dart';
import '../storage/cloud_media_cache_manager.dart';
import '../telegram/tdlib_service.dart';

/// Real-time upload operational telemetry state tracking active workers, throughput, and progress.
class UploadTelemetryState {
  final int completedCount;
  final int totalCount;
  final int activeWorkers;
  final double speedKBps;
  final String currentFileName;
  final int bytesTransferredTotal;
  final bool isPaused;

  const UploadTelemetryState({
    this.completedCount = 0,
    this.totalCount = 0,
    this.activeWorkers = 0,
    this.speedKBps = 0.0,
    this.currentFileName = '',
    this.bytesTransferredTotal = 0,
    this.isPaused = false,
  });

  double get progressPercentage =>
      totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

  String get speedFormatted {
    if (speedKBps >= 1024) {
      return '${(speedKBps / 1024).toStringAsFixed(1)} MB/s';
    }
    return '${speedKBps.toStringAsFixed(0)} KB/s';
  }
}

// Alias for seamless compatibility with telecloud_photos widgets
typedef UploadProgressState = UploadTelemetryState;

// This code for orchestrating the media synchronization engine
class SyncEngine {
  final AppDatabase _db;
  final TdlibService _tdlib;
  final AppPreferences _prefs;
  final CloudMediaCacheManager _cacheManager;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  bool _isProcessing = false;
  bool _isDisposed = false;
  bool _isPaused = false;
  bool get isPaused => _isPaused;

  StreamSubscription? _queueSubscription;
  StreamSubscription? _fileUpdateSubscription;
  Timer? _wakeupTimer;

  UploadTelemetryState _telemetryState = const UploadTelemetryState();
  UploadTelemetryState get currentTelemetry => _telemetryState;

  final StreamController<UploadTelemetryState> _telemetryController =
      StreamController<UploadTelemetryState>.broadcast();
  Stream<UploadTelemetryState> get telemetryStream => _telemetryController.stream;

  int _lastBytesTransferred = 0;
  DateTime _lastSpeedCalcTime = DateTime.now();

  SyncEngine(this._db, this._tdlib, this._prefs, this._cacheManager);

  void _updateTelemetry({
    int? completedCount,
    int? totalCount,
    int? activeWorkers,
    double? speedKBps,
    String? currentFileName,
    int? bytesTransferredTotal,
    bool? isPaused,
  }) {
    _telemetryState = UploadTelemetryState(
      completedCount: completedCount ?? _telemetryState.completedCount,
      totalCount: totalCount ?? _telemetryState.totalCount,
      activeWorkers: activeWorkers ?? _telemetryState.activeWorkers,
      speedKBps: speedKBps ?? _telemetryState.speedKBps,
      currentFileName: currentFileName ?? _telemetryState.currentFileName,
      bytesTransferredTotal:
          bytesTransferredTotal ?? _telemetryState.bytesTransferredTotal,
      isPaused: isPaused ?? _telemetryState.isPaused,
    );
    if (!_telemetryController.isClosed) {
      _telemetryController.add(_telemetryState);
    }
  }

  Future<void> _refreshTelemetryCounts() async {
    try {
      final pending = await (_db.select(_db.syncQueue)
            ..where((tbl) =>
                tbl.status.equals('pending') | tbl.status.equals('inProgress')))
          .get();
      final synced = await (_db.select(_db.mediaItems)
            ..where((tbl) => tbl.syncStatus.equals('synced')))
          .get();
      _updateTelemetry(
        totalCount: pending.length + synced.length,
        completedCount: synced.length,
      );
    } catch (_) {}
  }

  void _handleFileUpdate(UpdateFile update) {
    final remote = update.file.remote;
    final now = DateTime.now();
    final elapsedMs = now.difference(_lastSpeedCalcTime).inMilliseconds;

    if (elapsedMs >= 500) {
      final currentUploaded = remote.uploadedSize;
      final deltaBytes =
          (currentUploaded - _lastBytesTransferred).clamp(0, 500000000);
      final speedKBps = elapsedMs > 0
          ? (deltaBytes / (elapsedMs / 1000.0)) / 1024.0
          : 0.0;

      _lastBytesTransferred = currentUploaded;
      _lastSpeedCalcTime = now;

      _updateTelemetry(
        speedKBps: speedKBps,
        bytesTransferredTotal:
            _telemetryState.bytesTransferredTotal + deltaBytes,
      );
      _updateForegroundNotification();
    }
  }

  /// Pauses all ongoing and queued sync transmissions.
  void pauseSync() {
    _isPaused = true;
    _updateTelemetry(isPaused: true, activeWorkers: 0, speedKBps: 0.0);
    _updateForegroundNotification();
  }

  /// Resumes the upload pipeline and triggers queue processing.
  void resumeSync() {
    _isPaused = false;
    _updateTelemetry(isPaused: false);
    _updateForegroundNotification();
    if (!_isProcessing) {
      processNextTask();
    }
  }

  // Updates active Android notification with upload speed and current status
  Future<void> _updateForegroundNotification() async {
    try {
      if (!Platform.isAndroid) return;
      if (!await FlutterForegroundTask.isRunningService) {
        if (_telemetryState.activeWorkers > 0 && !_telemetryState.isPaused) {
          await FlutterForegroundTask.startService(
            notificationTitle: 'Infinity Vault Sync',
            notificationText:
                'Uploading: ${_telemetryState.currentFileName} (${_telemetryState.speedFormatted})',
          );
        }
      } else {
        if (_telemetryState.isPaused) {
          await FlutterForegroundTask.updateService(
            notificationTitle: 'Infinity Vault Sync',
            notificationText: 'Upload paused by user',
          );
        } else if (_telemetryState.activeWorkers > 0) {
          await FlutterForegroundTask.updateService(
            notificationTitle: 'Infinity Vault Sync',
            notificationText:
                'Uploading: ${_telemetryState.currentFileName} (${_telemetryState.speedFormatted})',
          );
        } else {
          await FlutterForegroundTask.updateService(
            notificationTitle: 'Infinity Vault Sync',
            notificationText: 'Sync idle. Photos and videos backed up.',
          );
        }
      }
    } catch (_) {}
  }

  /// Starts the reactive queue processor stream listener.
  void startQueueProcessor() {
    _isDisposed = false;
    _queueSubscription?.cancel();
    _fileUpdateSubscription?.cancel();
    _fileUpdateSubscription = _tdlib.fileUpdateStream.listen((update) {
      _handleFileUpdate(update);
    });
    _queueSubscription = _db.watchPendingSyncTasks().listen((tasks) {
      _refreshTelemetryCounts();
      if (tasks.isNotEmpty && !_isProcessing && !_isPaused) {
        processNextTask();
      }
    });
    _refreshTelemetryCounts();
  }

  /// Stops the sync queue processor.
  void stopQueueProcessor() {
    _isDisposed = true;
    _queueSubscription?.cancel();
    _fileUpdateSubscription?.cancel();
    _wakeupTimer?.cancel();
  }

  /// Enqueues a media item for upload to Telegram.
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
    await _refreshTelemetryCounts();
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

  // This code for processing the pending upload queue until exhausted or blocked
  Future<void> processNextTask() async {
    if (_isProcessing || _isDisposed || _isPaused) return;

    final canSync = await _canSyncUnderCurrentNetwork();
    if (!canSync || _isDisposed || _isPaused) return;

    _isProcessing = true;

    try {
      while (!_isDisposed && !_isPaused) {
        final canStillSync = await _canSyncUnderCurrentNetwork();
        if (!canStillSync || _isDisposed || _isPaused) break;

        final hasMore = await _processSingleTask();
        if (!hasMore || _isDisposed || _isPaused) break;
      }
    } finally {
      _isProcessing = false;
      if (!_isPaused) {
        _updateTelemetry(activeWorkers: 0);
        _updateForegroundNotification();
      }
    }
  }

  // This code for processing a single pending task in the queue; returns true if a task was handled
  Future<bool> _processSingleTask() async {
    if (_isPaused || _isDisposed) return false;

    final now = DateTime.now();
    final tasks = await (_db.select(_db.syncQueue)
          ..where((tbl) =>
              tbl.status.equals('pending') &
              (tbl.lastAttemptAt.isNull() |
                  tbl.lastAttemptAt.isSmallerOrEqualValue(now)))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.priority, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(
                expression: tbl.createdAt, mode: OrderingMode.asc)
          ])
          ..limit(1))
        .get();

    if (tasks.isEmpty) {
      await _scheduleNextBackoffWakeup(now);
      _updateTelemetry(activeWorkers: 0);
      _updateForegroundNotification();
      return false;
    }

    final task = tasks.first;
    final media = await _db.getMediaItem(task.mediaId);

    // This code for verifying local file existence on device before attempting upload
    if (media == null ||
        media.filePath == null ||
        !await File(media.filePath!).exists()) {
      await _db.updateTaskStatus(
        task.id,
        'failed',
        errorMessage: 'Media file not found on device',
        lastAttemptAt: DateTime.now(),
      );
      await _db.setCloudState(task.mediaId, 'FAILED');
      await _refreshTelemetryCounts();
      return true;
    }

    final fileName = media.filePath != null
        ? p.basename(media.filePath!)
        : 'Media item';
    _updateTelemetry(
      activeWorkers: 1,
      currentFileName: fileName,
      isPaused: false,
    );
    _updateForegroundNotification();

    await _db.updateTaskStatus(
      task.id,
      'inProgress',
      lastAttemptAt: DateTime.now(),
    );
    await _db.setCloudState(media.id, 'UPLOADING');

    try {
      final fileHash = await calculateSha256(media.filePath!);
      final existingDeduplicated = await _db.getMediaByHash(fileHash);

      // This code for deduplicating identical files against the Telegram supergroup vault
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
        await (_db.update(_db.mediaItems)
              ..where((tbl) => tbl.id.equals(media.id)))
            .write(MediaItemsCompanion(sha256Hash: Value(fileHash)));
        await _db.setCloudState(media.id, 'AVAILABLE_LOCALLY');
        await _db.deleteSyncTask(task.id);
        await _refreshTelemetryCounts();
        return true;
      }

      // This code for resolving destination Telegram forum topic based on media type and category
      final topicId = _tdlib.getTopicIdForCategory(media.mediaType);
      final message = await _tdlib.uploadMedia(
        filePath: media.filePath!,
        mediaType: media.mediaType,
        topicId: topicId,
        caption: '#infinity #${media.mediaType}',
      );

      if (message != null) {
        final extractedFileId = _extractFileId(message.content);
        await _db.updateSyncStatus(
          media.id,
          'synced',
          telegramFileId: extractedFileId,
          telegramMessageId: message.id,
          telegramChatId: message.chatId,
          telegramTopicId: topicId,
        );
        await (_db.update(_db.mediaItems)
              ..where((tbl) => tbl.id.equals(media.id)))
            .write(MediaItemsCompanion(sha256Hash: Value(fileHash)));
        await _db.setCloudState(media.id, 'AVAILABLE_LOCALLY');
        await _db.deleteSyncTask(task.id);
        await _refreshTelemetryCounts();
        await _cacheManager.enforceCacheLimits();
      } else {
        await _handleTaskFailure(task, 'Upload returned null message');
      }
    } catch (e) {
      await _handleTaskFailure(task, e.toString());
    } finally {
      await _refreshTelemetryCounts();
    }

    return true;
  }

  // This code for extracting Telegram file identifier from TDLib message content
  String? _extractFileId(MessageContent content) {
    if (content is MessagePhoto) {
      final sizes = content.photo.sizes;
      if (sizes.isNotEmpty) {
        return sizes.last.photo.id.toString();
      }
    } else if (content is MessageVideo) {
      return content.video.video.id.toString();
    } else if (content is MessageDocument) {
      return content.document.document.id.toString();
    }
    return null;
  }

  // This code for scheduling a wakeup timer for the earliest task currently in exponential backoff delay
  Future<void> _scheduleNextBackoffWakeup(DateTime now) async {
    _wakeupTimer?.cancel();
    final nextDelayedTasks = await (_db.select(_db.syncQueue)
          ..where((tbl) =>
              tbl.status.equals('pending') &
              tbl.lastAttemptAt.isNotNull() &
              tbl.lastAttemptAt.isBiggerThanValue(now))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.lastAttemptAt, mode: OrderingMode.asc)
          ])
          ..limit(1))
        .get();

    if (nextDelayedTasks.isNotEmpty) {
      final nextDue = nextDelayedTasks.first.lastAttemptAt!;
      final delay = nextDue.difference(now);
      _wakeupTimer = Timer(delay + const Duration(milliseconds: 100), () {
        if (!_isProcessing && !_isDisposed) {
          processNextTask();
        }
      });
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

  /// Automatically queues all unsynced local media items for background upload.
  Future<void> autoQueueUnsynced() async {
    final unsynced = await _db.getUnsyncedMedia();
    for (final item in unsynced) {
      await queueUpload(mediaId: item.id, priority: 0);
    }
  }
}
