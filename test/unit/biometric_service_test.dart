// This code for comprehensive unit testing of BiometricService hardware detection and authentication flows
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/security/biometric_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

// This code for mocking LocalAuthentication platform behaviors and return values
class FakeLocalAuthentication extends Fake implements LocalAuthentication {
  // This code for configuring canCheckBiometrics return value
  bool mockCanCheckBiometrics = true;

  // This code for configuring isDeviceSupported return value
  bool mockIsDeviceSupported = true;

  // This code for configuring available biometrics list
  List<BiometricType> mockBiometrics = [
    BiometricType.fingerprint,
    BiometricType.face,
  ];

  // This code for configuring authentication result
  bool mockAuthenticateResult = true;

  // This code for controlling whether authenticate throws an exception
  bool shouldThrowOnAuthenticate = false;

  // This code for tracking captured localizedReason argument
  String? lastLocalizedReason;

  @override
  Future<bool> get canCheckBiometrics async => mockCanCheckBiometrics;

  @override
  Future<bool> isDeviceSupported() async => mockIsDeviceSupported;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => mockBiometrics;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    // This code for validating error simulation
    if (shouldThrowOnAuthenticate) {
      throw Exception('Hardware sensor unavailable');
    }
    lastLocalizedReason = localizedReason;
    return mockAuthenticateResult;
  }
}

void main() {
  // This code for testing BiometricService initialization and authentication methods
  group('BiometricService Unit Tests', () {
    late FakeLocalAuthentication fakeAuth;
    late BiometricService biometricService;

    setUp(() {
      // This code for initializing fresh fake authentication provider and service before each test
      fakeAuth = FakeLocalAuthentication();
      biometricService = BiometricService(fakeAuth);
    });

    test('canAuthenticate returns true when biometrics can be checked', () async {
      // This code for validating true return when canCheckBiometrics is enabled
      fakeAuth.mockCanCheckBiometrics = true;
      fakeAuth.mockIsDeviceSupported = false;

      final result = await biometricService.canAuthenticate();
      expect(result, isTrue);
    });

    test('canAuthenticate returns true when device is supported even if biometrics check is false', () async {
      // This code for validating fallback device PIN/passcode capability
      fakeAuth.mockCanCheckBiometrics = false;
      fakeAuth.mockIsDeviceSupported = true;

      final result = await biometricService.canAuthenticate();
      expect(result, isTrue);
    });

    test('canAuthenticate returns false when neither biometrics nor device is supported', () async {
      // This code for validating unsupported hardware or emulator environment
      fakeAuth.mockCanCheckBiometrics = false;
      fakeAuth.mockIsDeviceSupported = false;

      final result = await biometricService.canAuthenticate();
      expect(result, isFalse);
    });

    test('getAvailableBiometrics returns configured biometric types', () async {
      // This code for testing retrieval of enrolled biometric sensors
      fakeAuth.mockBiometrics = [BiometricType.iris, BiometricType.strong];

      final biometrics = await biometricService.getAvailableBiometrics();
      expect(biometrics, equals([BiometricType.iris, BiometricType.strong]));
    });

    test('authenticate returns true bypass when biometric hardware is completely unavailable', () async {
      // This code for verifying non-blocking behavior on devices without biometric sensors
      fakeAuth.mockCanCheckBiometrics = false;
      fakeAuth.mockIsDeviceSupported = false;

      final success = await biometricService.authenticate(reason: 'Test Unlock');
      expect(success, isTrue);
      expect(fakeAuth.lastLocalizedReason, isNull);
    });

    test('authenticate forwards localizedReason and returns true on successful challenge', () async {
      // This code for testing successful user fingerprint or face unlock
      fakeAuth.mockCanCheckBiometrics = true;
      fakeAuth.mockAuthenticateResult = true;

      final success = await biometricService.authenticate(reason: 'Unlock Custom Vault');
      expect(success, isTrue);
      expect(fakeAuth.lastLocalizedReason, equals('Unlock Custom Vault'));
    });

    test('authenticate returns false when user cancels or biometric fails', () async {
      // This code for testing failed authentication attempt
      fakeAuth.mockCanCheckBiometrics = true;
      fakeAuth.mockAuthenticateResult = false;

      final success = await biometricService.authenticate();
      expect(success, isFalse);
      expect(fakeAuth.lastLocalizedReason, equals('Unlock Infinity Vault'));
    });

    test('authenticate catches exceptions and safely returns false', () async {
      // This code for testing resilient error handling on hardware sensor crash
      fakeAuth.mockCanCheckBiometrics = true;
      fakeAuth.shouldThrowOnAuthenticate = true;

      final success = await biometricService.authenticate();
      expect(success, isFalse);
    });
  });
}
