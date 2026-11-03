import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return Future.value(true);
  });
}

class BackgroundController {
  static void initForegroundTask() {
    if (Platform.isAndroid) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'infinity_sync_channel',
          channelName: 'Infinity Vault Sync',
          channelDescription: 'Ongoing background backup to Telegram Vault',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          autoRunOnBoot: false,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
    }
  }

  // This code for initializing the background WorkManager background job scheduler
  static Future<void> initWorkManager() async {
    if (Platform.isAndroid) {
      await Workmanager().initialize(
        callbackDispatcher,
      );
    }
  }

  static Future<void> schedulePeriodicSync({int intervalHours = 6}) async {
    if (Platform.isAndroid) {
      await Workmanager().registerPeriodicTask(
        'infinity_periodic_sync',
        'syncDeviceMedia',
        frequency: Duration(hours: intervalHours),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );
    }
  }

  static Future<void> cancelScheduledSync() async {
    if (Platform.isAndroid) {
      await Workmanager().cancelByUniqueName('infinity_periodic_sync');
    }
  }
}
