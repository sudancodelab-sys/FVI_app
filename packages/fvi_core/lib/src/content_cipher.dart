import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'encoding.dart';
import 'errors.dart';
import 'keys.dart';

/// Encrypts content files (lessons, quizzes, flashcards, images) shipped
/// inside the student app.
///
/// Blob format: `"FVC1" | 12B nonce | AES-256-GCM ciphertext | 16B tag`.
/// The file's path inside the content tree is bound in as associated data, so
/// a blob moved to another path (e.g. a free lesson swapped for a locked one)
/// fails to decrypt instead of showing the wrong content.
abstract final class ContentCipher {
  static final _magic = ascii.encode('FVC1');
  static final _aes = AesGcm.with256bits();
  static const _nonceLength = 12;
  static const _macLength = 16;

  static Future<Uint8List> encrypt({
    required List<int> key,
    required String path,
    required List<int> plain,
    Random? random,
  }) async {
    _checkKey(key);
    final box = await _aes.encrypt(
      plain,
      secretKey: SecretKeyData(key),
      nonce: randomBytes(_nonceLength, random),
      aad: _aad(path),
    );
    return Uint8List.fromList([
      ..._magic,
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  static Future<Uint8List> decrypt({
    required List<int> key,
    required String path,
    required List<int> blob,
  }) async {
    _checkKey(key);
    const overhead = 4 + _nonceLength + _macLength;
    if (blob.length < overhead || !bytesEqual(blob.sublist(0, 4), _magic)) {
      throw ContentDecryptionException(path);
    }
    final nonce = blob.sublist(4, 4 + _nonceLength);
    final cipherText = blob.sublist(4 + _nonceLength, blob.length - _macLength);
    final mac = blob.sublist(blob.length - _macLength);
    try {
      final plain = await _aes.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: SecretKeyData(key),
        aad: _aad(path),
      );
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      throw ContentDecryptionException(path);
    }
  }

  static List<int> _aad(String path) => utf8.encode('fvi/v1/content/$path');

  static void _checkKey(List<int> key) {
    if (key.length != keyLength) {
      throw ArgumentError('expected a $keyLength-byte key');
    }
  }
}
