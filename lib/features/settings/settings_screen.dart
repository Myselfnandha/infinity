// This code for managing application settings, backup schedules, storage cache, media compression, and Telegram vault configuration
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/storage/gallery_service.dart';

// This code for rendering the complete settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;
  bool _isCleaning = false;
  int _cacheSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  // This code for computing current local cached media size
  Future<void> _loadCacheSize() async {
    final cacheManager = ref.read(cacheManagerProvider);
    final size = await cacheManager.calculateCacheSizeBytes();
    if (mounted) {
      setState(() => _cacheSizeBytes = size);
    }
  }

  // This code for initiating manual device scan and backup check
  Future<void> _manualSync() async {
    setState(() => _isSyncing = true);
    try {
      final db = ref.read(databaseProvider);
      final gallery = GalleryService(db);
      await gallery.scanDeviceMedia(limit: 500);

      final sync = ref.read(syncEngineProvider);
      await sync.autoQueueUnsynced();
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  // This code for freeing up phone storage by deleting local copies of already backed up media
  Future<void> _freeUpSpace() async {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Free Up Device Space?'),
        message: const Text(
          'Original files that have been safely backed up to your Telegram Vault will be removed from local storage. Thumbnails remain and originals will stream on-demand.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isCleaning = true);
              try {
                final cacheManager = ref.read(cacheManagerProvider);
                final bytesFreed = await cacheManager.freeUpDeviceSpace();
                await _loadCacheSize();
                if (mounted) {
                  final mbFreed = (bytesFreed / (1024 * 1024)).toStringAsFixed(1);
                  showCupertinoDialog(
                    context: context,
                    builder: (alertCtx) => CupertinoAlertDialog(
                      title: const Text('Space Cleaned'),
                      content: Text('Successfully freed $mbFreed MB of device storage!'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () => Navigator.of(alertCtx).pop(),
                        ),
                      ],
                    ),
                  );
                }
              } catch (_) {
              } finally {
                if (mounted) setState(() => _isCleaning = false);
              }
            },
            child: const Text('Free Up Space'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // This code for logging out of the Telegram account
  Future<void> _logOut() async {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Log Out from Telegram?'),
        message: const Text('Disconnects this device from your Infinity Vault supergroup.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final tdlib = ref.read(tdlibServiceProvider);
              await tdlib.logOut();
              if (mounted) {
                context.go('/auth');
              }
            },
            child: const Text('Log Out'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // This code for building settings section card
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // This code for building toggle tile with description
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

  // This code for rendering an iOS-style thin separator line
  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 16),
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tdlib = ref.watch(tdlibServiceProvider);
    final prefs = ref.watch(preferencesProvider);
    final mediaAsync = ref.watch(allMediaProvider);

    final totalItems = mediaAsync.value?.length ?? 0;
    final syncedItems =
        mediaAsync.value?.where((e) => e.syncStatus == 'synced').length ?? 0;
    final totalBytes = mediaAsync.value?.fold<int>(
            0, (prev, element) => prev + element.fileSize) ??
        0;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings & Vault'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // This code for Telegram Vault status overview card
            _buildSection(
              title: 'INFINITY TELEGRAM VAULT',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Vault Supergroup Status'),
                          Text(
                            tdlib.vaultChatId != null
                                ? 'Connected'
                                : 'Connecting...',
                            style: TextStyle(
                              color: tdlib.vaultChatId != null
                                  ? CupertinoColors.activeGreen
                                  : CupertinoColors.systemOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Telegram Chat ID'),
                          Text(
                            tdlib.vaultChatId?.toString() ?? 'Auto-detecting',
                            style: const TextStyle(
                                color: CupertinoColors.secondaryLabel),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Connected Account'),
                          Text(
                            tdlib.authPhoneNumber ?? 'Active Session',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // This code for media compression & quality settings
            _buildSection(
              title: 'MEDIA QUALITY & COMPRESSION',
              children: [
                _buildSwitchTile(
                  title: 'Upload Compression',
                  subtitle:
                      'Default is off for original, lossless quality uploads',
                  value: prefs.isUploadCompressionEnabled,
                  onChanged: (val) async {
                    await prefs.setUploadCompressionEnabled(val);
                    setState(() {});
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Download Compression',
                  subtitle:
                      'Default is off for original uncompressed file downloads',
                  value: prefs.isDownloadCompressionEnabled,
                  onChanged: (val) async {
                    await prefs.setDownloadCompressionEnabled(val);
                    setState(() {});
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Optimized Playback',
                  subtitle:
                      'Stream high-quality adapted preview for smooth gallery playback',
                  value: prefs.isPlaybackOptimized,
                  onChanged: (val) async {
                    await prefs.setPlaybackOptimized(val);
                    setState(() {});
                  },
                ),
              ],
            ),

            // This code for customizable background sync preferences
            _buildSection(
              title: 'BACKGROUND SYNC & AUTOMATION',
              children: [
                _buildSwitchTile(
                  title: 'Wi-Fi Only Sync',
                  subtitle: 'Avoid using cellular mobile data for large uploads',
                  value: prefs.isWifiOnly,
                  onChanged: (val) async {
                    await prefs.setWifiOnly(val);
                    setState(() {});
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Sync While Charging Only',
                  subtitle: 'Conserve battery by syncing when connected to power',
                  value: prefs.isChargeOnly,
                  onChanged: (val) async {
                    await prefs.setChargeOnly(val);
                    setState(() {});
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Instant Sync on Capture',
                  subtitle: 'Queue photos immediately upon camera shutter capture',
                  value: prefs.isInstantSync,
                  onChanged: (val) async {
                    await prefs.setInstantSync(val);
                    setState(() {});
                  },
                ),
                _buildDivider(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Background Schedule',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Periodic sync check frequency',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          showCupertinoModalPopup(
                            context: context,
                            builder: (ctx) => CupertinoActionSheet(
                              title: const Text('Select Sync Frequency'),
                              actions: [
                                for (final freq in [
                                  'hourly',
                                  'daily',
                                  'weekly',
                                  'monthly'
                                ])
                                  CupertinoActionSheetAction(
                                    onPressed: () async {
                                      Navigator.of(ctx).pop();
                                      await prefs.setSyncScheduleFrequency(freq);
                                      setState(() {});
                                    },
                                    child: Text(
                                      freq[0].toUpperCase() + freq.substring(1),
                                      style: TextStyle(
                                        fontWeight:
                                            prefs.syncScheduleFrequency == freq
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          prefs.syncScheduleFrequency[0].toUpperCase() +
                              prefs.syncScheduleFrequency.substring(1),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // This code for storage breakdown and cache cleaner
            _buildSection(
              title: 'STORAGE & DEVICE CLEANER',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Media Items'),
                          Text(
                            '$totalItems items',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Vault Synced Items'),
                          Text(
                            '$syncedItems / $totalItems',
                            style: const TextStyle(
                              color: CupertinoColors.activeBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Storage Size'),
                          Text(
                            '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Local Cache Used'),
                          Text(
                            '${(_cacheSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildDivider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CupertinoButton(
                    color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: _isCleaning ? null : _freeUpSpace,
                    child: Center(
                      child: _isCleaning
                          ? const CupertinoActivityIndicator()
                          : const Text(
                              'Free Up Device Space',
                              style: TextStyle(
                                color: CupertinoColors.activeBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),

            // This code for security and biometric lock settings
            _buildSection(
              title: 'SECURITY & ENCRYPTION',
              children: [
                _buildSwitchTile(
                  title: 'Biometric App Lock',
                  subtitle: 'Require Face ID or Fingerprint to unlock Infinity',
                  value: prefs.isBiometricLockEnabled,
                  onChanged: (val) async {
                    if (val) {
                      final biometric = ref.read(biometricServiceProvider);
                      final didAuth = await biometric.authenticate(
                          reason: 'Confirm biometric security setup');
                      if (!didAuth) return;
                    }
                    await prefs.setBiometricLockEnabled(val);
                    setState(() {});
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'End-to-End Encryption (E2EE)',
                  subtitle:
                      'Encrypt photos with AES-256-GCM before uploading to Telegram',
                  value: prefs.isE2eeEnabled,
                  onChanged: (val) async {
                    await prefs.setE2eeEnabled(val);
                    setState(() {});
                  },
                ),
              ],
            ),

            // This code for manual sync and logout actions
            CupertinoButton.filled(
              onPressed: _isSyncing ? null : _manualSync,
              child: _isSyncing
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('Manual Scan & Sync Now'),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _logOut,
              child: const Text(
                'Log Out from Telegram',
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
