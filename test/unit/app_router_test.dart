// This code for testing AppRouter configuration, onboarding guards, and route generation
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/router/app_router.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping AppRouter navigation guard and route matching tests
  group('AppRouter Unit Tests', () {
    test('createAppRouter targets /onboarding when onboarding is not completed', () async {
      // This code for configuring shared preferences with fresh install state
      SharedPreferences.setMockInitialValues({'onboarding_completed': false});
      final prefs = await AppPreferences.getInstance();

      final router = createAppRouter(prefs);
      expect(router.routeInformationProvider.value.uri.path, equals('/onboarding'));
    });

    test('createAppRouter targets / when onboarding is already completed', () async {
      // This code for configuring shared preferences with completed onboarding
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await AppPreferences.getInstance();

      final router = createAppRouter(prefs);
      expect(router.routeInformationProvider.value.uri.path, equals('/'));
    });

    test('router includes registered configuration routes for all features', () async {
      // This code for verifying all application routes are registered
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await AppPreferences.getInstance();

      final router = createAppRouter(prefs);
      final routes = router.configuration.routes.map((r) => (r as dynamic).path).toList();

      expect(routes, contains('/'));
      expect(routes, contains('/onboarding'));
      expect(routes, contains('/auth'));
      expect(routes, contains('/trash'));
      expect(routes, contains('/search'));
      expect(routes, contains('/files'));
      expect(routes, contains('/album-detail'));
    });
  });
}
