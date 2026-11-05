// This code for testing SyncEngine queue orchestration, deduplication, retry backoff, priority scheduling, and network guards
import 'dart:io' as io;
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handy_tdlib_next/handy_tdlib_next.dart' as td;
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/core/storage/cloud_media_cache_manager.dart';
import 'package:infinity/core/sync/sync_engine.dart';
import 'package:infinity/core/telegram/tdlib_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This code for mocking connectivity states across tests
class FakeConnectivityPlatform extends ConnectivityPlatform with MockPlatformInterfaceMixin {
  List<ConnectivityResult> results;
  FakeConnectivityPlatform(this.results);

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => results;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => Stream.value(results);
}

// This code for mocking documents directory to isolated temp path
class FakePathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String path;
  FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

// This code for isolating database in-memory for testing
class TestAppDatabase extends AppDatabase {
  TestAppDatabase() : super.forTesting(NativeDatabase.memory());
}

// This code for mocking TDLib service upload responses without native binaries
class FakeTdlibService implements TdlibService {
  td.Message? uploadResult;
  int uploadCallCount = 0;
  String? lastUploadedPath;
  String? lastUploadedType;
  int? lastUploadedTopicId;
  final List<String> uploadedPaths = [];

  @override
  int getTopicIdForCategory(String category) => 101;

