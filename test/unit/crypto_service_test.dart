// This code for testing cryptographic key derivation and AES-GCM encryption
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/crypto/crypto_service.dart';

void main() {
  group('CryptoService Tests', () {
    late CryptoService crypto;

    setUp(() {
      crypto = CryptoService();
    });

    test('Argon2id derives deterministic 32-byte key given same password and salt', () {
      // This code for verifying deterministic key derivation output
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      const password = 'TestSecurePassword123!';

      final key1 = crypto.deriveKeyArgon2(password: password, salt: salt);
      final key2 = crypto.deriveKeyArgon2(password: password, salt: salt);

      expect(key1.length, equals(32));
      expect(key1, equals(key2));
    });

    test('AES-256-GCM encrypts and decrypts media byte payloads correctly', () {
      // This code for validating authenticated encryption and decryption roundtrip
      final key = crypto.generateRandomBytes(32);
      final rawData = Uint8List.fromList(utf8.encode('Sample photo binary bytes payload'));

      final encrypted = crypto.encryptAesGcm(data: rawData, key: key);
      expect(encrypted, isNot(equals(rawData)));

      final decrypted = crypto.decryptAesGcm(encryptedData: encrypted, key: key);
      expect(decrypted, equals(rawData));
      expect(utf8.decode(decrypted), equals('Sample photo binary bytes payload'));
    });
  });
}

