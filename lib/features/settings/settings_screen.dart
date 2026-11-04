// This code for root application settings screen organizing configurations into modular category folders
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/storage/gallery_service.dart';
import 'media_quality_screen.dart';
import 'security_privacy_screen.dart';
import 'storage_cleaner_screen.dart';
import 'sync_automation_screen.dart';
import 'vault_account_screen.dart';

// This code for rendering the main modular settings directory
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;

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

  // This code for logging out of the Telegram account
  Future<void> _logOut() async {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Log Out from Telegram?'),
        message: const Text(
            'Disconnects this device from your Infinity Vault supergroup.'),
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

  // This code for building folder category list tile
  Widget _buildCategoryTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      child: CupertinoListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        trailing: const CupertinoListTileChevron(),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This code for watching active Telegram vault supergroup connection status
    final tdlib = ref.watch(tdlibServiceProvider);
    final isVaultConnected = tdlib.vaultChatId != null;

    return CupertinoPageScaffold(
      // This code for clean iOS settings navigation title
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // This code for section header of modular category folders
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'PREFERENCES & SYSTEM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
            // This code for Vault & Telegram Account category folder with dynamic connection status
            _buildCategoryTile(
              icon: CupertinoIcons.infinite,
              iconColor: isVaultConnected
                  ? CupertinoColors.activeGreen
                  : CupertinoColors.activeBlue,
              title: 'Vault Account',
              subtitle: isVaultConnected
                  ? 'Connected • Infinity Vault Supergroup'
                  : 'Action Required • Connect Telegram Vault',
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => const VaultAccountScreen(),
                  ),
                );
              },
            ),
            // This code for Media Quality & Compression category folder
            _buildCategoryTile(
              icon: CupertinoIcons.slider_horizontal_3,
              iconColor: CupertinoColors.systemPurple,
              title: 'Media & Quality',
              subtitle: 'Lossless upload, compression & playback',
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => const MediaQualityScreen(),
                  ),
                );
              },
            ),
            // This code for Background Sync & Automation category folder
            _buildCategoryTile(
              icon: CupertinoIcons.arrow_2_circlepath,
              iconColor: CupertinoColors.systemGreen,
              title: 'Background Sync',
              subtitle: 'Wi-Fi, charging only & sync schedules',
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => const SyncAutomationScreen(),
                  ),
                );
              },
            ),
            // This code for Storage & Device Cleaner category folder
            _buildCategoryTile(
              icon: CupertinoIcons.archivebox,
              iconColor: CupertinoColors.systemOrange,
              title: 'Storage & Cleaner',
              subtitle: 'Cache breakdown & device space cleaner',
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => const StorageCleanerScreen(),
                  ),
                );
              },
            ),
            // This code for Security & Privacy category folder
            _buildCategoryTile(
              icon: CupertinoIcons.lock_shield,
              iconColor: CupertinoColors.systemIndigo,
              title: 'Security & Privacy',
              subtitle: 'Biometric App Lock & AES-256 encryption',
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => const SecurityPrivacyScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // This code for manual device scan and cloud sync trigger
            CupertinoButton.filled(
              onPressed: _isSyncing ? null : _manualSync,
              child: _isSyncing
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                  : const Text('Manual Scan & Sync Now'),
            ),
            const SizedBox(height: 14),
            // This code for adaptive Telegram connect or logout action depending on active session
            if (isVaultConnected)
              CupertinoButton(
                onPressed: _logOut,
                child: const Text(
                  'Log Out from Telegram',
                  style: TextStyle(color: CupertinoColors.destructiveRed),
                ),
              )
            else
              CupertinoButton(
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const VaultAccountScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Connect Telegram Vault',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            // This code for providing bottom padding ensuring content clears the translucent Cupertino tab bar
            const SizedBox(height: 84),
          ],
        ),
      ),
    );
  }
}
