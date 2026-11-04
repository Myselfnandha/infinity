// This code for rendering the main photos timeline with pinch zoom, multi-select, and Telegram sync status
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/di/providers.dart';
import '../../core/storage/gallery_service.dart';
import '../../core/storage/zip_export_service.dart';
import '../viewer/media_viewer_screen.dart';

// This code for managing interactive timeline state including selection and dynamic grid scaling
class PhotosTimelineScreen extends ConsumerStatefulWidget {
  const PhotosTimelineScreen({super.key});

  @override
  ConsumerState<PhotosTimelineScreen> createState() =>
      _PhotosTimelineScreenState();
}

class _PhotosTimelineScreenState extends ConsumerState<PhotosTimelineScreen> {
  bool _isScanning = false;
  int _crossAxisCount = 3;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // This code for scanning device storage for new photos and videos
  Future<void> _scanDevice() async {
    setState(() => _isScanning = true);
    try {
      final db = ref.read(databaseProvider);
      final service = GalleryService(db);
      await service.scanDeviceMedia(limit: 500);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  // This code for toggling selection mode
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

  // This code for batch queuing selected media items to Telegram vault
  Future<void> _batchUploadSelected(List<MediaItem> allItems) async {
    final sync = ref.read(syncEngineProvider);
    final selectedItems =
        allItems.where((i) => _selectedIds.contains(i.id)).toList();

    for (final item in selectedItems) {
      await sync.queueUpload(mediaId: item.id);
    }

    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  // This code for batch favoriting or unfavoriting selected media
  Future<void> _batchFavoriteSelected(List<MediaItem> allItems) async {
    final db = ref.read(databaseProvider);
    final selectedItems =
        allItems.where((i) => _selectedIds.contains(i.id)).toList();
    final bool anyUnfav = selectedItems.any((i) => !i.isFavorite);

    for (final item in selectedItems) {
      await db.setFavorite(item.id, anyUnfav);
    }

    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  // This code for batch moving selected items to the trash
  Future<void> _batchTrashSelected(List<MediaItem> allItems) async {
    final db = ref.read(databaseProvider);
    for (final id in _selectedIds) {
      await db.setTrashed(id, true);
    }

    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  // This code for batch exporting selected media items to a zipped bundle and invoking share sheet
  Future<void> _batchExportZipSelected(List<MediaItem> allItems) async {
    final selectedItems =
        allItems.where((i) => _selectedIds.contains(i.id)).toList();
    if (selectedItems.isEmpty) return;

    // Show Cupertino loading indicator
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

  // This code for formatting date groupings for timeline sections
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Today';
    } else if (itemDate == yesterday) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('EEEE, MMM d').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  // This code for grouping media items by calendar day
  Map<String, List<MediaItem>> _groupMediaByDate(List<MediaItem> items) {
    final Map<String, List<MediaItem>> grouped = {};
    for (final item in items) {
      final date = item.dateTaken ?? item.dateAdded;
      final key = _formatDateHeader(date);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(allMediaProvider);
    final pendingTasks = ref.watch(pendingTasksProvider).value ?? [];

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: _isSelectionMode
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _toggleSelectionMode,
                child: const Text('Cancel'),
              )
            : null,
        middle: Text(
          _isSelectionMode
              ? '${_selectedIds.length} Selected'
              : 'Infinity Photos',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isSelectionMode) ...[
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _toggleSelectionMode,
                child: const Text('Select'),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isScanning ? null : _scanDevice,
                child: _isScanning
                    ? const CupertinoActivityIndicator()
                    : const Icon(CupertinoIcons.arrow_2_circlepath),
              ),
            ],
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // This code for displaying active background upload sync progress banner
            if (pendingTasks.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: CupertinoColors.activeBlue.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    const CupertinoActivityIndicator(radius: 8),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Syncing ${pendingTasks.length} ${pendingTasks.length == 1 ? 'item' : 'items'} to Infinity Vault...',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: mediaAsync.when(
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (err, stack) => Center(
                  child: Text(
                    'Error: $err',
                    style:
                        const TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                ),
                data: (items) {
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
                          const Text(
                            'No media loaded yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.label,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Scan your device to view and backup photos',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 24),
                          CupertinoButton.filled(
                            onPressed: _isScanning ? null : _scanDevice,
                            child: _isScanning
                                ? const CupertinoActivityIndicator(
                                    color: CupertinoColors.white)
                                : const Text('Scan Device Media'),
                          ),
                        ],
                      ),
                    );
                  }

                  final grouped = _groupMediaByDate(items);

                  // This code for handling pinch-to-zoom scaling of photo grid
                  return GestureDetector(
                    onScaleUpdate: (details) {
                      if (details.scale > 1.25 && _crossAxisCount > 2) {
                        setState(() => _crossAxisCount--);
                      } else if (details.scale < 0.75 && _crossAxisCount < 5) {
                        setState(() => _crossAxisCount++);
                      }
                    },
                    child: CustomScrollView(
                      slivers: [
                        for (final entry in grouped.entries) ...[
                          // This code for pinning date header under navigation bar during scrolling
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyTimelineHeaderDelegate(
                              dateTitle: entry.key,
                              itemCount: entry.value.length,
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.all(2),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _crossAxisCount,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = entry.value[index];
                                  final isSelected =
                                      _selectedIds.contains(item.id);

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
                                        // This code for launching full-screen media viewer with swipeable items list
                                        Navigator.of(context).push(
                                          CupertinoPageRoute(
                                            builder: (_) => MediaViewerScreen(
                                              item: item,
                                              items: items,
                                              initialIndex:
                                                  items.contains(item)
                                                      ? items.indexOf(item)
                                                      : 0,
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
                                                errorBuilder:
                                                    (ctx, err, stack) =>
                                                        Container(
                                                  color: CupertinoColors
                                                      .systemGrey5,
                                                  child: const Icon(
                                                    CupertinoIcons.photo,
                                                    color: CupertinoColors
                                                        .systemGrey,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color:
                                                    CupertinoColors.systemGrey5,
                                                child: const Icon(
                                                  CupertinoIcons.cloud,
                                                  color: CupertinoColors
                                                      .systemGrey,
                                                ),
                                              ),
                                        if (item.mediaType == 'video')
                                          Positioned(
                                            left: 6,
                                            bottom: 6,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: CupertinoColors.black
                                                    .withValues(alpha: 0.6),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    CupertinoIcons.play_fill,
                                                    size: 10,
                                                    color:
                                                        CupertinoColors.white,
                                                  ),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    'VIDEO',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          CupertinoColors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (item.isPinnedOffline)
                                          Positioned(
                                            left: 6,
                                            top: 6,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: CupertinoColors.black
                                                    .withValues(alpha: 0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                CupertinoIcons.pin_fill,
                                                size: 11,
                                                color: CupertinoColors.white,
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          right: 6,
                                          top: 6,
                                          child: Icon(
                                            item.syncStatus == 'synced'
                                                ? CupertinoIcons
                                                    .check_mark_circled_solid
                                                : CupertinoIcons.cloud,
                                            size: 16,
                                            color: item.syncStatus == 'synced'
                                                ? CupertinoColors.activeGreen
                                                : CupertinoColors.white
                                                    .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        if (_isSelectionMode)
                                          Positioned(
                                            top: 6,
                                            left: 6,
                                            child: Icon(
                                              isSelected
                                                  ? CupertinoIcons
                                                      .checkmark_circle_fill
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
                                childCount: entry.value.length,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            // This code for rendering batch actions bottom toolbar when items are selected
            if (_isSelectionMode && _selectedIds.isNotEmpty)
              mediaAsync.maybeWhen(
                data: (items) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground
                        .resolveFrom(context),
                    border: Border(
                      top: BorderSide(
                        color: CupertinoColors.separator
                            .resolveFrom(context),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _batchUploadSelected(items),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.cloud_upload),
                            SizedBox(height: 2),
                            Text('Sync', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _batchFavoriteSelected(items),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.heart),
                            SizedBox(height: 2),
                            Text('Favorite', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
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
                        onPressed: () => _batchTrashSelected(items),
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
                orElse: () => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

// This code for rendering pinned iOS-style sticky date headers in the photos timeline
class _StickyTimelineHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String dateTitle;
  final int itemCount;

  const _StickyTimelineHeaderDelegate({
    required this.dateTitle,
    required this.itemCount,
  });

  @override
  double get minExtent => 42.0;

  @override
  double get maxExtent => 42.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // This code for adapting header blur and background color based on active system theme
    return Container(
      color: CupertinoColors.systemBackground
          .resolveFrom(context)
          .withValues(alpha: 0.96),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          Text(
            '$itemCount',
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTimelineHeaderDelegate oldDelegate) {
    return oldDelegate.dateTitle != dateTitle ||
        oldDelegate.itemCount != itemCount;
  }
}
