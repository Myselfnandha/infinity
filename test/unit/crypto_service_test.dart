// This code for testing cryptographic key derivation and AES-GCM encryption
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/crypto/crypto_service.dart';

// This code for mocking FlutterSecureStorage in-memory without native hardware
class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  // This code for in-memory key-value map simulating secure storage
  final Map<String, String> _storage = {};

  @override
  // This code for storing a key-value pair into in-memory storage
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    // This code for writing value or clearing key if null
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  // This code for retrieving a value for key from in-memory storage
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    // This code for returning stored value or null
    return _storage[key];
  }
}

// This code for executing CryptoService unit tests
void main() {
  // This code for grouping CryptoService unit tests
  group('CryptoService Tests', () {
    late FakeFlutterSecureStorage fakeStorage;
    late CryptoService crypto;

    setUp(() {
      // This code for initializing fresh mock storage and crypto service before each test
      fakeStorage = FakeFlutterSecureStorage();
      crypto = CryptoService(fakeStorage);
    });

    // This code for testing Argon2id key derivation determinism
    test('Argon2id derives deterministic 32-byte key given same password and salt', () {
      // This code for verifying deterministic key derivation output
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      const password = 'TestSecurePassword123!';

      final key1 = crypto.deriveKeyArgon2(password: password, salt: salt);
      final key2 = crypto.deriveKeyArgon2(password: password, salt: salt);

      expect(key1.length, equals(32));
      expect(key1, equals(key2));
    });

    // This code for testing AES-256-GCM encryption and decryption roundtrip
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

    // This code for testing random byte generation length and non-uniformity
    test('generateRandomBytes returns non-empty byte buffer of requested length', () {
      // This code for generating random byte arrays of varied sizes
      final bytes16 = crypto.generateRandomBytes(16);
      final bytes32 = crypto.generateRandomBytes(32);

      expect(bytes16.length, equals(16));
      expect(bytes32.length, equals(32));
      expect(bytes16, isNot(equals(crypto.generateRandomBytes(16))));
    });

    // This code for testing master key setup and validation
    test('setupMasterKey and hasMasterKey persist and detect master key correctly', () async {
      // This code for verifying initially hasMasterKey returns false
      expect(await crypto.hasMasterKey(), isFalse);

      // This code for initializing master key with user password
      await crypto.setupMasterKey('MasterVaultSecretPass@2026');

      // This code for verifying master key presence
      expect(await crypto.hasMasterKey(), isTrue);

      // This code for verifying stored salt and encrypted master key in secure storage
      final storedSalt = await fakeStorage.read(key: CryptoService.keyMasterKeySalt);
      final storedEncryptedKey = await fakeStorage.read(key: CryptoService.keyMasterKey);

      expect(storedSalt, isNotNull);
      expect(storedEncryptedKey, isNotNull);

      // This code for decrypting master key using derived kek to verify payload integrity
      final salt = base64Decode(storedSalt!);
      final encryptedMasterKey = base64Decode(storedEncryptedKey!);
      final kek = crypto.deriveKeyArgon2(password: 'MasterVaultSecretPass@2026', salt: salt);
      final masterKey = crypto.decryptAesGcm(encryptedData: encryptedMasterKey, key: kek);

      expect(masterKey.length, equals(32));
    });

    // This code for testing AES-GCM decryption failure on tampered ciphertext or wrong key
    test('decryptAesGcm throws exception when tampered ciphertext or invalid key is supplied', () {
      // This code for creating valid ciphertext
      final key = crypto.generateRandomBytes(32);
      final wrongKey = crypto.generateRandomBytes(32);
      final rawData = Uint8List.fromList(utf8.encode('Top secret vault data'));
      final encrypted = crypto.encryptAesGcm(data: rawData, key: key);

      // This code for asserting decryption fails with wrong key
      expect(
        () => crypto.decryptAesGcm(encryptedData: encrypted, key: wrongKey),
        throwsA(isA<Exception>()),
      );

      // This code for creating tampered ciphertext by flipping a bit
      final tampered = Uint8List.fromList(encrypted);
      tampered[tampered.length - 1] ^= 0xFF;

      // This code for asserting decryption fails with tampered ciphertext
      expect(
        () => crypto.decryptAesGcm(encryptedData: tampered, key: key),
        throwsA(isA<Exception>()),
      );
    });
  });
}
