// This code for managing biometric authentication and AES-256 client-side encryption settings
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';

// This code for rendering security and privacy settings sub-page
class SecurityPrivacyScreen extends ConsumerStatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  ConsumerState<SecurityPrivacyScreen> createState() =>
      _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends ConsumerState<SecurityPrivacyScreen> {
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
        middle: Text('Security & Privacy'),
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
                    title: 'Biometric App Lock',
                    subtitle: 'Require Face ID or Fingerprint to open Infinity',
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
                    title: 'Client-Side Encryption (E2EE)',
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
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'When Client-Side Encryption is enabled, media files are encrypted with Argon2id + AES-256-GCM using your master password. Telegram servers never receive unencrypted content.',
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
