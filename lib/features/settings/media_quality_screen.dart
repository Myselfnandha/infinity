// This code for configuring media upload compression and playback optimization preferences
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';

// This code for rendering media quality and compression settings sub-page
class MediaQualityScreen extends ConsumerStatefulWidget {
  const MediaQualityScreen({super.key});

  @override
  ConsumerState<MediaQualityScreen> createState() => _MediaQualityScreenState();
}

class _MediaQualityScreenState extends ConsumerState<MediaQualityScreen> {
  // This code for building toggle switch tile
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // This code for rendering divider between setting items
  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 16),
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        previousPageTitle: 'Settings',
        middle: Text('Media & Quality'),
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
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Upload Compression',
                    subtitle: 'Off preserves 100% original lossless quality',
                    value: prefs.isUploadCompressionEnabled,
                    onChanged: (val) async {
                      await prefs.setUploadCompressionEnabled(val);
                      setState(() {});
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    title: 'Download Compression',
                    subtitle: 'Off downloads original uncompressed files',
                    value: prefs.isDownloadCompressionEnabled,
                    onChanged: (val) async {
                      await prefs.setDownloadCompressionEnabled(val);
                      setState(() {});
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    title: 'Optimized Playback',
                    subtitle: 'Stream adaptive previews for smoother gallery scrolling',
                    value: prefs.isPlaybackOptimized,
                    onChanged: (val) async {
                      await prefs.setPlaybackOptimized(val);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'When Upload Compression is disabled, files are uploaded directly as documents to retain all camera RAW, EXIF, and color metadata intact.',
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
