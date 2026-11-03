import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/storage/gallery_service.dart';
import '../viewer/media_viewer_screen.dart';

class PhotosTimelineScreen extends ConsumerStatefulWidget {
  const PhotosTimelineScreen({super.key});

  @override
  ConsumerState<PhotosTimelineScreen> createState() =>
      _PhotosTimelineScreenState();
}

class _PhotosTimelineScreenState extends ConsumerState<PhotosTimelineScreen> {
  bool _isScanning = false;

  Future<void> _scanDevice() async {
    setState(() => _isScanning = true);
    try {
      final db = ref.read(databaseProvider);
      final service = GalleryService(db);
      await service.scanDeviceMedia(limit: 300);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(allMediaProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Infinity Photos'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isScanning ? null : _scanDevice,
          child: _isScanning
              ? const CupertinoActivityIndicator()
              : const Icon(CupertinoIcons.arrow_2_circlepath),
        ),
      ),
      child: SafeArea(
        child: mediaAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: CupertinoColors.destructiveRed),
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

            return GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
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