  @override
  Future<td.Message?> uploadMedia({
    required String filePath,
    required String mediaType,
    required int topicId,
    String? caption,
  }) async {
    uploadCallCount++;
    lastUploadedPath = filePath;
    lastUploadedType = mediaType;
    lastUploadedTopicId = topicId;
    uploadedPaths.add(filePath);
    return uploadResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncEngine Unit Tests', () {
    late io.Directory tempDir;
    late TestAppDatabase db;
    late FakeTdlibService tdlib;
    late SharedPreferences prefsInstance;
    late AppPreferences prefs;
    late CloudMediaCacheManager cacheManager;
    late SyncEngine syncEngine;
    late FakeConnectivityPlatform connectivity;

    setUp(() async {
      // This code for preparing isolated environment, DB, preferences, and mock network
      tempDir = io.Directory.systemTemp.createTempSync('infinity_sync_test_');
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

      connectivity = FakeConnectivityPlatform([ConnectivityResult.wifi]);
      ConnectivityPlatform.instance = connectivity;

      db = TestAppDatabase();
      tdlib = FakeTdlibService();
      SharedPreferences.setMockInitialValues({
        'is_wifi_only': false,
        'cache_limit_mb': 500,
      });
      prefsInstance = await SharedPreferences.getInstance();
      prefs = AppPreferences(prefsInstance);
      cacheManager = CloudMediaCacheManager(db, prefs);
      syncEngine = SyncEngine(db, tdlib, prefs, cacheManager);
    });

    tearDown(() async {
      // This code for tearing down database and removing temporary test directories
      syncEngine.stopQueueProcessor();
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('1. queueUpload inserts a pending task with priority and sets state to QUEUED', () async {
      // This code for verifying basic queue insertion and status updates
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media_test_1',
              mediaType: 'image',
              fileSize: 1024,
              dateAdded: DateTime.now(),
            ),
          );

      await syncEngine.queueUpload(mediaId: 'media_test_1', priority: 5);

      final tasks = await db.select(db.syncQueue).get();
      expect(tasks.length, equals(1));
      expect(tasks.first.mediaId, equals('media_test_1'));
      expect(tasks.first.priority, equals(5));
      expect(tasks.first.status, equals('pending'));

      final item = await db.getMediaItem('media_test_1');
      expect(item!.cloudState, equals('QUEUED'));
    });

    test('2. queueUpload is idempotent and skips duplicate pending or in-progress tasks', () async {
      // This code for asserting no duplicates are inserted when item is already queued
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media_dup',
              mediaType: 'image',
              fileSize: 1024,
              dateAdded: DateTime.now(),
            ),
          );

      await syncEngine.queueUpload(mediaId: 'media_dup');
      await syncEngine.queueUpload(mediaId: 'media_dup');

      final tasks = await db.select(db.syncQueue).get();
      expect(tasks.length, equals(1));
    });

    test('3. processNextTask halts when cellular active but Wi-Fi only is enforced', () async {
      // This code for asserting Wi-Fi only network policy guards
      prefs.setWifiOnly(true);
      connectivity.results = [ConnectivityResult.mobile];

      final file = io.File('${tempDir.path}/wifi_guard.jpg');
      await file.writeAsBytes([1, 2, 3]);

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media_wifi_guard',
              mediaType: 'image',
              fileSize: 3,
              dateAdded: DateTime.now(),
              filePath: drift.Value(file.path),
            ),
          );

      await syncEngine.queueUpload(mediaId: 'media_wifi_guard');
      await syncEngine.processNextTask();

      expect(tdlib.uploadCallCount, equals(0));
      final task = (await db.select(db.syncQueue).get()).first;
      expect(task.status, equals('pending'));
    });

    test('4. processNextTask halts when network is completely offline', () async {
      // This code for ensuring offline state prevents upload attempts
      connectivity.results = [ConnectivityResult.none];

      final file = io.File('${tempDir.path}/offline.jpg');
      await file.writeAsBytes([1, 2, 3]);

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media_offline',
              mediaType: 'image',
              fileSize: 3,
              dateAdded: DateTime.now(),
              filePath: drift.Value(file.path),
            ),
          );

      await syncEngine.queueUpload(mediaId: 'media_offline');
      await syncEngine.processNextTask();

      expect(tdlib.uploadCallCount, equals(0));
      final task = (await db.select(db.syncQueue).get()).first;
      expect(task.status, equals('pending'));
    });

    test('5. processNextTask marks task and media FAILED when local file is missing on disk', () async {
      // This code for verifying physical disk check guards against missing files
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media_ghost',
              mediaType: 'image',
              fileSize: 100,
              dateAdded: DateTime.now(),
              filePath: drift.Value('${tempDir.path}/does_not_exist.jpg'),
            ),
          );

      await syncEngine.queueUpload(mediaId: 'media_ghost');
      await syncEngine.processNextTask();

      expect(tdlib.uploadCallCount, equals(0));
      final task = (await db.select(db.syncQueue).get()).first;
      expect(task.status, equals('failed'));
      expect(task.errorMessage, contains('not found'));

      final item = await db.getMediaItem('media_ghost');
      expect(item!.cloudState, equals('FAILED'));
    });

    test('6. processNextTask deduplicates identical media via SHA-256 hash match', () async {
      // This code for asserting cloud deduplication when matching hash exists in supergroup
      final file = io.File('${tempDir.path}/duplicate.jpg');
      await file.writeAsBytes([10, 20, 30, 40]);
      final expectedHash = await syncEngine.calculateSha256(file.path);

      // Existing uploaded item with identical hash
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'item_cloud_original',
              mediaType: 'image',
              fileSize: 4,
              dateAdded: DateTime.now().subtract(const Duration(days: 1)),
              sha256Hash: drift.Value(expectedHash),
              telegramFileId: const drift.Value('tg_file_dedup_123'),
              telegramMessageId: const drift.Value(777),
              telegramChatId: const drift.Value(-100123),
              telegramTopicId: const drift.Value(101),
              syncStatus: const drift.Value('synced'),
            ),
          );

      // New media item with identical content
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'item_cloud_copy',
              mediaType: 'image',
              fileSize: 4,
              dateAdded: DateTime.now(),
              filePath: drift.Value(file.path),
            ),
          );

      await syncEngine.queueUpload(mediaId: 'item_cloud_copy');
      await syncEngine.processNextTask();

      // No network upload should have occurred
      expect(tdlib.uploadCallCount, equals(0));

      final tasks = await db.select(db.syncQueue).get();
      expect(tasks, isEmpty); // Task removed on successful sync

      final copyItem = await db.getMediaItem('item_cloud_copy');
      expect(copyItem!.syncStatus, equals('synced'));
      expect(copyItem.telegramFileId, equals('tg_file_dedup_123'));
      expect(copyItem.telegramMessageId, equals(777));
      expect(copyItem.cloudState, equals('AVAILABLE_LOCALLY'));
    });

    test('7. processNextTask successfully uploads media, extracts file ID, and completes sync', () async {
      // This code for asserting full upload pipeline execution and file ID extraction
      final file = io.File('${tempDir.path}/upload_ok.jpg');
      await file.writeAsBytes([100, 101, 102, 103]);

      tdlib.uploadResult = td.Message(
        id: 9901,
        senderId: const td.MessageSenderUser(userId: 111),
        chatId: -100555,
        isOutgoing: true,
        isPinned: false,
        isFromOffline: false,
        canBeSaved: true,
        hasTimestampedMedia: false,
        isChannelPost: false,
        isTopicMessage: true,
        containsUnreadMention: false,
        date: 1700000000,
        editDate: 0,
        unreadReactions: const [],
        messageThreadId: 101,
        savedMessagesTopicId: 0,
        selfDestructIn: 0,
        autoDeleteIn: 0,
        viaBotUserId: 0,
        senderBusinessBotUserId: 0,
        senderBoostCount: 0,
        authorSignature: '',
        mediaAlbumId: 0,
        effectId: 0,
        hasSensitiveContent: false,
        restrictionReason: '',
        content: td.MessagePhoto(
          photo: td.Photo(
            hasStickers: false,
            minithumbnail: null,
            sizes: [
              td.PhotoSize(
                type: 'y',
                photo: const td.File(
                  id: 54321,
                  size: 4,
                  expectedSize: 4,
                  local: td.LocalFile(
                    path: '/tmp/upload_ok.jpg',
                    canBeDownloaded: true,
                    canBeDeleted: true,
                    isDownloadingActive: false,
                    isDownloadingCompleted: true,
                    downloadOffset: 0,
                    downloadedPrefixSize: 0,
                    downloadedSize: 4,
                  ),
                  remote: td.RemoteFile(
                    id: 'rem_54321',
                    uniqueId: 'uniq_54321',
                    isUploadingActive: false,
                    isUploadingCompleted: true,
                    uploadedSize: 4,
                  ),
                ),
                width: 100,
                height: 100,
                progressiveSizes: [],
              ),
            ],
          ),
          caption: const td.FormattedText(text: '#infinity', entities: []),
          showCaptionAboveMedia: false,
          hasSpoiler: false,
          isSecret: false,
        ),
      );

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media_upload_ok',
              mediaType: 'image',
              fileSize: 4,
              dateAdded: DateTime.now(),
              filePath: drift.Value(file.path),
            ),
          );

      await syncEngine.queueUpload(mediaId: 'media_upload_ok');
      await syncEngine.processNextTask();

      expect(tdlib.uploadCallCount, equals(1));

      final tasks = await db.select(db.syncQueue).get();
      expect(tasks, isEmpty);

      final item = await db.getMediaItem('media_upload_ok');
      expect(item!.syncStatus, equals('synced'));
      expect(item.telegramFileId, equals('54321')); // Extracted from PhotoSize
      expect(item.telegramMessageId, equals(9901));
      expect(item.telegramChatId, equals(-100555));
      expect(item.telegramTopicId, equals(101));
      expect(item.cloudState, equals('AVAILABLE_LOCALLY'));
    });

    test('8. processNextTask executes higher priority tasks before earlier low priority tasks', () async {
      // This code for verifying priority ordering in the sync queue
      final fileLow = io.File('${tempDir.path}/low.jpg');
      final fileHigh = io.File('${tempDir.path}/high.jpg');
      await fileLow.writeAsBytes([1]);
      await fileHigh.writeAsBytes([2]);

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media_low',
              mediaType: 'image',
              fileSize: 1,
              dateAdded: DateTime.now().subtract(const Duration(minutes: 5)),
              filePath: drift.Value(fileLow.path),
            ),
          );

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media_high',
              mediaType: 'image',
              fileSize: 1,
              dateAdded: DateTime.now(),
              filePath: drift.Value(fileHigh.path),
            ),
          );

      await syncEngine.queueUpload(mediaId: 'media_low', priority: 0);
      await syncEngine.queueUpload(mediaId: 'media_high', priority: 10);

      // TDLib returns null so task fails without crashing
      tdlib.uploadResult = null;
      await syncEngine.processNextTask();

      // The high-priority task should have been attempted first
      expect(tdlib.uploadedPaths.isNotEmpty, isTrue);
      expect(tdlib.uploadedPaths.first, equals(fileHigh.path));
    });

    test('9. processNextTask applies exponential backoff delay and increments retry count on error', () async {
      // This code for verifying exponential backoff retry scheduling on failure
      final file = io.File('${tempDir.path}/retry.jpg');
      await file.writeAsBytes([5, 6, 7]);

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media_retry',
              mediaType: 'image',
              fileSize: 3,
              dateAdded: DateTime.now(),
              filePath: drift.Value(file.path),
            ),
          );

      await syncEngine.queueUpload(mediaId: 'media_retry');
      tdlib.uploadResult = null; // Triggers failure

      final before = DateTime.now();
      await syncEngine.processNextTask();

      final tasks = await db.select(db.syncQueue).get();
      expect(tasks.length, equals(1));
      final task = tasks.first;
      expect(task.status, equals('pending'));
      expect(task.retryCount, equals(1));
      expect(task.lastAttemptAt, isNotNull);
      // Backoff for retry 1 is pow(2, 1)*2 = 4 seconds + random jitter
      expect(task.lastAttemptAt!.isAfter(before.add(const Duration(seconds: 3))), isTrue);
    });

    test('10. processNextTask permanently fails task when retry count exceeds threshold of 5', () async {
      // This code for verifying retry exhaustion permanently terminates failed sync tasks
      final file = io.File('${tempDir.path}/exhausted.jpg');
      await file.writeAsBytes([9, 9, 9]);

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media_exhausted',
              mediaType: 'image',
              fileSize: 3,
              dateAdded: DateTime.now(),
              filePath: drift.Value(file.path),
            ),
          );

      await syncEngine.queueUpload(mediaId: 'media_exhausted');
      // Pre-set retryCount to 5
      await (db.update(db.syncQueue)..where((tbl) => tbl.mediaId.equals('media_exhausted')))
          .write(const SyncQueueCompanion(retryCount: drift.Value(5)));

      tdlib.uploadResult = null; // Fails 6th attempt
      await syncEngine.processNextTask();

      final task = (await db.select(db.syncQueue).get()).first;
      expect(task.status, equals('failed'));
      expect(task.retryCount, equals(6));

      final item = await db.getMediaItem('media_exhausted');
      expect(item!.cloudState, equals('FAILED'));
    });

    test('11. pauseSync and resumeSync control transmission state and emit telemetry updates', () async {
      expect(syncEngine.currentTelemetry.isPaused, isFalse);

      syncEngine.pauseSync();
      expect(syncEngine.currentTelemetry.isPaused, isTrue);

      syncEngine.resumeSync();
      expect(syncEngine.currentTelemetry.isPaused, isFalse);

      // Allow async task triggered by resumeSync to settle before teardown
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('12. processNextTask halts immediately when pauseSync is active', () async {
      final file = io.File('${tempDir.path}/paused_item.jpg');
      await file.writeAsBytes([1, 2, 3]);

      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media_paused',
              mediaType: 'image',
              fileSize: 3,
              dateAdded: DateTime.now(),
              filePath: drift.Value(file.path),
            ),
          );

      await syncEngine.queueUpload(mediaId: 'media_paused');
      syncEngine.pauseSync();

      await syncEngine.processNextTask();

      // Upload must NOT have been called while paused
      expect(tdlib.uploadCallCount, equals(0));
      final task = (await db.select(db.syncQueue).get()).first;
      expect(task.status, equals('pending'));
    });

    test('13. UploadTelemetryState computes progressPercentage and throughputMbps correctly', () {
      const state = UploadTelemetryState(
        isPaused: false,
        activeWorkers: 1,
        speedKBps: 8192.0,
        bytesTransferredTotal: 5000,
        completedCount: 5,
        totalCount: 10,
      );

      expect(state.progressPercentage, equals(0.5));
      expect(state.activeWorkers > 0 && !state.isPaused, isTrue);
      expect(state.speedFormatted, contains('MB/s'));

      const pausedState = UploadTelemetryState(
        isPaused: true,
        activeWorkers: 1,
      );
      expect(pausedState.activeWorkers > 0 && !pausedState.isPaused, isFalse);
    });
  });
}
