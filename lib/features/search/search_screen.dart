// This code for providing search and interactive filtering across vault media and files
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/di/providers.dart';
import '../viewer/media_viewer_screen.dart';

// This code for managing stateful search criteria and filter selections
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedScope = 'all'; // 'all', 'image', 'video', 'files', 'favorites', 'pinned'
  String _dateFilter = 'any'; // 'any', 'week', 'month', 'year'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // This code for computing start date bound based on selected date filter chip
  DateTime? _getStartDate() {
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return now.subtract(const Duration(days: 30));
      case 'year':
        return DateTime(now.year, 1, 1);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final startDate = _getStartDate();

    // Determine query parameters based on selected scope
    final String? mediaTypeParam =
        (_selectedScope == 'image' || _selectedScope == 'video' || _selectedScope == 'files')
            ? _selectedScope
            : null;
    final bool? isFavParam = _selectedScope == 'favorites' ? true : null;
    final bool? isPinnedParam = _selectedScope == 'pinned' ? true : null;

    final searchStream = db.searchMedia(
      query: _searchQuery,
      mediaType: mediaTypeParam,
      startDate: startDate,
      isFavorite: isFavParam,
      isPinnedOffline: isPinnedParam,
    );

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Search Vault'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // This code for rendering search text input field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search files, dates, or tags...',
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
                onSubmitted: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
            ),

            // This code for rendering scope filter selector pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildScopePill('All', 'all'),
                  _buildScopePill('Photos', 'image'),
                  _buildScopePill('Videos', 'video'),
                  _buildScopePill('Files', 'files'),
                  _buildScopePill('Favorites', 'favorites'),
                  _buildScopePill('Pinned', 'pinned'),
                ],
              ),
            ),

            // This code for rendering date range filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildDateChip('Any Time', 'any'),
                  _buildDateChip('Past 7 Days', 'week'),
                  _buildDateChip('Past 30 Days', 'month'),
                  _buildDateChip('This Year', 'year'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // This code for displaying real-time filtered media grid stream
            Expanded(
              child: StreamBuilder<List<MediaItem>>(
                stream: searchStream,
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
                            CupertinoIcons.search,
                            size: 48,
                            color: CupertinoColors.systemGrey.resolveFrom(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty && _selectedScope == 'all' && _dateFilter == 'any'
                                ? 'Search by name, category, or date range'
                                : 'No matching items found',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Text(
                          '${items.length} ${items.length == 1 ? 'item' : 'items'} found',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(4),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 3,
                            mainAxisSpacing: 3,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            // This code for rendering each search result tile with swipe context
                            return _buildGridTile(item, items, index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // This code for building clickable scope filter pill
  Widget _buildScopePill(String title, String value) {
    final isSelected = _selectedScope == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedScope = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey5.resolveFrom(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? CupertinoColors.white
                  : CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ),
      ),
    );
  }

  // This code for building clickable date filter chip
  Widget _buildDateChip(String title, String value) {
    final isSelected = _dateFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _dateFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? CupertinoColors.activeOrange
                : CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? CupertinoColors.white
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
      ),
    );
  }

  // This code for rendering an individual media item tile in search results with swipe capability
  Widget _buildGridTile(
      MediaItem item, List<MediaItem> allResults, int index) {
    final date = item.dateTaken ?? item.dateAdded;
    final isDocument = item.mediaType != 'image' && item.mediaType != 'video';

    return GestureDetector(
      onTap: () {
        // This code for opening media viewer with list of matching search results
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => MediaViewerScreen(
              item: item,
              items: allResults,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            child: isDocument
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.doc_text,
                          size: 32,
                          color: CupertinoColors.activeBlue,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            item.filePath != null
                                ? item.filePath!.split('/').last
                                : item.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  )
                : item.thumbnailPath != null && File(item.thumbnailPath!).existsSync()
                    ? Image.file(
                        File(item.thumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallback(item),
                      )
                    : item.filePath != null && File(item.filePath!).existsSync()
                        ? Image.file(
                            File(item.filePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallback(item),
                          )
                        : _buildFallback(item),
          ),

          // Video indicator badge
          if (item.mediaType == 'video')
            const Positioned(
              left: 4,
              bottom: 4,
              child: Icon(
                CupertinoIcons.play_circle_fill,
                color: CupertinoColors.white,
                size: 16,
              ),
            ),

          // Favorite badge
          if (item.isFavorite)
            const Positioned(
              right: 4,
              top: 4,
              child: Icon(
                CupertinoIcons.heart_fill,
                color: CupertinoColors.systemRed,
                size: 14,
              ),
            ),

          // Offline pinned badge
          if (item.isPinnedOffline)
            const Positioned(
              left: 4,
              top: 4,
              child: Icon(
                CupertinoIcons.pin_fill,
                color: CupertinoColors.activeGreen,
                size: 13,
              ),
            ),

          // Timestamp overlay
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: CupertinoColors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                DateFormat('MMM d').format(date),
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This code for rendering fallback placeholder icon when thumbnail file is unavailable
  Widget _buildFallback(MediaItem item) {
    return Center(
      child: Icon(
        item.mediaType == 'video'
            ? CupertinoIcons.video_camera
            : CupertinoIcons.photo,
        color: CupertinoColors.systemGrey,
        size: 28,
      ),
    );
  }
}

