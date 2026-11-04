import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../viewer/media_viewer_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favsAsync = ref.watch(favoritesProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Favorites'),
      ),
      child: SafeArea(
        child: favsAsync.when(
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
                      CupertinoIcons.heart,
                      size: 64,
                      color: CupertinoColors.systemGrey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No favorites yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the heart icon on any photo to favorite it',
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
                    // This code for opening media viewer with swipeable favorite items
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => MediaViewerScreen(
                          item: item,
                          items: items,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: item.filePath != null
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
