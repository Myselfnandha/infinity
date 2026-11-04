// This code for configuring background synchronization and battery automation preferences
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';

// This code for rendering background sync and automation settings sub-page
class SyncAutomationScreen extends ConsumerStatefulWidget {
  const SyncAutomationScreen({super.key});

  @override
  ConsumerState<SyncAutomationScreen> createState() =>
      _SyncAutomationScreenState();
}

class _SyncAutomationScreenState extends ConsumerState<SyncAutomationScreen> {
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
        middle: Text('Background Sync'),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                                        await prefs
                                            .setSyncScheduleFrequency(freq);
                                        setState(() {});
                                      },
                                      child: Text(
                                        freq[0].toUpperCase() +
                                            freq.substring(1),
                                        style: TextStyle(
                                          fontWeight:
                                              prefs.syncScheduleFrequency ==
                                                      freq
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
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Background sync uses Android WorkManager to wake up and process pending items even when the application is closed.',
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
