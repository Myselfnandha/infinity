import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../core/database/app_database.dart';
import '../../core/di/providers.dart';
import 'exif_info_sheet.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  final MediaItem item;

  const MediaViewerScreen({super.key, required this.item});

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  late bool _isFavorite;
  late bool _isPinned;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorite;
    _isPinned = widget.item.isPinnedOffline;

    if (widget.item.mediaType == 'video' && widget.item.filePath != null) {
      _videoController = VideoPlayerController.file(File(widget.item.filePath!))
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
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final newFav = !_isFavorite;
    setState(() => _isFavorite = newFav);
    final db = ref.read(databaseProvider);
    await db.setFavorite(widget.item.id, newFav);
  }

  Future<void> _togglePin() async {
    final newPin = !_isPinned;
    setState(() => _isPinned = newPin);
    final db = ref.read(databaseProvider);
    await db.setPinnedOffline(widget.item.id, newPin);
  }

  Future<void> _moveToTrash() async {
    final db = ref.read(databaseProvider);
    await db.setTrashed(widget.item.id, true);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // This code for sharing the media file using the native device share sheet
  Future<void> _shareMedia() async {
    if (widget.item.filePath != null) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(widget.item.filePath!)]),
      );
    }
  }

  void _showExifSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => ExifInfoSheet(item: widget.item),
    );
  }

  Future<void> _uploadToVault() async {
    if (widget.item.filePath == null) return;

    setState(() => _isUploading = true);

    try {
      final sync = ref.read(syncEngineProvider);
      await sync.queueUpload(mediaId: widget.item.id, priority: 1);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');
    final formattedDate = widget.item.dateTaken != null
        ? dateFormat.format(widget.item.dateTaken!)
        : dateFormat.format(widget.item.dateAdded);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.6),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: Text(
          widget.item.mediaType.toUpperCase(),
          style: const TextStyle(color: CupertinoColors.white),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showExifSheet,
              child: const Icon(
                CupertinoIcons.info_circle,
                color: CupertinoColors.white,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _shareMedia,
              child: const Icon(
                CupertinoIcons.share,
                color: CupertinoColors.white,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _togglePin,
              child: Icon(
                _isPinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin,
                color: _isPinned
                    ? CupertinoColors.systemYellow
                    : CupertinoColors.white,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _toggleFavorite,
              child: Icon(
                _isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                color: _isFavorite
                    ? CupertinoColors.systemRed
                    : CupertinoColors.white,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _isUploading ? null : _uploadToVault,
              child: _isUploading
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : Icon(
                      widget.item.syncStatus == 'synced'
                          ? CupertinoIcons.cloud_upload_fill
                          : CupertinoIcons.cloud_upload,
                      color: widget.item.syncStatus == 'synced'
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.white,
                    ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _moveToTrash,
              child: const Icon(
                CupertinoIcons.trash,
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! > 300) {
                    Navigator.of(context).pop();
                  }
                },
                child: Center(
                  child: widget.item.mediaType == 'video'
                      ? (_isVideoInitialized && _videoController != null
                          ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  VideoPlayer(_videoController!),
                                  VideoProgressIndicator(
                                    _videoController!,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: CupertinoColors.activeBlue,
                                      bufferedColor: CupertinoColors.systemGrey,
                                      backgroundColor: CupertinoColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            ))
                      : (widget.item.filePath != null
                          ? InteractiveViewer(
                              minScale: 0.8,
                              maxScale: 4.0,
                              child: Image.file(
                                File(widget.item.filePath!),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
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
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: CupertinoColors.black.withValues(alpha: 0.8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(widget.item.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.item.syncStatus == 'synced'
                          ? CupertinoColors.activeGreen.withValues(alpha: 0.2)
                          : CupertinoColors.systemGrey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.item.syncStatus == 'synced'
                              ? CupertinoIcons.check_mark_circled
                              : CupertinoIcons.arrow_up_circle,
                          size: 14,
                          color: widget.item.syncStatus == 'synced'
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.item.syncStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.item.syncStatus == 'synced'
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
          ],
        ),
      ),
    );
  }
}
