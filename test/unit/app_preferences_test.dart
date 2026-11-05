// This code for testing user preference persistence, default values, and Telegram API credentials management
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This code for executing AppPreferences unit tests
void main() {
  // This code for grouping AppPreferences unit test scenarios
  group('AppPreferences Tests', () {
    // This code for verifying clean default settings on fresh install
    test('Default values follow requirements (no compression, wifi only, daily sync)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPreferences.getInstance();

      expect(prefs.isOnboardingCompleted, isFalse);
      expect(prefs.isUploadCompressionEnabled, isFalse);
      expect(prefs.isDownloadCompressionEnabled, isFalse);
      expect(prefs.isPlaybackOptimized, isTrue);
      expect(prefs.isWifiOnly, isTrue);
      expect(prefs.isChargeOnly, isFalse);
      expect(prefs.isInstantSync, isTrue);
      expect(prefs.syncIntervalHours, equals(6));
      expect(prefs.cacheLimitMb, equals(2048));
      expect(prefs.syncScheduleFrequency, equals('daily'));
      expect(prefs.isBiometricLockEnabled, isFalse);
      expect(prefs.isDeveloperMode, isFalse);
      expect(prefs.isE2eeEnabled, isFalse);
      expect(prefs.backupFolderIds, equals(['camera', 'screenshots', 'videos']));
      expect(prefs.telegramApiId, isNull);
      expect(prefs.telegramApiHash, isNull);
    });

    // This code for verifying setting mutations across all preferences
    test('Customizable settings update and persist correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPreferences.getInstance();

      await prefs.setOnboardingCompleted(true);
      await prefs.setUploadCompressionEnabled(true);
      await prefs.setDownloadCompressionEnabled(true);
      await prefs.setPlaybackOptimized(false);
      await prefs.setSyncScheduleFrequency('weekly');
      await prefs.setWifiOnly(false);
      await prefs.setChargeOnly(true);
      await prefs.setInstantSync(false);
      await prefs.setSyncIntervalHours(12);
      await prefs.setCacheLimitMb(4096);
      await prefs.setBiometricLockEnabled(true);
      await prefs.setDeveloperMode(true);
      await prefs.setE2eeEnabled(true);
      await prefs.setBackupFolderIds(['camera', 'custom_album']);

      expect(prefs.isOnboardingCompleted, isTrue);
      expect(prefs.isUploadCompressionEnabled, isTrue);
      expect(prefs.isDownloadCompressionEnabled, isTrue);
      expect(prefs.isPlaybackOptimized, isFalse);
      expect(prefs.syncScheduleFrequency, equals('weekly'));
      expect(prefs.isWifiOnly, isFalse);
      expect(prefs.isChargeOnly, isTrue);
      expect(prefs.isInstantSync, isFalse);
      expect(prefs.syncIntervalHours, equals(12));
      expect(prefs.cacheLimitMb, equals(4096));
      expect(prefs.isBiometricLockEnabled, isTrue);
      expect(prefs.isDeveloperMode, isTrue);
      expect(prefs.isE2eeEnabled, isTrue);
      expect(prefs.backupFolderIds, equals(['camera', 'custom_album']));
    });

    // This code for verifying Telegram API ID and Hash persistence and null clearing
    test('Telegram API ID and Hash set and remove correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPreferences.getInstance();

      await prefs.setTelegramApiId(30662321);
      await prefs.setTelegramApiHash('cf007e0155c41fd1aa9b114b592377e0');

      expect(prefs.telegramApiId, equals(30662321));
      expect(prefs.telegramApiHash, equals('cf007e0155c41fd1aa9b114b592377e0'));

      // This code for testing clearing credentials with null
      await prefs.setTelegramApiId(null);
      await prefs.setTelegramApiHash(null);

      expect(prefs.telegramApiId, isNull);
      expect(prefs.telegramApiHash, isNull);
    });

    // This code for verifying Telegram Vault Chat ID, Title, and Topics mapping persistence
    test('Vault Chat ID, Title, and Topics map set and restore correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPreferences.getInstance();

      expect(prefs.vaultChatId, isNull);
      expect(prefs.vaultChatTitle, isNull);
      expect(prefs.vaultTopics, isEmpty);

      await prefs.setVaultChatId(-1001987654321);
      await prefs.setVaultChatTitle('Infinity Super Vault');
      await prefs.setVaultTopics({'Photos': 2, 'Videos': 4, 'Documents': 6});

      expect(prefs.vaultChatId, equals(-1001987654321));
      expect(prefs.vaultChatTitle, equals('Infinity Super Vault'));
      expect(prefs.vaultTopics, equals({'Photos': 2, 'Videos': 4, 'Documents': 6}));

      // Test clearing vault chat id and title with null
      await prefs.setVaultChatId(null);
      await prefs.setVaultChatTitle(null);
      await prefs.setVaultTopics({});

      expect(prefs.vaultChatId, isNull);
      expect(prefs.vaultChatTitle, isNull);
      expect(prefs.vaultTopics, isEmpty);
    });
  });
}
