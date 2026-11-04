// This code for displaying media items belonging to a specific Telegram topic album
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/di/providers.dart';
import '../../core/media/perceptual_hash_service.dart';
import '../../core/storage/zip_export_service.dart';
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
  // This code for fixed cross-axis count in album detail photo grid
  final int _crossAxisCount = 3;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

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
    } else if (lower == 'duplicates') {
      // This code for streaming duplicate and near-duplicate images detected via 64-bit dHash
      return db.watchDuplicateCandidates().map((items) {
        final clusters = PerceptualHashService.findDuplicates(items);
        final duplicateIds = <String>{};
        for (final cluster in clusters) {
          duplicateIds.add(cluster.primary.id);
          for (final dup in cluster.duplicates) {
            duplicateIds.add(dup.id);
          }
        }
        return items.where((i) => duplicateIds.contains(i.id)).toList();
      });
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

  // This code for toggling multi-selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  // This code for toggling selection of a single media item
  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // This code for batch exporting selected media items to a zipped bundle and invoking share sheet
  Future<void> _batchExportZipSelected(List<MediaItem> allItems) async {
    final selectedItems =
        allItems.where((i) => _selectedIds.contains(i.id)).toList();
    if (selectedItems.isEmpty) return;

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CupertinoPopupSurface(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(),
                SizedBox(height: 12),
                Text('Compressing to Zip...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await ZipExportService.exportAndShareMediaItems(selectedItems);
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _isSelectionMode = false;
          _selectedIds.clear();
        });
      }
    }
  }

  // This code for moving selected items to the trash
  Future<void> _batchTrashSelected() async {
    final db = ref.read(databaseProvider);
    for (final id in _selectedIds) {
      await db.setTrashed(id, true);
    }
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          _isSelectionMode
              ? '${_selectedIds.length} Selected'
              : widget.title,
        ),
        // This code for toggling selection mode in album detail view
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _toggleSelectionMode,
          child: Text(_isSelectionMode ? 'Done' : 'Select'),
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
                    Icon(
                      widget.title.toLowerCase() == 'duplicates'
                          ? CupertinoIcons.rectangle_on_rectangle_angled
                          : CupertinoIcons.photo_on_rectangle,
                      size: 64,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title.toLowerCase() == 'duplicates'
                          ? 'No Duplicates Found'
                          : 'No media in ${widget.title}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title.toLowerCase() == 'duplicates'
                          ? 'All photos in your vault are visually unique'
                          : 'Items assigned to this topic album will appear here',
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(2),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _crossAxisCount,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = _selectedIds.contains(item.id);

                      return GestureDetector(
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _toggleSelectionMode();
                            _toggleItemSelection(item.id);
                          }
                        },
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleItemSelection(item.id);
                          } else {
                            // This code for opening media viewer with swipeable album items
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => MediaViewerScreen(
                                  item: item,
                                  items: items,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            item.filePath != null
                                ? Image.file(
                                    File(item.filePath!),
                                    fit: BoxFit.cover,
                                    cacheWidth: 360,
                                    cacheHeight: 360,
                                    filterQuality: FilterQuality.low,
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
                            if (_isSelectionMode)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Icon(
                                  isSelected
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                  color: isSelected
                                      ? CupertinoColors.activeBlue
                                      : CupertinoColors.white,
                                  size: 22,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_isSelectionMode && _selectedIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.resolveFrom(context),
                      border: Border(
                        top: BorderSide(
                          color: CupertinoColors.separator.resolveFrom(context),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _batchExportZipSelected(items),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.archivebox),
                              SizedBox(height: 2),
                              Text('Export Zip', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _batchTrashSelected,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.trash,
                                  color: CupertinoColors.destructiveRed),
                              SizedBox(height: 2),
                              Text(
                                'Trash',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.destructiveRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
