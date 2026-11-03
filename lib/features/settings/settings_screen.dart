import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/storage/gallery_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;

  Future<void> _manualSync() async {
    setState(() => _isSyncing = true);
    try {
      final db = ref.read(databaseProvider);
      final gallery = GalleryService(db);
      await gallery.scanDeviceMedia(limit: 500);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _logOut() async {
    final tdlib = ref.read(tdlibServiceProvider);
    await tdlib.logOut();
    if (mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tdlib = ref.watch(tdlibServiceProvider);
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INFINITY CLOUD VAULT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Supergroup Status'),
                      Text(
                        tdlib.vaultChatId != null ? 'Connected' : 'Connecting...',
                        style: TextStyle(
                          color: tdlib.vaultChatId != null
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.systemOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Telegram Supergroup ID'),
                      Text(
                        tdlib.vaultChatId?.toString() ?? 'Auto-detecting',
                        style: const TextStyle(
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Connected Account'),
                      Text(
                        tdlib.authPhoneNumber ?? 'Active Session',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STORAGE BREAKDOWN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Backed Up to Telegram'),
                      Text(
                        '$syncedItems / $totalItems',
                        style: const TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _isSyncing ? null : _manualSync,
              child: _isSyncing
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('Sync Now'),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _logOut,
              child: const Text(
                'Log Out from Telegram',
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
