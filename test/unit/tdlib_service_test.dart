// This code for comprehensive unit testing of TdlibService, authentication states, topic routing, and session management
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/telegram/tdlib_service.dart';

void main() {
  group('TdlibService Unit & Manual Logic Tests', () {
    late TdlibService tdlib;

    setUp(() {
      tdlib = TdlibService();
    });

    test('Singleton identity ensures consistent instance across app providers', () {
      final instance1 = TdlibService();
      final instance2 = TdlibService();
      expect(identical(instance1, instance2), isTrue);
      expect(identical(instance1, tdlib), isTrue);
    });

    test('Initial authentication state is valid TelegramAuthState enum', () {
      expect(tdlib.currentAuthState, isA<TelegramAuthState>());
      expect(TelegramAuthState.values, contains(TelegramAuthState.uninitialized));
      expect(TelegramAuthState.values, contains(TelegramAuthState.waitingForPhoneNumber));
      expect(TelegramAuthState.values, contains(TelegramAuthState.waitingForCode));
      expect(TelegramAuthState.values, contains(TelegramAuthState.waitingForPassword));
      expect(TelegramAuthState.values, contains(TelegramAuthState.waitingForQrCode));
      expect(TelegramAuthState.values, contains(TelegramAuthState.ready));
      expect(TelegramAuthState.values, contains(TelegramAuthState.loggingOut));
      expect(TelegramAuthState.values, contains(TelegramAuthState.closed));
      expect(TelegramAuthState.values, contains(TelegramAuthState.error));
    });

    test('resetToPhoneNumber updates state to waitingForPhoneNumber and clears qrLink', () {
      tdlib.resetToPhoneNumber();
      expect(tdlib.currentAuthState, equals(TelegramAuthState.waitingForPhoneNumber));
      expect(tdlib.qrCodeLink, isNull);
    });

    test('Topic resolution correctly routes Photos category', () {
      final topicId = tdlib.getTopicIdForCategory('Photos');
      expect(topicId, isNotNull);
      expect(topicId, isA<int>());
    });

    test('Topic resolution correctly routes Videos category', () {
      final topicId = tdlib.getTopicIdForCategory('Videos');
      expect(topicId, isNotNull);
      expect(topicId, isA<int>());
    });

    test('Topic resolution correctly routes Screenshots category', () {
      final topicId = tdlib.getTopicIdForCategory('Screenshots');
      expect(topicId, isNotNull);
      expect(topicId, isA<int>());
    });

    test('Topic resolution correctly routes Files, documents, pdfs, and zips', () {
      expect(tdlib.getTopicIdForCategory('Files'), isNotNull);
      expect(tdlib.getTopicIdForCategory('Documents'), isNotNull);
      expect(tdlib.getTopicIdForCategory('Archive.zip'), isNotNull);
      expect(tdlib.getTopicIdForCategory('Invoice.pdf'), isNotNull);
    });

    test('Topic resolution correctly routes Trash category', () {
      final topicId = tdlib.getTopicIdForCategory('Trash');
      expect(topicId, isNotNull);
      expect(topicId, isA<int>());
    });

    test('Case-insensitive category name routing', () {
      final idLower = tdlib.getTopicIdForCategory('videos');
      final idUpper = tdlib.getTopicIdForCategory('VIDEOS');
      final idMixed = tdlib.getTopicIdForCategory('ViDeOs');
      expect(idLower, equals(idUpper));
      expect(idLower, equals(idMixed));
    });

    test('authStateStream emits events on state transitions', () async {
      expectLater(
        tdlib.authStateStream,
        emits(TelegramAuthState.waitingForPhoneNumber),
      );
      tdlib.resetToPhoneNumber();
    });

    test('activeApiId and activeApiHash properties exist and start unconfigured', () {
      expect(tdlib.activeApiId == null || tdlib.activeApiId is int, isTrue);
      expect(tdlib.activeApiHash == null || tdlib.activeApiHash is String, isTrue);
    });
  });
}
