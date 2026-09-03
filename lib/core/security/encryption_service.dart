import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static const String _defaultSalt = 'DZ_RECHARGE_SECURE_SALT_2026_V1';

  /// Generates a SHA-256 hash of the input string with optional salt
  static String hash(String input, {String? salt}) {
    final effectiveSalt = salt ?? _defaultSalt;
    final bytes = utf8.encode('$effectiveSalt:$input');
    return sha256.convert(bytes).toString();
  }

  /// Generates an HMAC-SHA256 signature using a secret key
  static String sign(String payload, String secretKey) {
    final keyBytes = utf8.encode(secretKey);
    final payloadBytes = utf8.encode(payload);
    final hmac = Hmac(sha256, keyBytes);
    return hmac.convert(payloadBytes).toString();
  }

  /// Verifies an HMAC-SHA256 signature
  static bool verifySignature(String payload, String signature, String secretKey) {
    final expected = sign(payload, secretKey);
    return expected == signature;
  }

  /// Encrypts text with an internal key using reversible byte masking + base64 encoding
  static String encrypt(String plainText, {String? key}) {
    if (plainText.isEmpty) return '';
    final effectiveKey = key ?? _defaultSalt;
    final keyBytes = utf8.encode(effectiveKey);
    final textBytes = utf8.encode(plainText);

    final result = List<int>.filled(textBytes.length, 0);
    for (int i = 0; i < textBytes.length; i++) {
      result[i] = textBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return base64.encode(result);
  }

  /// Decrypts text encrypted by `encrypt`
  static String decrypt(String cipherText, {String? key}) {
    if (cipherText.isEmpty) return '';
    try {
      final effectiveKey = key ?? _defaultSalt;
      final keyBytes = utf8.encode(effectiveKey);
      final cipherBytes = base64.decode(cipherText);

      final result = List<int>.filled(cipherBytes.length, 0);
      for (int i = 0; i < cipherBytes.length; i++) {
        result[i] = cipherBytes[i] ^ keyBytes[i % keyBytes.length];
      }
      return utf8.decode(result);
    } catch (_) {
      return '';
    }
  }
}
