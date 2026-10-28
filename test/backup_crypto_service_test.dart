import 'dart:convert';
import 'dart:typed_data';

import 'package:borrow_ledger/core/services/backup_crypto_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BackupCryptoService();
  final payload = Uint8List.fromList(utf8.encode('backup_format:2\nrecords'));

  test('encrypts and decrypts a backup payload', () async {
    final encrypted = await service.encrypt(
      payload: payload,
      password: 'correct horse battery staple',
    );

    expect(service.isEncryptedEnvelope(encrypted), isTrue);
    expect(
      await service.decrypt(
        envelopeBytes: encrypted,
        password: 'correct horse battery staple',
      ),
      payload,
    );
  });

  test('rejects a wrong password and modified ciphertext', () async {
    final encrypted = await service.encrypt(
      payload: payload,
      password: 'correct horse battery staple',
    );
    final envelope = jsonDecode(utf8.decode(encrypted)) as Map<String, dynamic>;
    final ciphertext = base64Decode(envelope['ciphertext'] as String);
    ciphertext[0] ^= 1;
    envelope['ciphertext'] = base64Encode(ciphertext);
    final modified = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));

    expect(
      () => service.decrypt(
        envelopeBytes: modified,
        password: 'correct horse battery staple',
      ),
      throwsA(isA<BackupAuthenticationException>()),
    );
    expect(
      () =>
          service.decrypt(envelopeBytes: encrypted, password: 'wrong password'),
      throwsA(isA<BackupAuthenticationException>()),
    );
  });

  test('rejects invalid passwords and envelope metadata', () async {
    expect(
      () => service.encrypt(payload: payload, password: 'short'),
      throwsA(isA<BackupPasswordException>()),
    );
    expect(service.validatePassword('1234567'), isNotNull);

    final encrypted = await service.encrypt(
      payload: payload,
      password: 'correct horse battery staple',
    );
    final envelope = jsonDecode(utf8.decode(encrypted)) as Map<String, dynamic>;
    envelope['cipher'] = 'unsupported';
    expect(
      () => service.decrypt(
        envelopeBytes: Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
        password: 'correct horse battery staple',
      ),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('rejects modified salt and nonce through authentication', () async {
    final encrypted = await service.encrypt(
      payload: payload,
      password: 'correct horse battery staple',
    );
    final envelope = jsonDecode(utf8.decode(encrypted)) as Map<String, dynamic>;
    for (final field in ['salt', 'nonce']) {
      final bytes = base64Decode(envelope[field] as String);
      bytes[0] ^= 1;
      final modified = Map<String, dynamic>.from(envelope)
        ..[field] = base64Encode(bytes);
      expect(
        () => service.decrypt(
          envelopeBytes: Uint8List.fromList(utf8.encode(jsonEncode(modified))),
          password: 'correct horse battery staple',
        ),
        throwsA(isA<BackupAuthenticationException>()),
      );
    }
  });
}
