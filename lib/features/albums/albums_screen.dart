// This code for managing and displaying Telegram forum supergroup topic albums
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'album_detail_screen.dart';
import 'trash_screen.dart';

// This code for rendering the album overview screen with topic mappings
class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  final TextEditingController _albumNameController = TextEditingController();

  @override
  void dispose() {
    _albumNameController.dispose();
    super.dispose();
  }

  void _showCreateAlbumDialog() {
    _albumNameController.clear();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('New Album'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: _albumNameController,
            placeholder: 'Album Name (e.g. Vacation)',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final name = _albumNameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(ctx).pop();
                final tdlib = ref.read(tdlibServiceProvider);
                await tdlib.createTopic(name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tdlib = ref.watch(tdlibServiceProvider);
    final vaultId = tdlib.vaultChatId;

    final defaultAlbums = [
      {'name': 'Photos', 'icon': CupertinoIcons.photo, 'topic': 'Photos'},
      {'name': 'Videos', 'icon': CupertinoIcons.video_camera, 'topic': 'Videos'},
      {
        'name': 'Screenshots',
        'icon': CupertinoIcons.device_phone_portrait,
        'topic': 'Screenshots'
      },
      {'name': 'Files', 'icon': CupertinoIcons.doc_on_doc, 'topic': 'Files'},
      {'name': 'Trash', 'icon': CupertinoIcons.trash, 'topic': 'Trash'},
    ];

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Albums & Topics'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showCreateAlbumDialog,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.infinite,
                    color: CupertinoColors.activeBlue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Infinity Vault Supergroup',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vaultId != null
                              ? 'Chat ID: $vaultId • Forum Mode Active'
                              : 'Connecting to Telegram supergroup...',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'TELEGRAM TOPIC ALBUMS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 8),
            ...defaultAlbums.map((album) {
              final albumName = album['name'] as String;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
                child: CupertinoListTile(
                  leading: Icon(
                    album['icon'] as IconData,
                    color: albumName == 'Trash'
                        ? CupertinoColors.destructiveRed
                        : CupertinoColors.activeBlue,
                  ),
                  title: Text(
                    albumName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('Maps to topic: #${album['topic']}'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    // This code for navigating to Trash or specific album detail screen
                    if (albumName == 'Trash') {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => const TrashScreen(),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => AlbumDetailScreen(title: albumName),
                        ),
                      );
                    }
                  },
                ),
              );
            }),
            // This code for displaying user-created custom topic albums from SQLite
            ref.watch(albumsProvider).when(
                  data: (customAlbums) {
                    if (customAlbums.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'CUSTOM TOPIC ALBUMS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...customAlbums.map((cust) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBackground
                                  .resolveFrom(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: CupertinoColors.separator
                                    .resolveFrom(context),
                                width: 0.5,
                              ),
                            ),
                            child: CupertinoListTile(
                              leading: const Icon(
                                CupertinoIcons.folder_fill,
                                color: CupertinoColors.activeBlue,
                              ),
                              title: Text(
                                cust.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                  'Topic ID: #${cust.topicId ?? 'Pending'}'),
                              trailing: const CupertinoListTileChevron(),
                              onTap: () {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (_) => AlbumDetailScreen(
                                      title: cust.title,
                                      albumId: cust.id,
                                      topicId: cust.topicId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
          ],
        ),
      ),
    );
  }
}
