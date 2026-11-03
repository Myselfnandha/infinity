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

final authStateProvider = StreamProvider<TelegramAuthState>((ref) {
  final service = ref.watch(tdlibServiceProvider);
  return service.authStateStream;
});

final allMediaProvider = StreamProvider<List<MediaItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllMedia();
});

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
