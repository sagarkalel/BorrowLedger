import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class BackupPasswordException implements Exception {
  final String message;

  const BackupPasswordException(this.message);

  @override
  String toString() => message;
}

class BackupFormatException implements Exception {
  final String message;

  const BackupFormatException(this.message);

  @override
  String toString() => message;
}

class BackupAuthenticationException implements Exception {
  const BackupAuthenticationException();

  @override
  String toString() =>
      'The backup password is incorrect or the file is damaged.';
}

/// Encrypts and decrypts the outer backup envelope.
///
/// The ZIP produced by the existing backup format is kept as the encrypted
/// payload, so restore compatibility remains unchanged after decryption.
class BackupCryptoService {
  static const int minimumPasswordLength = 8;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _keyLength = 32;
  static const int _memory = 65536;
  static const int _iterations = 3;
  static const int _parallelism = 2;
  static const String _format = 'hisaabmate_encrypted_backup';
  static const int _formatVersion = 1;
  static const String _cipher = 'AES-256-GCM';
  static const String _kdf = 'Argon2id';
  static const List<int> _aad = <int>[
    72,
    105,
    115,
    97,
    97,
    98,
    77,
    97,
    116,
    101,
    45,
    66,
    97,
    99,
    107,
    117,
    112,
    45,
    118,
    49,
  ];

  const BackupCryptoService();

  String? validatePassword(String password) {
    if (password.trim().isEmpty) return 'Password is required.';
    if (password.length < minimumPasswordLength) {
      return 'Password must be at least $minimumPasswordLength characters.';
    }
    return null;
  }

  bool isEncryptedEnvelope(Uint8List bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map && decoded['format'] == _format;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List> encrypt({
    required Uint8List payload,
    required String password,
  }) async {
    final validationError = validatePassword(password);
    if (validationError != null) {
      throw BackupPasswordException(validationError);
    }

    final random = SecureRandom.defaultRandom;
    final salt = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => random.nextInt(256)),
    );
    final nonce = Uint8List.fromList(
      List<int>.generate(_nonceLength, (_) => random.nextInt(256)),
    );
    final key = await _deriveKey(password, salt);
    final secretBox = await AesGcm.with256bits().encrypt(
      payload,
      secretKey: key,
      nonce: nonce,
      aad: _aad,
    );

    final envelope = <String, dynamic>{
      'format': _format,
      'format_version': _formatVersion,
      'cipher': _cipher,
      'kdf': _kdf,
      'kdf_memory': _memory,
      'kdf_iterations': _iterations,
      'kdf_parallelism': _parallelism,
      'salt': base64Encode(salt),
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<Uint8List> decrypt({
    required Uint8List envelopeBytes,
    required String password,
  }) async {
    final validationError = validatePassword(password);
    if (validationError != null) {
      throw BackupPasswordException(validationError);
    }

    final envelope = _decodeEnvelope(envelopeBytes);
    final salt = _decodeBase64(
      envelope['salt'],
      'salt',
      expectedLength: _saltLength,
    );
    final nonce = _decodeBase64(
      envelope['nonce'],
      'nonce',
      expectedLength: _nonceLength,
    );
    final ciphertext = _decodeBase64(envelope['ciphertext'], 'ciphertext');
    final mac = _decodeBase64(envelope['mac'], 'mac', expectedLength: 16);
    final key = await _deriveKey(password, salt);

    try {
      final clearText = await AesGcm.with256bits().decrypt(
        SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
        aad: _aad,
      );
      return Uint8List.fromList(clearText);
    } on SecretBoxAuthenticationError {
      throw const BackupAuthenticationException();
    } catch (_) {
      throw const BackupAuthenticationException();
    }
  }

  Future<SecretKey> _deriveKey(String password, Uint8List salt) {
    return Argon2id(
      parallelism: _parallelism,
      memory: _memory,
      iterations: _iterations,
      hashLength: _keyLength,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  }

  Map<String, dynamic> _decodeEnvelope(Uint8List bytes) {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const BackupFormatException(
        'This is not a valid encrypted backup.',
      );
    }
    if (decoded is! Map) {
      throw const BackupFormatException(
        'This is not a valid encrypted backup.',
      );
    }
    final envelope = Map<String, dynamic>.from(decoded);
    if (envelope['format'] != _format ||
        envelope['format_version'] != _formatVersion ||
        envelope['cipher'] != _cipher ||
        envelope['kdf'] != _kdf ||
        envelope['kdf_memory'] != _memory ||
        envelope['kdf_iterations'] != _iterations ||
        envelope['kdf_parallelism'] != _parallelism) {
      throw const BackupFormatException(
        'This encrypted backup format is not supported.',
      );
    }
    for (final field in ['salt', 'nonce', 'ciphertext', 'mac']) {
      if (envelope[field] is! String || (envelope[field] as String).isEmpty) {
        throw BackupFormatException('Encrypted backup is missing $field.');
      }
    }
    return envelope;
  }

  Uint8List _decodeBase64(dynamic value, String field, {int? expectedLength}) {
    try {
      final bytes = Uint8List.fromList(base64Decode(value as String));
      if (expectedLength != null && bytes.length != expectedLength) {
        throw const FormatException();
      }
      return bytes;
    } catch (_) {
      throw BackupFormatException('Encrypted backup has an invalid $field.');
    }
  }
}
