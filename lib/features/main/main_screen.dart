// This code for root application scaffold featuring primary Cupertino tab navigation and adaptive selection toolbar
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  DateTime? _lastBackPressTime;
  OverlayEntry? _toastEntry;

  // This code for persistent tab view hierarchy
  final List<Widget> _screens = const [
    PhotosTimelineScreen(),
    AlbumsScreen(),
    SearchScreen(),
    FilesScreen(),
    SettingsScreen(),
  ];

  @override
  void dispose() {
    _toastEntry?.remove();
    _toastEntry = null;
    super.dispose();
  }

  // Shows an unobtrusive floating notification requesting a second back-tap confirmation
  void _showExitToast() {
    _toastEntry?.remove();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 76,
        left: 24,
        right: 24,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.darkBackgroundGray.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.info_circle_fill, color: CupertinoColors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Press back again to exit',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    _toastEntry = entry;
    Future.delayed(const Duration(seconds: 2), () {
      if (_toastEntry == entry) {
        entry.remove();
        _toastEntry = null;
      }
    });
  }

  // Handles Android back button navigation to ensure Photos screen is primary root
  void _handlePopInvoked(bool didPop) {
    if (didPop) return;

    final isSelectionMode = ref.read(selectionModeProvider);
    if (isSelectionMode) {
      ref.read(selectionModeProvider.notifier).setSelectionMode(false);
      ref.read(selectedMediaIdsProvider.notifier).clear();
      return;
    }

    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      _showExitToast();
    } else {
      _toastEntry?.remove();
      _toastEntry = null;
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // This code for watching active gallery selection mode to dynamically toggle bottom bar
    final isSelectionMode = ref.watch(selectionModeProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handlePopInvoked(didPop),
      child: CupertinoPageScaffold(
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
      ),
    );
  }
}
