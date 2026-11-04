// This code for managing Telegram Vault supergroup account status and connection details
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';

// This code for rendering the Telegram Vault account details sub-page
class VaultAccountScreen extends ConsumerWidget {
  const VaultAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdlib = ref.watch(tdlibServiceProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        previousPageTitle: 'Settings',
        middle: Text('Vault Account'),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Vault Supergroup Status'),
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
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Telegram Chat ID'),
                        Text(
                          tdlib.vaultChatId?.toString() ?? 'Auto-detecting',
                          style: const TextStyle(color: CupertinoColors.secondaryLabel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Connected Account'),
                        Text(
                          tdlib.authPhoneNumber ?? 'Active Session',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Forum Topics Mode'),
                        Text(
                          tdlib.vaultChatId != null ? 'Active' : 'Standby',
                          style: const TextStyle(
                            color: CupertinoColors.activeBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Infinity uses a private Telegram supergroup with forum topics as your personal unlimited cloud vault. Photos and videos are stored across organized topics.',
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
