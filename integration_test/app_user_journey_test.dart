// This code for executing full end-to-end user journey integration tests on device
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/di/providers.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/features/backup/backup_telemetry_sheet.dart';
import 'package:infinity/features/backup/widgets/m3e_wavy_progress_indicator.dart';
import 'package:infinity/main.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Infinity End-to-End User Journey Tests', () {
    testWidgets('Full User Journey: Tab navigation, gallery timeline, and telemetry modal hub',
        (WidgetTester tester) async {
      // Configure test preferences with completed onboarding
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
        'vault_chat_id': -1001234567890,
        'vault_chat_title': 'Infinity Vault',
      });
      final prefs = await AppPreferences.getInstance();

      // Launch application under ProviderScope
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
          ],
          child: const InfinityApp(),
        ),
      );

      // Settle initial route and widget building with discrete pumps
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // 1. Verify primary Cupertino tab bar destinations are present
      expect(find.byType(CupertinoTabBar), findsOneWidget);
      expect(find.descendant(of: find.byType(CupertinoTabBar), matching: find.text('Photos')), findsOneWidget);
      expect(find.descendant(of: find.byType(CupertinoTabBar), matching: find.text('Albums')), findsOneWidget);
      expect(find.descendant(of: find.byType(CupertinoTabBar), matching: find.text('Search')), findsOneWidget);
      expect(find.descendant(of: find.byType(CupertinoTabBar), matching: find.text('Files')), findsOneWidget);
      expect(find.descendant(of: find.byType(CupertinoTabBar), matching: find.text('Settings')), findsOneWidget);

      // 2. Navigate through destination tabs via the CupertinoTabBar
      await tester.tap(find.descendant(of: find.byType(CupertinoTabBar), matching: find.text('Albums')));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.descendant(of: find.byType(CupertinoTabBar), matching: find.text('Search')));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.descendant(of: find.byType(CupertinoTabBar), matching: find.text('Files')));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.descendant(of: find.byType(CupertinoTabBar), matching: find.text('Settings')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Settings'), findsWidgets);

      // 3. Return to Photos tab
      await tester.tap(find.descendant(of: find.byType(CupertinoTabBar), matching: find.text('Photos')));
      await tester.pump(const Duration(milliseconds: 400));

      // 4. Open Backup Telemetry Sheet via timeline app bar interaction
      await tester.tap(find.text('Infinity Photos'));
      await tester.pump(const Duration(milliseconds: 600));

      // Verify Telemetry Sheet components
      expect(find.byType(BackupTelemetrySheet), findsOneWidget);
      expect(find.text('Uploads & Telemetry'), findsOneWidget);
      expect(find.text('Monitored Backup Folders'), findsOneWidget);

      // 5. Test Pause / Resume action inside sheet
      final pauseButton = find.text('Pause');
      if (pauseButton.evaluate().isNotEmpty) {
        await tester.tap(pauseButton);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Resume'), findsOneWidget);

        await tester.tap(find.text('Resume'));
        await tester.pump(const Duration(milliseconds: 300));
      }

      // 6. Dismiss modal sheet by tapping close icon
      final closeButton = find.byIcon(Icons.close_rounded);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(BackupTelemetrySheet), findsNothing);
      }

      // 7. Gracefully pause sync before teardown
      final container = ProviderScope.containerOf(tester.element(find.byType(InfinityApp)));
      container.read(syncEngineProvider).pauseSync();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('M3EWavyProgressIndicator component renders smoothly in isolate',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: M3EWavyProgressIndicator(
                  progress: 0.65,
                  color: Color(0xFF00E5FF),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(M3EWavyProgressIndicator), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
