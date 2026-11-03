// This code for displaying media items belonging to a specific Telegram topic album
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/di/providers.dart';
import '../viewer/media_viewer_screen.dart';

// This code for rendering the album detail view with responsive media grid
class AlbumDetailScreen extends ConsumerStatefulWidget {
  final String title;
  final String? albumId;
  final int? topicId;

  const AlbumDetailScreen({
    super.key,
    required this.title,
    this.albumId,
    this.topicId,
  });

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  int _crossAxisCount = 3;

  // This code for streaming media items associated with this album or media category
  Stream<List<MediaItem>> _getAlbumMediaStream(AppDatabase db) {
    if (widget.albumId != null) {
      return db.watchMediaForAlbum(widget.albumId!);
    }

    final lower = widget.title.toLowerCase();
    if (lower == 'videos') {
      return (db.select(db.mediaItems)
            ..where((tbl) =>
                tbl.mediaType.equals('video') & tbl.isTrashed.equals(false))
            ..orderBy([
              (tbl) => drift.OrderingTerm(
                    expression: drift.coalesce([tbl.dateTaken, tbl.dateAdded]),
                    mode: drift.OrderingMode.desc,
                  )
            ]))
          .watch();
    } else if (lower == 'photos') {
      return (db.select(db.mediaItems)
            ..where((tbl) =>
                tbl.mediaType.equals('image') & tbl.isTrashed.equals(false))
            ..orderBy([
              (tbl) => drift.OrderingTerm(
                    expression: drift.coalesce([tbl.dateTaken, tbl.dateAdded]),
                    mode: drift.OrderingMode.desc,
                  )
            ]))
          .watch();
    } else if (lower == 'screenshots') {
      return (db.select(db.mediaItems)
            ..where((tbl) =>
                tbl.filePath.like('%Screenshot%') & tbl.isTrashed.equals(false))
            ..orderBy([
              (tbl) => drift.OrderingTerm(
                    expression: drift.coalesce([tbl.dateTaken, tbl.dateAdded]),
                    mode: drift.OrderingMode.desc,
                  )
            ]))
          .watch();
    }

    return (db.select(db.mediaItems)
          ..where((tbl) => tbl.isTrashed.equals(false))
          ..orderBy([
            (tbl) => drift.OrderingTerm(
                  expression: drift.coalesce([tbl.dateTaken, tbl.dateAdded]),
                  mode: drift.OrderingMode.desc,
                )
          ]))
        .watch();
  }

  // This code for cycling the grid column zoom level between 2, 3, and 4 columns
  void _toggleZoomLevel() {
    setState(() {
      _crossAxisCount = _crossAxisCount == 3
          ? 4
          : _crossAxisCount == 4
              ? 2
              : 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _toggleZoomLevel,
          child: const Icon(CupertinoIcons.square_grid_2x2),
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<List<MediaItem>>(
          stream: _getAlbumMediaStream(db),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.photo_on_rectangle,
                      size: 64,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No media in ${widget.title}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Items assigned to this topic album will appear here',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => MediaViewerScreen(item: item),
                      ),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.filePath != null
                          ? Image.file(
                              File(item.filePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: CupertinoColors.systemGrey5,
                                child: const Icon(
                                  CupertinoIcons.photo,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            )
                          : Container(
                              color: CupertinoColors.systemGrey5,
                              child: const Icon(
                                CupertinoIcons.cloud,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                      if (item.mediaType == 'video')
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: CupertinoColors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  CupertinoIcons.play_fill,
                                  size: 10,
                                  color: CupertinoColors.white,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'VIDEO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Icon(
                          item.syncStatus == 'synced'
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.cloud,
                          size: 16,
                          color: item.syncStatus == 'synced'
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

