// This code for managing general document and file storage in the Telegram vault
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/app_database.dart';
import '../../core/di/providers.dart';
import '../viewer/media_viewer_screen.dart';

// This code for stateful files browser screen with document actions
class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  bool _isCreatingFile = false;

  // This code for formatting byte sizes into human readable strings
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // This code for determining document badge color based on file extension
  Color _getExtensionColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return CupertinoColors.systemRed;
      case 'zip':
      case 'rar':
      case '7z':
        return CupertinoColors.systemOrange;
      case 'doc':
      case 'docx':
      case 'txt':
        return CupertinoColors.systemBlue;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return CupertinoColors.systemGreen;
      default:
        return CupertinoColors.systemIndigo;
    }
  }

  // This code for creating or importing a document into the vault database and syncing to Telegram
  Future<void> _createSampleDocument() async {
    setState(() => _isCreatingFile = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/vault_documents');
      if (!docsDir.existsSync()) {
        docsDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Infinity_Notes_$timestamp.txt';
      final file = File('${docsDir.path}/$fileName');
      await file.writeAsString(
        'Infinity Vault Document\nCreated: ${DateTime.now().toIso8601String()}\nStored securely on Telegram Supergroup #Files.',
      );

      final db = ref.read(databaseProvider);
      final id = 'doc_$timestamp';

      await db.insertMediaItem(
        MediaItemsCompanion.insert(
          id: id,
          filePath: Value(file.path),
          mediaType: 'document',
          fileSize: file.lengthSync(),
          dateAdded: DateTime.now(),
          syncStatus: const Value('local'),
          cloudState: const Value('LOCAL_ONLY'),
        ),
      );

      // Automatically queue document upload to Telegram vault
      final sync = ref.read(syncEngineProvider);
      await sync.queueUpload(mediaId: id, priority: 2);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isCreatingFile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(filesProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Vault Documents'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isCreatingFile ? null : _createSampleDocument,
          child: _isCreatingFile
              ? const CupertinoActivityIndicator()
              : const Icon(CupertinoIcons.add_circled),
        ),
      ),
      child: SafeArea(
        child: filesAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (files) {
            if (files.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.doc_on_doc,
                      size: 56,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Documents in Vault',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap + above to add documents and files\nbacked up to Telegram #Files topic',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              );
            }

            final totalBytes =
                files.fold<int>(0, (sum, item) => sum + item.fileSize);

            return CustomScrollView(
              slivers: [
                // Summary header card
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.folder_fill,
                          color: CupertinoColors.activeBlue,
                          size: 32,
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${files.length} ${files.length == 1 ? 'Document' : 'Documents'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total Storage: ${_formatFileSize(totalBytes)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Documents list
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = files[index];
                      final fileName = item.filePath != null
                          ? item.filePath!.split('/').last
                          : item.id;
                      final ext = fileName.contains('.')
                          ? fileName.split('.').last.toUpperCase()
                          : 'FILE';

                      return CupertinoListTile(
                        leadingSize: 42,
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _getExtensionColor(ext).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              ext,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _getExtensionColor(ext),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15),
                        ),
                        subtitle: Text(
                          '${_formatFileSize(item.fileSize)} • ${DateFormat('MMM d, yyyy').format(item.dateAdded)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.isPinnedOffline)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  CupertinoIcons.pin_fill,
                                  color: CupertinoColors.activeGreen,
                                  size: 14,
                                ),
                              ),
                            Icon(
                              item.syncStatus == 'synced'
                                  ? CupertinoIcons.cloud_upload_fill
                                  : CupertinoIcons.cloud_upload,
                              color: item.syncStatus == 'synced'
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.systemGrey3,
                              size: 18,
                            ),
                          ],
                        ),
                        onTap: () {
                          _showFileActionSheet(item);
                        },
                      );
                    },
                    childCount: files.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // This code for displaying modal popup of file actions (share, pin, sync, trash)
  void _showFileActionSheet(MediaItem item) {
    final fileName = item.filePath != null ? item.filePath!.split('/').last : item.id;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(fileName),
        message: Text('Size: ${_formatFileSize(item.fileSize)} | Status: ${item.syncStatus}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              if (item.filePath != null && File(item.filePath!).existsSync()) {
                SharePlus.instance.share(
                  ShareParams(files: [XFile(item.filePath!)]),
                );
              }
            },
            child: const Text('Share File'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              final db = ref.read(databaseProvider);
              db.setPinnedOffline(item.id, !item.isPinnedOffline);
            },
            child: Text(item.isPinnedOffline ? 'Unpin Offline' : 'Pin Offline (Always on device)'),
          ),
          if (item.syncStatus != 'synced')
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                final sync = ref.read(syncEngineProvider);
                sync.queueUpload(mediaId: item.id, priority: 2);
              },
              child: const Text('Sync to Telegram Vault Now'),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              final db = ref.read(databaseProvider);
              db.setTrashed(item.id, true);
            },
            child: const Text('Move to Trash'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
