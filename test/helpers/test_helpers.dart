// This code for providing reusable mock services, fake providers, and widget test wrappers
import 'dart:async';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/src/internals.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:handy_tdlib_next/handy_tdlib_next.dart' as td;
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/di/providers.dart';
import 'package:infinity/core/security/biometric_service.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/core/telegram/tdlib_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// This code for providing isolated in-memory SQLite database instance
class TestDatabase extends AppDatabase {
  TestDatabase() : super.forTesting(NativeDatabase.memory());
}

// This code for mocking ConnectivityPlatform interface
class FakeConnectivityPlatform extends ConnectivityPlatform with MockPlatformInterfaceMixin {
  // This code for current mock connectivity results
  List<ConnectivityResult> results = [ConnectivityResult.wifi];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => results;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => Stream.value(results);
}

// This code for mocking PathProviderPlatform interface with safe temporary folder
class FakePathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  // This code for temporary path string
  final String tempPath;

  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;

  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
}

// This code for mocking TdlibService in headless widget and unit tests
class FakeTdlibService extends Fake implements TdlibService {
  // This code for mock auth state stream controller
  final StreamController<TelegramAuthState> _authStateController =
      StreamController<TelegramAuthState>.broadcast();

  // This code for current auth state
  TelegramAuthState _currentAuthState = TelegramAuthState.ready;

  // This code for mock vault chat ID
  int? mockVaultChatId = -100123456789;

  @override
  int? get vaultChatId => mockVaultChatId;

  @override
  int? get activeApiId => 30662321;

  @override
  String? get activeApiHash => 'cf007e0155c41fd1aa9b114b592377e0';

  @override
  String? get authPhoneNumber => lastPhoneNumber;

  // This code for tracking created topic names
  final List<String> createdTopics = [];

  // This code for tracking login attempts
  String? lastPhoneNumber;
  String? lastAuthCode;
  String? lastPassword;
  bool isDisposed = false;

  @override
  TelegramAuthState get currentAuthState => _currentAuthState;

  @override
  Stream<TelegramAuthState> get authStateStream => _authStateController.stream;

  @override
  String? get qrCodeLink => 'https://t.me/fake_qr_code_link';

  // This code for setting simulated auth state and emitting to stream
  void setAuthState(TelegramAuthState state) {
    _currentAuthState = state;
    _authStateController.add(state);
  }

  @override
  Future<void> sendPhoneNumber(String phoneNumber) async {
    lastPhoneNumber = phoneNumber;
    setAuthState(TelegramAuthState.waitingForCode);
  }

  @override
  Future<void> sendAuthCode(String code) async {
    lastAuthCode = code;
    setAuthState(TelegramAuthState.ready);
  }

  @override
  Future<void> send2FaPassword(String password) async {
    lastPassword = password;
    setAuthState(TelegramAuthState.ready);
  }

  @override
  void resetToPhoneNumber() {
    setAuthState(TelegramAuthState.waitingForPhoneNumber);
  }

  @override
  Future<void> logOut() async {
    setAuthState(TelegramAuthState.uninitialized);
  }

  @override
  Future<int?> createTopic(String title, {int iconColor = 7322096}) async {
    createdTopics.add(title);
    return 200 + createdTopics.length;
  }

  @override
  int getTopicIdForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('video')) return 102;
    if (lower.contains('photo') || lower.contains('image')) return 101;
    if (lower.contains('doc') || lower.contains('pdf') || lower.contains('zip')) return 104;
    if (lower.contains('trash')) return 105;
    return 101;
  }

  @override
  Future<void> restartClient({int? apiId, String? apiHash}) async {
    // This code for simulating client restart with custom API credentials
  }

  @override
  Future<td.Message?> uploadMedia({
    required String filePath,
    required String mediaType,
    required int topicId,
    String? caption,
  }) async {
    return null;
  }

  @override
  void dispose() {
    isDisposed = true;
    _authStateController.close();
  }
}

// This code for mocking BiometricService
class FakeBiometricService extends Fake implements BiometricService {
  // This code for mock authenticate result
  bool canAuth = true;
  bool authSuccess = true;

  @override
  Future<bool> canAuthenticate() async => canAuth;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [BiometricType.fingerprint];

  @override
  Future<bool> authenticate({String reason = 'Unlock Infinity Vault'}) async => authSuccess;
}

// This code for building a test widget scaffold wrapped in CupertinoApp and ProviderScope
Widget buildTestApp({
  required Widget child,
  required TestDatabase database,
  required AppPreferences preferences,
  FakeTdlibService? tdlibService,
  FakeBiometricService? biometricService,
  List<Override> additionalOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      preferencesProvider.overrideWithValue(preferences),
      if (tdlibService != null) tdlibServiceProvider.overrideWithValue(tdlibService),
      if (biometricService != null) biometricServiceProvider.overrideWithValue(biometricService),
      ...additionalOverrides,
    ],
    child: CupertinoApp(
      home: child,
    ),
  );
}
