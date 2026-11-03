import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../telegram/tdlib_service.dart';

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
