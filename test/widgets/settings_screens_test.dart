// This code for widget testing SettingsScreen, VaultAccountScreen, MediaQualityScreen, SecurityPrivacyScreen, StorageCleanerScreen, and SyncAutomationScreen
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/core/telegram/tdlib_service.dart';
import 'package:infinity/features/settings/media_quality_screen.dart';
import 'package:infinity/features/settings/security_privacy_screen.dart';
import 'package:infinity/features/settings/settings_screen.dart';
import 'package:infinity/features/settings/storage_cleaner_screen.dart';
import 'package:infinity/features/settings/sync_automation_screen.dart';
import 'package:infinity/features/settings/vault_account_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.dart';

void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping settings feature screens widget tests
  group('Settings Screens Widget Tests', () {
    late TestDatabase db;
    late AppPreferences prefs;
    late FakeTdlibService fakeTdlib;
    late FakeBiometricService fakeBiometric;

    setUp(() async {
      // This code for preparing mock preferences, database, and services before each test
      SharedPreferences.setMockInitialValues({});
      prefs = await AppPreferences.getInstance();
      db = TestDatabase();
      fakeTdlib = FakeTdlibService();
      fakeBiometric = FakeBiometricService();
    });

    tearDown(() async {
      // This code for closing database resources after each test run
      await db.close();
    });

    testWidgets('SettingsScreen renders all category folders and sync action button', (WidgetTester tester) async {
      // This code for pumping SettingsScreen into tester
      await tester.pumpWidget(
        buildTestApp(
          child: const SettingsScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert header and category folders
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Vault Account'), findsOneWidget);
      expect(find.text('Media & Quality'), findsOneWidget);
      expect(find.text('Background Sync'), findsOneWidget);
      expect(find.text('Storage & Cleaner'), findsOneWidget);
      expect(find.text('Security & Privacy'), findsOneWidget);
      expect(find.text('Manual Scan & Sync Now'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('MediaQualityScreen toggles compression and playback options', (WidgetTester tester) async {
      // This code for pumping MediaQualityScreen
      await tester.pumpWidget(
        buildTestApp(
          child: const MediaQualityScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert switch titles
      expect(find.text('Media & Quality'), findsOneWidget);
      expect(find.text('Upload Compression'), findsOneWidget);
      expect(find.text('Download Compression'), findsOneWidget);
      expect(find.text('Optimized Playback'), findsOneWidget);

      // Toggle upload compression switch
      final switches = find.byType(CupertinoSwitch);
      expect(switches, findsNWidgets(3));
      await tester.tap(switches.first);
      await tester.pump();

      expect(prefs.isUploadCompressionEnabled, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('SecurityPrivacyScreen toggles biometric app lock and E2EE', (WidgetTester tester) async {
      // This code for pumping SecurityPrivacyScreen
      await tester.pumpWidget(
        buildTestApp(
          child: const SecurityPrivacyScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
          biometricService: fakeBiometric,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Security & Privacy'), findsOneWidget);
      expect(find.text('Biometric App Lock'), findsOneWidget);
      expect(find.text('Client-Side Encryption (E2EE)'), findsOneWidget);

      // Toggle E2EE switch
      final switches = find.byType(CupertinoSwitch);
      await tester.tap(switches.last);
      await tester.pump();

      expect(prefs.isE2eeEnabled, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('StorageCleanerScreen displays media item stats and cleaner button', (WidgetTester tester) async {
      // This code for pumping StorageCleanerScreen
      await tester.pumpWidget(
        buildTestApp(
          child: const StorageCleanerScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Storage & Cleaner'), findsOneWidget);
      expect(find.text('Total Media Items'), findsOneWidget);
      expect(find.text('Vault Synced Items'), findsOneWidget);
      expect(find.text('Free Up Device Space'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('SyncAutomationScreen toggles Wi-Fi, battery charging, and instant sync', (WidgetTester tester) async {
      // This code for pumping SyncAutomationScreen
      await tester.pumpWidget(
        buildTestApp(
          child: const SyncAutomationScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Background Sync'), findsOneWidget);
      expect(find.text('Wi-Fi Only Sync'), findsOneWidget);
      expect(find.text('Sync While Charging Only'), findsOneWidget);
      expect(find.text('Instant Sync on Capture'), findsOneWidget);

      final switches = find.byType(CupertinoSwitch);
      await tester.tap(switches.at(0));
      await tester.pump();

      expect(prefs.isWifiOnly, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('VaultAccountScreen renders authentication controls and custom API fields', (WidgetTester tester) async {
      // This code for setting auth state to waiting for phone number and resetting vault chat id
      fakeTdlib.mockVaultChatId = null;
      fakeTdlib.setAuthState(TelegramAuthState.waitingForPhoneNumber);

      // This code for pumping VaultAccountScreen
      await tester.pumpWidget(
        buildTestApp(
          child: const VaultAccountScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Vault Account'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);
      expect(find.text('Custom Telegram API Credentials (Optional)'), findsOneWidget);

      // This code for tapping custom API credentials toggle to expand configuration inputs
      await tester.tap(find.text('Custom Telegram API Credentials (Optional)'));
      await tester.pump();

      expect(find.text('Telegram Android (6)'), findsOneWidget);
      expect(find.text('Workspace API (30662321)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // This code for testing VaultAccountScreen connected state and disconnect action sheet
    testWidgets('VaultAccountScreen renders connected vault status and handles disconnect confirmation', (WidgetTester tester) async {
      // This code for setting ready state with active vault chat id
      fakeTdlib.mockVaultChatId = -100123456789;
      fakeTdlib.setAuthState(TelegramAuthState.ready);

      // This code for pumping VaultAccountScreen
      await tester.pumpWidget(
        buildTestApp(
          child: const VaultAccountScreen(),
          database: db,
          preferences: prefs,
          tdlibService: fakeTdlib,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Vault Account'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('-100123456789'), findsOneWidget);
      expect(find.text('Active (5 Topics)'), findsOneWidget);

      // Tap Disconnect Vault button
      final disconnectButton = find.text('Disconnect Vault');
      expect(disconnectButton, findsOneWidget);
      await tester.tap(disconnectButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Assert confirmation sheet appears
      expect(find.text('Disconnect Telegram Vault?'), findsOneWidget);

      // Tap Disconnect Vault action inside sheet
      await tester.tap(find.widgetWithText(CupertinoActionSheetAction, 'Disconnect Vault'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeTdlib.currentAuthState, equals(TelegramAuthState.uninitialized));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
