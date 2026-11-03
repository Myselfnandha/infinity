// This code for declarative application routing and onboarding authentication guards using GoRouter
import 'package:go_router/go_router.dart';
import '../../features/albums/album_detail_screen.dart';
import '../../features/albums/trash_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/main/main_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../settings/app_preferences.dart';

// This code for constructing the GoRouter instance configured with user onboarding state
GoRouter createAppRouter(AppPreferences prefs) {
  return GoRouter(
    initialLocation: prefs.isOnboardingCompleted ? '/' : '/onboarding',
    redirect: (context, state) {
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isCompleted = prefs.isOnboardingCompleted;

      // This code for enforcing onboarding on first launch
      if (!isCompleted && !isOnboarding) {
        return '/onboarding';
      }

      // This code for redirecting away from onboarding once completed
      if (isCompleted && isOnboarding) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/trash',
        builder: (context, state) => const TrashScreen(),
      ),
      GoRoute(
        path: '/album-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AlbumDetailScreen(
            title: extra['title'] as String? ?? 'Album',
            albumId: extra['albumId'] as String?,
            topicId: extra['topicId'] as int?,
          );
        },
      ),
    ],
  );
}
