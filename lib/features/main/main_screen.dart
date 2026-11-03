// This code for root application scaffold featuring primary Cupertino tab navigation
import 'package:flutter/cupertino.dart';
import '../albums/albums_screen.dart';
import '../files/files_screen.dart';
import '../gallery/photos_timeline_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
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
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const PhotosTimelineScreen();
          case 1:
            return const AlbumsScreen();
          case 2:
            return const SearchScreen();
          case 3:
            return const FilesScreen();
          case 4:
            return const SettingsScreen();
          default:
            return const PhotosTimelineScreen();
        }
      },
    );
  }
}
