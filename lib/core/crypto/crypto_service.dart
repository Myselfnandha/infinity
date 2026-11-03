import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

class CryptoService {
  static const String keyMasterKey = 'infinity_master_key';
  static const String keyMasterKeySalt = 'infinity_master_key_salt';

  final FlutterSecureStorage _secureStorage;

  CryptoService([FlutterSecureStorage? storage])
      : _secureStorage = storage ?? const FlutterSecureStorage();

  Uint8List generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  // This code for deriving cryptographic keys using Argon2id with memory hardness
  Uint8List deriveKeyArgon2({
    required String password,
    required Uint8List salt,
    int iterations = 3,
    int memoryKiB = 16384,
    int keyLength = 32,
  }) {
    final argon2 = Argon2BytesGenerator();
    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      version: Argon2Parameters.ARGON2_VERSION_13,
      iterations: iterations,
      memoryPowerOf2: 14,
      desiredKeyLength: keyLength,
    );
    argon2.init(parameters);

    final passBytes = utf8.encode(password);
    final result = Uint8List(keyLength);
    argon2.deriveKey(Uint8List.fromList(passBytes), 0, result, 0);
    return result;
  }

  Future<void> setupMasterKey(String userPassword) async {
    final salt = generateRandomBytes(16);
    final kek = deriveKeyArgon2(password: userPassword, salt: salt);
    final masterKey = generateRandomBytes(32);

    final encryptedMasterKey = encryptAesGcm(data: masterKey, key: kek);

    await _secureStorage.write(
      key: keyMasterKeySalt,
      value: base64Encode(salt),
    );
    await _secureStorage.write(
      key: keyMasterKey,
      value: base64Encode(encryptedMasterKey),
    );
  }

  // This code for encrypting raw bytes using AES-256-GCM with a 96-bit nonce and 128-bit MAC
  Uint8List encryptAesGcm({
    required Uint8List data,
    required Uint8List key,
  }) {
    final nonce = generateRandomBytes(12);
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      128,
      nonce,
      Uint8List(0),
    );
    cipher.init(true, params);

    final output = Uint8List(cipher.getOutputSize(data.length) + nonce.length);
    output.setRange(0, nonce.length, nonce);

    final len = cipher.processBytes(data, 0, data.length, output, nonce.length);
    final finalLen = cipher.doFinal(output, nonce.length + len);

    return Uint8List.sublistView(output, 0, nonce.length + len + finalLen);
  }

  // This code for decrypting AES-256-GCM encrypted byte payloads
  Uint8List decryptAesGcm({
    required Uint8List encryptedData,
    required Uint8List key,
  }) {
    final nonce = Uint8List.sublistView(encryptedData, 0, 12);
    final ciphertext = Uint8List.sublistView(encryptedData, 12);

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      128,
      nonce,
      Uint8List(0),
    );
    cipher.init(false, params);

    final output = Uint8List(cipher.getOutputSize(ciphertext.length));
    final len =
        cipher.processBytes(ciphertext, 0, ciphertext.length, output, 0);
    final finalLen = cipher.doFinal(output, len);

    return Uint8List.sublistView(output, 0, len + finalLen);
  }

  Future<bool> hasMasterKey() async {
    final res = await _secureStorage.read(key: keyMasterKey);
    return res != null && res.isNotEmpty;
  }
}
