// This code for comprehensive unit testing of TelegramApiExtractorHelper, DOM regex parsers, and edge cases
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/core/telegram/tdlib_service.dart';
import 'package:infinity/features/auth/telegram_api_extractor_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TelegramApiExtractorHelper Unit Tests', () {
    test('parseExtractorMessage correctly parses valid payload with integer apiId', () {
      final jsonPayload = jsonEncode({
        'apiId': 30662321,
        'apiHash': 'cf007e0155c41fd1aa9b114b592377e0',
        'stage': 'extracted',
      });

      final parsed = TelegramApiExtractorHelper.parseExtractorMessage(jsonPayload);
      expect(parsed, isNotNull);
      expect(parsed!['apiId'], equals(30662321));
      expect(parsed['apiHash'], equals('cf007e0155c41fd1aa9b114b592377e0'));
      expect(parsed['stage'], equals('extracted'));
      expect(parsed['isComplete'], isTrue);
    });

    test('parseExtractorMessage parses string apiId and trims whitespace', () {
      final jsonPayload = jsonEncode({
        'apiId': '  30662321  ',
        'apiHash': ' cf007e0155c41fd1aa9b114b592377e0 ',
        'stage': 'extracted',
      });

      final parsed = TelegramApiExtractorHelper.parseExtractorMessage(jsonPayload);
      expect(parsed, isNotNull);
      expect(parsed!['apiId'], equals(30662321));
      expect(parsed['apiHash'], equals('cf007e0155c41fd1aa9b114b592377e0'));
      expect(parsed['isComplete'], isTrue);
    });

    test('parseExtractorMessage flags incomplete when apiHash length is invalid', () {
      final jsonPayload = jsonEncode({
        'apiId': 30662321,
        'apiHash': 'tooshort',
        'stage': 'partial',
      });

      final parsed = TelegramApiExtractorHelper.parseExtractorMessage(jsonPayload);
      expect(parsed, isNotNull);
      expect(parsed!['apiId'], equals(30662321));
      expect(parsed['apiHash'], isNull);
      expect(parsed['isComplete'], isFalse);
    });

    test('parseExtractorMessage flags incomplete when apiId is non-numeric or negative', () {
      final jsonPayload = jsonEncode({
        'apiId': -5,
        'apiHash': 'cf007e0155c41fd1aa9b114b592377e0',
        'stage': 'error',
      });

      final parsed = TelegramApiExtractorHelper.parseExtractorMessage(jsonPayload);
      expect(parsed, isNotNull);
      expect(parsed!['apiId'], isNull);
      expect(parsed['apiHash'], equals('cf007e0155c41fd1aa9b114b592377e0'));
      expect(parsed['isComplete'], isFalse);
    });

    test('parseExtractorMessage safely handles malformed JSON without throwing', () {
      final parsed = TelegramApiExtractorHelper.parseExtractorMessage('not a json string');
      expect(parsed, isNull);
    });

    test('parseExtractorMessage correctly identifies stage tags', () {
      final stages = ['waiting_code', 'create_app', 'apps_page', 'auth_page'];
      for (final stage in stages) {
        final payload = jsonEncode({'stage': stage});
        final parsed = TelegramApiExtractorHelper.parseExtractorMessage(payload);
        expect(parsed!['stage'], equals(stage));
        expect(parsed['isComplete'], isFalse);
      }
    });

    test('extractFromTextOrHtml extracts credentials from modern [data-copy] HTML attributes', () {
      const htmlSnippet = '''
        <div class="row">
          <div class="form-group">
            <span class="label">App api_id:</span>
            <span class="value" data-copy="30662321">30662321</span>
          </div>
          <div class="form-group">
            <span class="label">App api_hash:</span>
            <span class="value" data-copy="cf007e0155c41fd1aa9b114b592377e0">cf007e0155c41fd1aa9b114b592377e0</span>
          </div>
        </div>
      ''';

      final extracted = TelegramApiExtractorHelper.extractFromTextOrHtml(htmlSnippet);
      expect(extracted, isNotNull);
      expect(extracted!['apiId'], equals(30662321));
      expect(extracted['apiHash'], equals('cf007e0155c41fd1aa9b114b592377e0'));
    });

    test('extractFromTextOrHtml extracts credentials from .creds > .cred text representation', () {
      const htmlSnippet = '''
        <div class="creds">
          <div class="cred">App api_id: 30662321</div>
          <div class="cred">App api_hash: cf007e0155c41fd1aa9b114b592377e0</div>
        </div>
      ''';

      final extracted = TelegramApiExtractorHelper.extractFromTextOrHtml(htmlSnippet);
      expect(extracted, isNotNull);
      expect(extracted!['apiId'], equals(30662321));
      expect(extracted['apiHash'], equals('cf007e0155c41fd1aa9b114b592377e0'));
    });

    test('extractFromTextOrHtml extracts credentials from unformatted body text', () {
      const textContent = '''
        Your active Telegram applications:
        App api_id: 30662321
        App api_hash: cf007e0155c41fd1aa9b114b592377e0
        Short name: infinityvault
      ''';

      final extracted = TelegramApiExtractorHelper.extractFromTextOrHtml(textContent);
      expect(extracted, isNotNull);
      expect(extracted!['apiId'], equals(30662321));
      expect(extracted['apiHash'], equals('cf007e0155c41fd1aa9b114b592377e0'));
    });

    test('extractFromTextOrHtml returns null for empty or non-matching content', () {
      expect(TelegramApiExtractorHelper.extractFromTextOrHtml(''), isNull);
      expect(TelegramApiExtractorHelper.extractFromTextOrHtml('Welcome to Telegram login'), isNull);
    });

    test('Persisting extracted credentials updates AppPreferences and TDLib cleanly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPreferences.getInstance();

      const testId = 30662321;
      const testHash = 'cf007e0155c41fd1aa9b114b592377e0';

      await prefs.setTelegramApiId(testId);
      await prefs.setTelegramApiHash(testHash);

      expect(prefs.telegramApiId, equals(testId));
      expect(prefs.telegramApiHash, equals(testHash));

      final tdlib = TdlibService();
      // Test restartClient logic
      await tdlib.restartClient(apiId: testId, apiHash: testHash);
      expect(tdlib.activeApiId, equals(testId));
      expect(tdlib.activeApiHash, equals(testHash));
    });
  });
}
