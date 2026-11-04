import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../crypto/crypto_service.dart';
import '../database/app_database.dart';
import '../security/biometric_service.dart';
import '../settings/app_preferences.dart';
import '../storage/cloud_media_cache_manager.dart';
import '../sync/sync_engine.dart';
import '../telegram/tdlib_service.dart';

final preferencesProvider = Provider<AppPreferences>((ref) {
  throw UnimplementedError();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final tdlibServiceProvider = Provider<TdlibService>((ref) {
  final service = TdlibService();
  ref.onDispose(() => service.dispose());
  return service;
});

final cryptoServiceProvider = Provider<CryptoService>((ref) {
  return CryptoService();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final cacheManagerProvider = Provider<CloudMediaCacheManager>((ref) {
  final db = ref.watch(databaseProvider);
  final prefs = ref.watch(preferencesProvider);
  return CloudMediaCacheManager(db, prefs);
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(databaseProvider);
  final tdlib = ref.watch(tdlibServiceProvider);
  final prefs = ref.watch(preferencesProvider);
  final cache = ref.watch(cacheManagerProvider);
  final engine = SyncEngine(db, tdlib, prefs, cache);
  engine.startQueueProcessor();
  ref.onDispose(() => engine.stopQueueProcessor());
  return engine;
});

// This code for streaming Telegram authentication state with immediate initial value
final authStateProvider = StreamProvider<TelegramAuthState>((ref) async* {
  final service = ref.watch(tdlibServiceProvider);
  yield service.currentAuthState;
  yield* service.authStateStream;
});

final allMediaProvider = StreamProvider<List<MediaItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllMedia();
});

// This code for managing active gallery multi-selection mode across navigation scaffolds
class SelectionModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // This code for updating active selection mode state
  void setSelectionMode(bool value) => state = value;
}

// This code for riverpod provider exposing active selection mode state
final selectionModeProvider =
    NotifierProvider<SelectionModeNotifier, bool>(SelectionModeNotifier.new);

// This code for managing selected media item IDs across multi-selection sessions
class SelectedMediaIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  // This code for replacing currently selected media IDs set
  void setSelectedIds(Set<String> ids) => state = ids;

  // This code for clearing all selected media IDs
  void clear() => state = <String>{};
}

// This code for riverpod provider exposing selected media IDs set
final selectedMediaIdsProvider =
    NotifierProvider<SelectedMediaIdsNotifier, Set<String>>(
        SelectedMediaIdsNotifier.new);

final favoritesProvider = StreamProvider<List<MediaItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchFavorites();
});

final trashProvider = StreamProvider<List<MediaItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchTrash();
});

final albumsProvider = StreamProvider<List<Album>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAlbums();
});

final pendingTasksProvider = StreamProvider<List<SyncQueueData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchPendingSyncTasks();
});

// This code for streaming media items currently pending or in-progress in upload queue
final pendingUploadMediaProvider = StreamProvider<List<MediaItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchPendingUploadMedia();
});

// This code for streaming non-photo document and general files from the database
final filesProvider = StreamProvider<List<MediaItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchFiles();
});

// This code for streaming real-time upload throughput and telemetry state
final uploadTelemetryProvider = StreamProvider<UploadTelemetryState>((ref) async* {
  final engine = ref.watch(syncEngineProvider);
  yield engine.currentTelemetry;
  yield* engine.telemetryStream;
});

// This code for tracking active device media scanner state to avoid empty screen glitches
class IsMediaScanningNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setScanning(bool value) => state = value;
}

final isMediaScanningProvider =
    NotifierProvider<IsMediaScanningNotifier, bool>(IsMediaScanningNotifier.new);

