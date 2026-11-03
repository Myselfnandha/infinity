// This code for application entry point, lifecycle observation, and biometric authentication gate
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/background/background_controller.dart';
import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/settings/app_preferences.dart';

// This code for initializing application services, background controllers, and shared preferences
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This code for loading user preferences
  final prefs = await AppPreferences.getInstance();

  // This code for initializing background tasks on Android platform
  if (!kIsWeb && Platform.isAndroid) {
    BackgroundController.initForegroundTask();
    await BackgroundController.initWorkManager();
  }

  runApp(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
      ],
      child: const InfinityApp(),
    ),
  );
}

// This code for root application widget with Cupertino iOS-style design and biometric gate
class InfinityApp extends ConsumerStatefulWidget {
  const InfinityApp({super.key});

  @override
  ConsumerState<InfinityApp> createState() => _InfinityAppState();
}

class _InfinityAppState extends ConsumerState<InfinityApp>
    with WidgetsBindingObserver {
  GoRouter? _router;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This code for initializing TDLib client engine
      ref.read(tdlibServiceProvider).initialize();

      // This code for verifying biometric unlock on fresh application launch if enabled
      final prefs = ref.read(preferencesProvider);
      if (prefs.isBiometricLockEnabled) {
        setState(() => _isLocked = true);
        _promptBiometricUnlock();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // This code for observing app lifecycle transitions to lock vault when resuming from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final prefs = ref.read(preferencesProvider);
      if (prefs.isBiometricLockEnabled) {
        setState(() => _isLocked = true);
        _promptBiometricUnlock();
      }
    }
  }

  // This code for prompting user biometric authentication to unlock the app
  Future<void> _promptBiometricUnlock() async {
    final biometric = ref.read(biometricServiceProvider);
    final authenticated = await biometric.authenticate(
      reason: 'Unlock Infinity Photo Vault',
    );
    if (authenticated && mounted) {
      setState(() => _isLocked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    _router ??= createAppRouter(prefs);

    return CupertinoApp.router(
      title: 'Infinity',
      debugShowCheckedModeBanner: false,
      routerConfig: _router!,
      // This code for applying system-adaptive Cupertino theme matching host device light/dark mode
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
      ),
      builder: (context, child) {
        // This code for rendering biometric security lock overlay screen
        if (_isLocked) {
          return CupertinoPageScaffold(
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.lock_shield_fill,
                        size: 80,
                        color: CupertinoColors.activeBlue,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Infinity Vault Locked',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Biometric authentication is required to access your photos and videos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 36),
                      CupertinoButton.filled(
                        onPressed: _promptBiometricUnlock,
                        child: const Text('Unlock with Biometrics'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return child ?? const SizedBox.shrink();
      },
    );
  }
}
