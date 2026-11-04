// This code for testing BackgroundController task registration and scheduler lifecycle
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/background/background_controller.dart';

void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping BackgroundController unit test scenarios
  group('BackgroundController Unit Tests', () {
    test('initForegroundTask executes safely without uncaught exceptions on desktop/headless runtime', () {
      // This code for verifying non-Android platform guard on foreground task setup
      expect(() => BackgroundController.initForegroundTask(), returnsNormally);
    });

    test('initWorkManager completes successfully on desktop/headless runtime', () async {
      // This code for verifying non-Android platform guard on WorkManager initialization
      await expectLater(BackgroundController.initWorkManager(), completes);
    });

    test('schedulePeriodicSync completes successfully with default interval', () async {
      // This code for verifying periodic sync task scheduling guard
      await expectLater(BackgroundController.schedulePeriodicSync(), completes);
    });

    test('schedulePeriodicSync completes successfully with custom interval', () async {
      // This code for verifying periodic sync task scheduling with custom 12-hour cadence
      await expectLater(BackgroundController.schedulePeriodicSync(intervalHours: 12), completes);
    });

    test('cancelScheduledSync completes successfully without errors', () async {
      // This code for verifying background task cancellation call
      await expectLater(BackgroundController.cancelScheduledSync(), completes);
    });

    test('callbackDispatcher entry point function is defined and executable', () {
      // This code for verifying top-level entrypoint dispatcher callback signature
      expect(callbackDispatcher, isA<Function>());
    });
  });
}
