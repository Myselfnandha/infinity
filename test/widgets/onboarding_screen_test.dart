// This code for testing OnboardingScreen flows, slides navigation, auth interactions, and preference persistence
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:infinity/core/di/providers.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/core/telegram/tdlib_service.dart';
import 'package:infinity/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping OnboardingScreen widget interaction tests
  group('OnboardingScreen Widget Tests', () {
    late TestDatabase db;
    late AppPreferences prefs;
    late FakeTdlibService fakeTdlib;
    late FakeBiometricService fakeBio;

    setUp(() async {
      // This code for resetting mocks and test database before each test
      SharedPreferences.setMockInitialValues({'onboarding_completed': false});
      prefs = await AppPreferences.getInstance();
      db = TestDatabase();
      fakeTdlib = FakeTdlibService();
      fakeBio = FakeBiometricService();
      fakeTdlib.setAuthState(TelegramAuthState.waitingForPhoneNumber);
    });

    tearDown(() async {
      // This code for disposing database and mocks
      await db.close();
      fakeTdlib.dispose();
    });

    // Helper to create router-backed app for onboarding navigation
    Widget buildRouterTestApp({Widget? child}) {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => child ?? const OnboardingScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Text('Main Timeline Home'),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          preferencesProvider.overrideWithValue(prefs),
          tdlibServiceProvider.overrideWithValue(fakeTdlib),
          biometricServiceProvider.overrideWithValue(fakeBio),
        ],
        child: CupertinoApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('OnboardingScreen renders initial Welcome slide and navigates forward on Get Started tap', (WidgetTester tester) async {
      // This code for pumping OnboardingScreen with router
      await tester.pumpWidget(buildRouterTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Welcome (1/7)'), findsOneWidget);
      expect(find.text('Welcome to Infinity'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // This code for tapping Get Started button to navigate to auth slide
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome (2/7)'), findsOneWidget);
      expect(find.text('Telegram Connection'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('OnboardingScreen submits phone number and handles custom API toggle', (WidgetTester tester) async {
      // This code for pumping OnboardingScreen
      await tester.pumpWidget(buildRouterTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Advance to auth slide
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // This code for testing custom Telegram API credentials expansion before submitting phone
      expect(find.text('Custom Telegram API (Optional)'), findsOneWidget);
      await tester.tap(find.text('Custom Telegram API (Optional)'));
      await tester.pump();

      expect(find.text('Telegram Android (6)'), findsOneWidget);
      expect(find.text('Workspace API (30662321)'), findsOneWidget);

      // This code for entering phone number and triggering submit
      await tester.enterText(find.byType(CupertinoTextField).first, '+1234567890');
      await tester.tap(find.text('Send Verification Code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeTdlib.lastPhoneNumber, equals('+1234567890'));
      expect(find.text('Verify Code'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('OnboardingScreen advances through permission and folder selection slides', (WidgetTester tester) async {
      // This code for pumping OnboardingScreen
      await tester.pumpWidget(buildRouterTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1: Welcome -> Auth
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // 2: Auth -> Media Permissions
      await tester.tap(find.text('Configure Later'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome (3/7)'), findsOneWidget);
      expect(find.text('Photo & Video Access'), findsOneWidget);

      // 3: Media Permissions -> Notification Permissions
      await tester.tap(find.text('Skip for Now'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome (4/7)'), findsOneWidget);
      expect(find.text('Background Sync Alerts'), findsOneWidget);

      // 4: Notification Permissions -> Folder Selection
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome (5/7)'), findsOneWidget);
      expect(find.text('Select Backup Folders'), findsOneWidget);
      expect(find.text('Camera Roll'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Screenshots'), findsOneWidget);

      // 5: Folder Selection -> Sync Preferences
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome (6/7)'), findsOneWidget);
      expect(find.text('Sync Preferences'), findsOneWidget);
      expect(find.text('Upload Over Wi-Fi Only'), findsOneWidget);

      // 6: Sync Preferences -> Security Page
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome (7/7)'), findsOneWidget);
      expect(find.text('Security & App Lock'), findsOneWidget);
      expect(find.text('Complete Setup'), findsOneWidget);

      // This code for tapping Complete Setup and verifying preference storage
      await tester.tap(find.text('Complete Setup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(prefs.isOnboardingCompleted, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
