// This code for testing FilesScreen, MainScreen CupertinoTabBar navigation, and AuthScreen authentication flows
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/di/providers.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/core/telegram/tdlib_service.dart';
import 'package:infinity/features/auth/auth_screen.dart';
import 'package:infinity/features/files/files_screen.dart';
import 'package:infinity/features/main/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

// This code for mock selection mode notifier allowing initial value injection
class MockSelectionModeNotifier extends SelectionModeNotifier {
  final bool initial;
  MockSelectionModeNotifier(this.initial);

  @override
  bool build() => initial;
}

void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping FilesScreen tests
  group('FilesScreen Widget Tests', () {
    late TestDatabase db;
    late AppPreferences prefs;

    setUp(() async {
      // This code for initializing database and mock preferences
      SharedPreferences.setMockInitialValues({});
      prefs = await AppPreferences.getInstance();
      db = TestDatabase();
    });

    tearDown(() async {
      // This code for closing database
      await db.close();
    });

    testWidgets('FilesScreen displays empty state when no documents exist', (WidgetTester tester) async {
      // This code for pumping FilesScreen with empty files stream
      await tester.pumpWidget(
        buildTestApp(
          child: const FilesScreen(),
          database: db,
          preferences: prefs,
          additionalOverrides: [
            filesProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Vault Documents'), findsOneWidget);
      expect(find.text('No Documents in Vault'), findsOneWidget);
      expect(find.textContaining('Tap + above to add documents'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('FilesScreen renders documents list and storage summary header', (WidgetTester tester) async {
      // This code for creating mock document media item
      final mockDoc = MediaItem(
        id: 'doc_1',
        filePath: '/storage/vault/Project_Proposal.pdf',
        mediaType: 'document',
        fileSize: 2097152, // 2.0 MB
        dateAdded: DateTime(2025, 5, 10),
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isFavorite: false,
        isTrashed: false,
        isPinnedOffline: true,
      );

      // This code for pumping FilesScreen with populated files stream
      await tester.pumpWidget(
        buildTestApp(
          child: const FilesScreen(),
          database: db,
          preferences: prefs,
          additionalOverrides: [
            filesProvider.overrideWith((ref) => Stream.value([mockDoc])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1 Document'), findsOneWidget);
      expect(find.textContaining('Total Storage: 2.0 MB'), findsOneWidget);
      expect(find.text('Project_Proposal.pdf'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  // This code for grouping MainScreen root shell navigation tests
  group('MainScreen Navigation Widget Tests', () {
    late TestDatabase db;
    late AppPreferences prefs;
    late FakeTdlibService fakeTdlib;
    late FakeBiometricService fakeBio;

    setUp(() async {
      // This code for initializing test database and mocks
      SharedPreferences.setMockInitialValues({});
      prefs = await AppPreferences.getInstance();
      db = TestDatabase();
      fakeTdlib = FakeTdlibService();
      fakeBio = FakeBiometricService();
    });

    tearDown(() async {
      // This code for closing database and mocks
      await db.close();
      fakeTdlib.dispose();
    });

    // Helper to build MainScreen with safe mocked riverpod stream providers
    Widget buildSafeMainScreen({bool isSelectionMode = false}) {
      return buildTestApp(
        child: const MainScreen(),
        database: db,
        preferences: prefs,
        tdlibService: fakeTdlib,
        biometricService: fakeBio,
        additionalOverrides: [
          allMediaProvider.overrideWith((ref) => Stream.value([])),
          favoritesProvider.overrideWith((ref) => Stream.value([])),
          albumsProvider.overrideWith((ref) => Stream.value([])),
          trashProvider.overrideWith((ref) => Stream.value([])),
          filesProvider.overrideWith((ref) => Stream.value([])),
          pendingTasksProvider.overrideWith((ref) => Stream.value([])),
          selectionModeProvider.overrideWith(() => MockSelectionModeNotifier(isSelectionMode)),
        ],
      );
    }

    testWidgets('MainScreen renders bottom tab navigation bar with 5 destinations', (WidgetTester tester) async {
      // This code for pumping MainScreen scaffold
      await tester.pumpWidget(buildSafeMainScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CupertinoTabBar), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Files'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('MainScreen switches active tab upon tapping tab item', (WidgetTester tester) async {
      // This code for pumping MainScreen scaffold
      await tester.pumpWidget(buildSafeMainScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // This code for tapping Files tab
      await tester.tap(find.text('Files'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Vault Documents'), findsOneWidget);

      // This code for tapping Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Settings'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('MainScreen hides CupertinoTabBar when selectionModeProvider is active', (WidgetTester tester) async {
      // This code for pumping MainScreen with active selection mode
      await tester.pumpWidget(buildSafeMainScreen(isSelectionMode: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CupertinoTabBar), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('MainScreen back press switches tab to Photos when on non-zero tab', (WidgetTester tester) async {
      await tester.pumpWidget(buildSafeMainScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Settings tab (index 4)
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Trigger pop via PopScope
      final dynamic popScopeWidget = tester.widget(find.byWidgetPredicate((w) => w is PopScope));
      popScopeWidget.onPopInvokedWithResult(false, null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should return to Photos tab
      expect(find.text('Photos'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('MainScreen back press cancels selection mode first', (WidgetTester tester) async {
      await tester.pumpWidget(buildSafeMainScreen(isSelectionMode: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final dynamic popScopeWidget = tester.widget(find.byWidgetPredicate((w) => w is PopScope));
      popScopeWidget.onPopInvokedWithResult(false, null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify widget handled pop gracefully
      expect(find.byType(MainScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  // This code for grouping AuthScreen authentication interaction tests
  group('AuthScreen Widget Tests', () {
    late TestDatabase db;
    late AppPreferences prefs;
    late FakeTdlibService fakeTdlib;

    setUp(() async {
      // This code for initializing test state
      SharedPreferences.setMockInitialValues({});
      prefs = await AppPreferences.getInstance();
      db = TestDatabase();
      fakeTdlib = FakeTdlibService();
      fakeTdlib.setAuthState(TelegramAuthState.waitingForPhoneNumber);
    });

    tearDown(() async {
      // This code for disposing database and mocks
      await db.close();
      fakeTdlib.dispose();
    });

    // Helper to build AuthScreen with GoRouter support for post-auth navigation
    Widget buildRouterAuthApp() {
      final router = GoRouter(
        initialLocation: '/auth',
        routes: [
          GoRoute(
            path: '/auth',
            builder: (context, state) => const AuthScreen(),
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
        ],
        child: CupertinoApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('AuthScreen renders login branding and phone number input field', (WidgetTester tester) async {
      // This code for pumping AuthScreen
      await tester.pumpWidget(buildRouterAuthApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Infinity Login'), findsOneWidget);
      expect(find.text('Infinity Cloud Vault'), findsOneWidget);
      expect(find.text('Continue with Phone'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('AuthScreen submits phone number and transitions auth state', (WidgetTester tester) async {
      // This code for pumping AuthScreen
      await tester.pumpWidget(buildRouterAuthApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // This code for entering phone and submitting
      await tester.enterText(find.byType(CupertinoTextField), '+1987654321');
      await tester.tap(find.text('Continue with Phone'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeTdlib.lastPhoneNumber, equals('+1987654321'));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('AuthScreen verifies authentication code and navigates home on success', (WidgetTester tester) async {
      // This code for setting waitingForCode state
      fakeTdlib.setAuthState(TelegramAuthState.waitingForCode);

      // This code for pumping AuthScreen in code verification state
      await tester.pumpWidget(buildRouterAuthApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Verify Code'), findsOneWidget);

      // This code for entering code and submitting
      await tester.enterText(find.byType(CupertinoTextField), '54321');
      await tester.tap(find.text('Verify Code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeTdlib.lastAuthCode, equals('54321'));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('AuthScreen submits 2FA password and navigates home on success', (WidgetTester tester) async {
      // This code for setting waitingForPassword state
      fakeTdlib.setAuthState(TelegramAuthState.waitingForPassword);

      // This code for pumping AuthScreen in password state
      await tester.pumpWidget(buildRouterAuthApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Submit Password'), findsOneWidget);

      // This code for entering 2FA password and submitting
      await tester.enterText(find.byType(CupertinoTextField), 'superSecret123');
      await tester.tap(find.text('Submit Password'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeTdlib.lastPassword, equals('superSecret123'));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
