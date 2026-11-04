// This code for root application scaffold featuring primary Cupertino tab navigation and adaptive selection toolbar
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../albums/albums_screen.dart';
import '../files/files_screen.dart';
import '../gallery/photos_timeline_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

// This code for managing root application tab navigation and dynamic bottom bar visibility
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  // This code for persistent tab view hierarchy
  final List<Widget> _screens = const [
    PhotosTimelineScreen(),
    AlbumsScreen(),
    SearchScreen(),
    FilesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // This code for watching active gallery selection mode to dynamically toggle bottom bar
    final isSelectionMode = ref.watch(selectionModeProvider);

    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          // This code for hiding tab navigation bar when gallery selection mode is active
          if (!isSelectionMode)
            CupertinoTabBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.photo_on_rectangle),
                  label: 'Photos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.folder),
                  label: 'Albums',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.doc_on_doc),
                  label: 'Files',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.gear_alt),
                  label: 'Settings',
                ),
              ],
            ),
        ],
      ),
    );
  }
}
