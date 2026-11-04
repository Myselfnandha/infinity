// This code for managing device storage, viewing cache breakdown, and freeing local space
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';

// This code for rendering storage stats and cache cleaner sub-page
class StorageCleanerScreen extends ConsumerStatefulWidget {
  const StorageCleanerScreen({super.key});

  @override
  ConsumerState<StorageCleanerScreen> createState() =>
      _StorageCleanerScreenState();
}

class _StorageCleanerScreenState extends ConsumerState<StorageCleanerScreen> {
  bool _isCleaning = false;
  int _cacheSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  // This code for computing current local cached media size
  Future<void> _loadCacheSize() async {
    final cacheManager = ref.read(cacheManagerProvider);
    final size = await cacheManager.calculateCacheSizeBytes();
    if (mounted) {
      setState(() => _cacheSizeBytes = size);
    }
  }

  // This code for freeing up phone storage by deleting local copies of already backed up media
  Future<void> _freeUpSpace() async {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Free Up Device Space?'),
        message: const Text(
          'Original files that have been safely backed up to your Telegram Vault will be removed from local storage. Thumbnails remain and originals will stream on-demand.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isCleaning = true);
              try {
                final cacheManager = ref.read(cacheManagerProvider);
                final bytesFreed = await cacheManager.freeUpDeviceSpace();
                await _loadCacheSize();
                if (mounted) {
                  final mbFreed =
                      (bytesFreed / (1024 * 1024)).toStringAsFixed(1);
                  showCupertinoDialog(
                    context: context,
                    builder: (alertCtx) => CupertinoAlertDialog(
                      title: const Text('Space Cleaned'),
                      content: Text(
                          'Successfully freed $mbFreed MB of device storage!'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () => Navigator.of(alertCtx).pop(),
                        ),
                      ],
                    ),
                  );
                }
              } catch (_) {
              } finally {
                if (mounted) setState(() => _isCleaning = false);
              }
            },
            child: const Text('Free Up Space'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(allMediaProvider);

    final totalItems = mediaAsync.value?.length ?? 0;
    final syncedItems =
        mediaAsync.value?.where((e) => e.syncStatus == 'synced').length ?? 0;
    final totalBytes = mediaAsync.value?.fold<int>(
            0, (prev, element) => prev + element.fileSize) ??
        0;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        previousPageTitle: 'Settings',
        middle: Text('Storage & Cleaner'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Media Items'),
                        Text(
                          '$totalItems items',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Vault Synced Items'),
                        Text(
                          '$syncedItems / $totalItems',
                          style: const TextStyle(
                            color: CupertinoColors.activeBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Media Size'),
                        Text(
                          '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Local Cache Used'),
                        Text(
                          '${(_cacheSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // This code for free up space button
            CupertinoButton(
              color: CupertinoColors.activeBlue.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: _isCleaning ? null : _freeUpSpace,
              child: Center(
                child: _isCleaning
                    ? const CupertinoActivityIndicator()
                    : const Text(
                        'Free Up Device Space',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Freeing up device space deletes local copies of media items that are confirmed backed up in your Telegram vault. You can stream or re-download them anytime.',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
