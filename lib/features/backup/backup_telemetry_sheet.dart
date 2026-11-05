// This code for OLED Minimalist operational backup telemetry hub ported from telecloud_photos
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/di/providers.dart';
import '../../core/storage/gallery_service.dart';
import '../../core/sync/sync_engine.dart';
import 'widgets/m3e_wavy_progress_indicator.dart';

/// Modal Telemetry Hub & Operational Backup Queue Viewer
/// Displays live upload throughput, worker activity, and queued Telegram vault files.
class BackupTelemetrySheet extends ConsumerStatefulWidget {
  const BackupTelemetrySheet({super.key});

  /// Displays the telemetry sheet as an interactive modal bottom sheet
  static Future<void> show(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return showCupertinoModalPopup(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: const BackupTelemetrySheet(),
        ),
      ),
    );
  }

  @override
  ConsumerState<BackupTelemetrySheet> createState() => _BackupTelemetrySheetState();
}

class _BackupTelemetrySheetState extends ConsumerState<BackupTelemetrySheet>
    with SingleTickerProviderStateMixin {
  final Set<String> _expandedFolders = {'Camera Roll'};
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleFolderExpanded(String folder) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedFolders.contains(folder)) {
        _expandedFolders.remove(folder);
      } else {
        _expandedFolders.add(folder);
      }
    });
  }

  void _togglePause(SyncEngine engine, bool isCurrentlyPaused) {
    HapticFeedback.lightImpact();
    if (isCurrentlyPaused) {
      engine.resumeSync();
    } else {
      engine.pauseSync();
    }
  }

  Future<void> _forceScan() async {
    HapticFeedback.mediumImpact();
    try {
      ref.read(isMediaScanningProvider.notifier).setScanning(true);
      final db = ref.read(databaseProvider);
      final gallery = GalleryService(db);
      final count = await gallery.scanDeviceMedia(limit: 500);
      await ref.read(syncEngineProvider).autoQueueUnsynced();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanned $count new items. Syncing with Telegram Vault...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
    } finally {
      ref.read(isMediaScanningProvider.notifier).setScanning(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final engine = ref.watch(syncEngineProvider);

    final telemetryAsync = ref.watch(uploadTelemetryProvider);
    final telemetry = telemetryAsync.value ?? engine.currentTelemetry;
    final isPaused = telemetry.isPaused;

    final pendingItemsAsync = ref.watch(pendingUploadMediaProvider);
    final pendingItems = pendingItemsAsync.value ?? [];
    final totalPending = pendingItems.length;
    final isUploading = telemetry.activeWorkers > 0 && !isPaused;

    // Progress calculation
    final progressValue = totalPending > 0
        ? (telemetry.totalCount > 0
            ? telemetry.progressPercentage
            : (isUploading ? 0.3 : 0.05))
        : 1.0;

    // Status accent color & label
    final Color statusAccentColor;
    final String statusLabel;
    if (isPaused) {
      statusAccentColor = const Color(0xFFFFB300); // Amber
      statusLabel = 'TRANSMISSION PAUSED';
    } else if (isUploading) {
      statusAccentColor = const Color(0xFF00E676); // Emerald pulse
      statusLabel = 'UPLINK ACTIVE';
    } else if (totalPending > 0) {
      statusAccentColor = const Color(0xFF00E5FF); // Cyan
      statusLabel = 'QUEUE READY';
    } else {
      statusAccentColor = const Color(0xFF00E5FF); // Cyan
      statusLabel = 'CLOUD SYNCHRONIZED';
    }

    final sheetHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? const Color(0xFF22272E) : CupertinoColors.systemGrey5,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Drag handle pill
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusAccentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        color: statusAccentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Uploads & Telemetry',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Rescan Device',
                      onPressed: _forceScan,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================================
                  // OLED MINIMALIST TELEMETRY HUB CARD
                  // ========================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: statusAccentColor.withValues(alpha: isDark ? 0.35 : 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusAccentColor.withValues(alpha: isDark ? 0.12 : 0.08),
                          blurRadius: 20,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Status Pill with live animated pulse dot + Supergroup badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusAccentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusAccentColor.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      final double glowRadius = isUploading
                                          ? 3.0 + (_pulseAnimation.value * 5.0)
                                          : 2.0;
                                      return Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: statusAccentColor,
                                          boxShadow: [
                                            BoxShadow(
                                              color: statusAccentColor.withValues(
                                                alpha: isUploading ? 0.8 : 0.4,
                                              ),
                                              blurRadius: glowRadius,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: statusAccentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.send_rounded,
                                  size: 15,
                                  color: CupertinoColors.activeBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Telegram Vault',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Hero Speed Gauge Readout
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              isPaused
                                  ? '0.0 KB/s'
                                  : (isUploading
                                      ? telemetry.speedFormatted
                                      : (totalPending > 0 ? 'Ready' : 'Synced')),
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isPaused
                                    ? const Color(0xFFFFB300)
                                    : (isUploading
                                        ? const Color(0xFF00E5FF)
                                        : (isDark ? Colors.white : Colors.black87)),
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isUploading ? 'THROUGHPUT' : (isPaused ? 'PAUSED' : 'STATUS'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Subtitle telemetry info
                        Text(
                          isPaused
                              ? '$totalPending items held in queue. Tap Resume to restart MTProto pipeline.'
                              : (isUploading
                                  ? 'Uploading: ${telemetry.currentFileName.isNotEmpty ? telemetry.currentFileName : "Streaming batch..."}'
                                  : (totalPending > 0
                                      ? '$totalPending media items queued for automatic Telegram backup.'
                                      : 'All photos and videos are safe in your Telegram Cloud Supergroup.')),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 18),

                        // Telemetry Micro-Sensors Row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.45)
                                : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildTelemetrySensor(
                                icon: Icons.queue,
                                label: 'QUEUED',
                                value: '$totalPending items',
                                valueColor: isDark ? Colors.white : Colors.black87,
                              ),
                              Container(
                                height: 24,
                                width: 1,
                                color: isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8),
                              ),
                              _buildTelemetrySensor(
                                icon: Icons.bolt,
                                label: 'WORKERS',
                                value: telemetry.activeWorkers > 0
                                    ? '${telemetry.activeWorkers} Active'
                                    : 'Standby',
                                valueColor: telemetry.activeWorkers > 0
                                    ? const Color(0xFF00E676)
                                    : (isDark ? Colors.white54 : Colors.black45),
                              ),
                              Container(
                                height: 24,
                                width: 1,
                                color: isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8),
                              ),
                              _buildTelemetrySensor(
                                icon: Icons.cloud_done_outlined,
                                label: 'SYNCED',
                                value: '${telemetry.completedCount}',
                                valueColor: const Color(0xFF00E5FF),
                              ),
                            ],
                          ),
                        ),

                        // Wavy Progress Indicator (during active upload)
                        if (isUploading) ...[
                          const SizedBox(height: 16),
                          M3EWavyProgressIndicator(
                            progress: progressValue,
                            height: 14,
                            color: const Color(0xFF00E5FF),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Docked Telemetry Command Bar inside Card Footer
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.35)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => _togglePause(engine, isPaused),
                                  icon: Icon(
                                    isPaused ? Icons.play_arrow : Icons.pause,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isPaused ? 'Resume' : 'Pause',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isPaused
                                        ? const Color(0xFFFFB300)
                                        : (isDark ? Colors.white : Colors.black87),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: _forceScan,
                                  icon: const Icon(Icons.sync, size: 18),
                                  label: const Text(
                                    'Scan Now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDark ? Colors.white : Colors.black87,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Monitored Folders Section
                  Text(
                    'Monitored Backup Folders',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Monitored Folder Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            avatar: const Icon(Icons.camera_alt, size: 16),
                            label: Text('Camera Roll ($totalPending queued)'),
                            backgroundColor: isDark ? const Color(0xFF161B22) : const Color(0xFFE1E4E8),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            avatar: const Icon(Icons.videocam, size: 16),
                            label: const Text('Videos'),
                            backgroundColor: isDark ? const Color(0xFF161B22) : const Color(0xFFE1E4E8),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            avatar: const Icon(Icons.screenshot, size: 16),
                            label: const Text('Screenshots'),
                            backgroundColor: isDark ? const Color(0xFF161B22) : const Color(0xFFE1E4E8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Active Transfer Queue Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Transfer Queue ($totalPending)',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (totalPending > 0)
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            engine.resumeSync();
                          },
                          child: const Text('Start All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Transfer Queue Content
                  if (pendingItems.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00E676).withValues(alpha: 0.12),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                size: 44,
                                color: Color(0xFF00E676),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Transfer queue is empty',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Any newly captured media will queue and upload automatically.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    ..._buildFolderAccordions(pendingItems, isDark),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFolderAccordions(List<MediaItem> pendingItems, bool isDark) {
    final Map<String, List<MediaItem>> grouped = {};
    for (final item in pendingItems) {
      final folder = item.mediaType == 'video'
          ? 'Videos'
          : (item.mediaType == 'document' ? 'Files' : 'Camera Roll');
      grouped.putIfAbsent(folder, () => []).add(item);
    }

    return grouped.entries.map((entry) {
      final folderName = entry.key;
      final items = entry.value;
      final isExpanded = _expandedFolders.contains(folderName);
      final double totalFolderBytes =
          items.fold(0.0, (sum, i) => sum + i.fileSize.toDouble());
      final sizeFormatted = totalFolderBytes > 1024 * 1024 * 1024
          ? '${(totalFolderBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
          : '${(totalFolderBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13171D) : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8),
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => _toggleFolderExpanded(folderName),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          folderName.toLowerCase().contains('camera')
                              ? Icons.camera_alt_outlined
                              : (folderName.toLowerCase().contains('video')
                                  ? Icons.videocam_outlined
                                  : Icons.folder_outlined),
                          size: 20,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              folderName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${items.length} items • $sizeFormatted',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.take(15).length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF21262D) : const Color(0xFFEAEEF2),
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isVideo = item.mediaType == 'video';
                    final fileName = item.filePath != null
                        ? item.filePath!.split(Platform.pathSeparator).last
                        : 'Media item ${index + 1}';
                    final sizeMB = (item.fileSize / (1024 * 1024)).toStringAsFixed(1);

                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF21262D) : const Color(0xFFDEE2E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isVideo ? Icons.videocam : Icons.photo,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      title: Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '$sizeMB MB • Queued for Vault',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.cloud_upload_outlined,
                        color: CupertinoColors.activeBlue,
                        size: 20,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTelemetrySensor({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: valueColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: valueColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
