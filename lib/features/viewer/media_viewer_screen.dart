// This code for displaying media viewer with pinch-to-zoom and swipeable horizontal PageView
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../core/database/app_database.dart';
import '../../core/di/providers.dart';
import 'exif_info_sheet.dart';

// This code for viewing photos and videos in full screen with gesture controls and multi-item swiping
class MediaViewerScreen extends ConsumerStatefulWidget {
  final MediaItem item;
  final List<MediaItem>? items;
  final int initialIndex;

  const MediaViewerScreen({
    super.key,
    required this.item,
    this.items,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  late List<MediaItem> _itemList;
  late int _currentIndex;
  late PageController _pageController;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isUploading = false;

  MediaItem get _currentItem => _itemList[_currentIndex];

  @override
  void initState() {
    super.initState();
    // This code for initializing items list and active index
    if (widget.items != null && widget.items!.isNotEmpty) {
      _itemList = List<MediaItem>.from(widget.items!);
      _currentIndex = widget.initialIndex.clamp(0, _itemList.length - 1);
    } else {
      _itemList = [widget.item];
      _currentIndex = 0;
    }
    _pageController = PageController(initialPage: _currentIndex);
    _initVideoIfApplicable();
  }

  // This code for initializing video controller if active item is a video
  void _initVideoIfApplicable() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;

    final current = _currentItem;
    if (current.mediaType == 'video' && current.filePath != null) {
      _videoController = VideoPlayerController.file(File(current.filePath!))
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isVideoInitialized = true);
            _videoController?.play();
          }
        });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // This code for toggling favorite status of current media item
  Future<void> _toggleFavorite() async {
    final current = _currentItem;
    final newFav = !current.isFavorite;
    final db = ref.read(databaseProvider);
    await db.setFavorite(current.id, newFav);
    setState(() {
      _itemList[_currentIndex] = current.copyWith(isFavorite: newFav);
    });
  }

  // This code for toggling offline pinning status of current media item
  Future<void> _togglePin() async {
    final current = _currentItem;
    final newPin = !current.isPinnedOffline;
    final db = ref.read(databaseProvider);
    await db.setPinnedOffline(current.id, newPin);
    setState(() {
      _itemList[_currentIndex] = current.copyWith(isPinnedOffline: newPin);
    });
  }

  // This code for moving active item to trash topic
  Future<void> _moveToTrash() async {
    final current = _currentItem;
    final db = ref.read(databaseProvider);
    await db.setTrashed(current.id, true);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // This code for sharing the media file using the native device share sheet
  Future<void> _shareMedia() async {
    final current = _currentItem;
    if (current.filePath != null) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(current.filePath!)]),
      );
    }
  }

  // This code for displaying modal sheet with camera EXIF metadata
  void _showExifSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => ExifInfoSheet(item: _currentItem),
    );
  }

  // This code for triggering manual sync upload of active media item
  Future<void> _uploadToVault() async {
    final current = _currentItem;
    if (current.filePath == null) return;

    setState(() => _isUploading = true);

    try {
      final sync = ref.read(syncEngineProvider);
      await sync.queueUpload(mediaId: current.id, priority: 1);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentItem;
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');
    final formattedDate = current.dateTaken != null
        ? dateFormat.format(current.dateTaken!)
        : dateFormat.format(current.dateAdded);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      // This code for clean navigation bar with back button, date indicator, and EXIF sheet action
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.6),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formattedDate,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_itemList.length > 1)
              Text(
                '${_currentIndex + 1} of ${_itemList.length}',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showExifSheet,
          child: const Icon(
            CupertinoIcons.info_circle,
            color: CupertinoColors.white,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // This code for horizontal PageView enabling swipe gestures between media items
            Expanded(
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! > 300) {
                    Navigator.of(context).pop();
                  }
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _itemList.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                    _initVideoIfApplicable();
                  },
                  itemBuilder: (context, index) {
                    final item = _itemList[index];
                    return Center(
                      child: item.mediaType == 'video'
                          ? (_isVideoInitialized &&
                                  _videoController != null &&
                                  index == _currentIndex
                              ? AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      VideoPlayer(_videoController!),
                                      VideoProgressIndicator(
                                        _videoController!,
                                        allowScrubbing: true,
                                        colors: const VideoProgressColors(
                                          playedColor:
                                              CupertinoColors.activeBlue,
                                          bufferedColor:
                                              CupertinoColors.systemGrey,
                                          backgroundColor:
                                              CupertinoColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const CupertinoActivityIndicator(
                                  color: CupertinoColors.white,
                                ))
                          : (item.filePath != null
                              ? InteractiveViewer(
                                  minScale: 0.8,
                                  maxScale: 4.0,
                                  child: Image.file(
                                    File(item.filePath!),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error,
                                            stackTrace) =>
                                        const Icon(
                                      CupertinoIcons.photo,
                                      size: 80,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  CupertinoIcons.photo,
                                  size: 80,
                                  color: CupertinoColors.systemGrey,
                                )),
                    );
                  },
                ),
              ),
            ),
            // This code for presenting caption bar with file size and sync state badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: CupertinoColors.black.withValues(alpha: 0.8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(current.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: current.syncStatus == 'synced'
                          ? CupertinoColors.activeGreen.withValues(alpha: 0.2)
                          : CupertinoColors.systemGrey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          current.syncStatus == 'synced'
                              ? CupertinoIcons.check_mark_circled
                              : CupertinoIcons.arrow_up_circle,
                          size: 13,
                          color: current.syncStatus == 'synced'
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          current.syncStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: current.syncStatus == 'synced'
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // This code for ergonomic bottom action toolbar placed in user thumb zone
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: CupertinoColors.black.withValues(alpha: 0.95),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _shareMedia,
                    child: const Icon(CupertinoIcons.share,
                        color: CupertinoColors.white, size: 24),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _togglePin,
                    child: Icon(
                      current.isPinnedOffline
                          ? CupertinoIcons.pin_fill
                          : CupertinoIcons.pin,
                      color: current.isPinnedOffline
                          ? CupertinoColors.systemYellow
                          : CupertinoColors.white,
                      size: 24,
                    ),
                  ),
                  if (current.syncStatus != 'synced')
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isUploading ? null : _uploadToVault,
                      child: _isUploading
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white)
                          : const Icon(CupertinoIcons.cloud_upload,
                              color: CupertinoColors.activeBlue, size: 24),
                    )
                  else
                    const Icon(CupertinoIcons.checkmark_seal_fill,
                        color: CupertinoColors.activeGreen, size: 22),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _toggleFavorite,
                    child: Icon(
                      current.isFavorite
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      color: current.isFavorite
                          ? CupertinoColors.systemRed
                          : CupertinoColors.white,
                      size: 24,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _moveToTrash,
                    child: const Icon(CupertinoIcons.trash,
                        color: CupertinoColors.destructiveRed, size: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
