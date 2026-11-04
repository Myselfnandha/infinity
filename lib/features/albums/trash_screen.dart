// This code for managing and restoring deleted media in the dedicated Telegram Trash album
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/di/providers.dart';

// This code for rendering the Trash screen allowing item recovery or permanent local removal
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  // This code for restoring an item from trash back to the main photo library
  Future<void> _restoreItem(MediaItem item) async {
    final db = ref.read(databaseProvider);
    await db.setTrashed(item.id, false);
  }

  // This code for restoring all trashed items back to active library
  Future<void> _restoreAll(List<MediaItem> items) async {
    final db = ref.read(databaseProvider);
    for (final item in items) {
      await db.setTrashed(item.id, false);
    }
  }

  // This code for showing confirmation dialog to empty trash
  void _confirmEmptyTrash(List<MediaItem> items) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Empty Trash?'),
        message: const Text(
          'Media files will be removed from your device. If synced, your backup remains permanently safe in your Telegram Vault #Trash topic.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final db = ref.read(databaseProvider);
              for (final item in items) {
                if (item.filePath != null) {
                  try {
                    final f = File(item.filePath!);
                    if (await f.exists()) {
                      await f.delete();
                    }
                  } catch (_) {}
                }
                await (db.delete(db.mediaItems)
                      ..where((tbl) => tbl.id.equals(item.id)))
                    .go();
              }
            },
            child: const Text('Empty Trash'),
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
    final trashAsync = ref.watch(trashProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Trash'),
        trailing: trashAsync.maybeWhen(
          data: (items) => items.isNotEmpty
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _confirmEmptyTrash(items),
                  child: const Text(
                    'Empty',
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                )
              : null,
          orElse: () => null,
        ),
      ),
      child: SafeArea(
        child: trashAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: CupertinoColors.destructiveRed),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.trash,
                      size: 64,
                      color: CupertinoColors.systemGrey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Trash is Empty',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Deleted photos and videos stay here until emptied',
                      style: TextStyle(
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${items.length} items in Trash',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _restoreAll(items),
                        child: const Text(
                          'Restore All',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(2),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () {
                          // This code for presenting action sheet to restore selected trashed item
                          final displayName = item.filePath != null
                              ? item.filePath!.split('/').last
                              : 'Media Item';
                          showCupertinoModalPopup(
                            context: context,
                            builder: (ctx) => CupertinoActionSheet(
                              title: Text(displayName),
                              actions: [
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _restoreItem(item);
                                  },
                                  child: const Text('Restore Photo'),
                                ),
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
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
                                    cacheWidth: 360,
                                    cacheHeight: 360,
                                    filterQuality: FilterQuality.low,
                                    errorBuilder: (ctx, err, stack) =>
                                        Container(
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
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.black
                                      .withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.arrow_counterclockwise,
                                  size: 14,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
