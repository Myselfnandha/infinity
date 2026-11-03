// This code for testing user preference persistence and default values
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppPreferences Tests', () {
    test('Default values follow requirements (no compression, wifi only, daily sync)', () async {
      // This code for verifying clean default settings on fresh install
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPreferences.getInstance();

      expect(prefs.isOnboardingCompleted, isFalse);
      expect(prefs.isUploadCompressionEnabled, isFalse);
      expect(prefs.isDownloadCompressionEnabled, isFalse);
      expect(prefs.isPlaybackOptimized, isTrue);
      expect(prefs.isWifiOnly, isTrue);
      expect(prefs.isChargeOnly, isFalse);
      expect(prefs.syncScheduleFrequency, equals('daily'));
      expect(prefs.isBiometricLockEnabled, isFalse);
    });

    test('Customizable settings update and persist correctly', () async {
      // This code for verifying setting mutations
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPreferences.getInstance();

      await prefs.setOnboardingCompleted(true);
      await prefs.setUploadCompressionEnabled(true);
      await prefs.setDownloadCompressionEnabled(true);
      await prefs.setSyncScheduleFrequency('weekly');
      await prefs.setWifiOnly(false);
      await prefs.setChargeOnly(true);
      await prefs.setBiometricLockEnabled(true);

      expect(prefs.isOnboardingCompleted, isTrue);
      expect(prefs.isUploadCompressionEnabled, isTrue);
      expect(prefs.isDownloadCompressionEnabled, isTrue);
      expect(prefs.syncScheduleFrequency, equals('weekly'));
      expect(prefs.isWifiOnly, isFalse);
      expect(prefs.isChargeOnly, isTrue);
      expect(prefs.isBiometricLockEnabled, isTrue);
    });
  });
}

