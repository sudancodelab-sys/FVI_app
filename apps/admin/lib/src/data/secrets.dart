import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fvi_core/fvi_core.dart' show keyLength;

/// The institute's two secrets (docs/REQUIREMENTS.md 5.1): the seal seed that
/// signs every code, and the content root key every level's key comes from.
class InstituteKeys {
  InstituteKeys({required List<int> issuerSeed, required List<int> rootKey})
      : issuerSeed = Uint8List.fromList(issuerSeed),
        rootKey = Uint8List.fromList(rootKey);

  InstituteKeys.fromJson(Map<String, Object?> json)
      : this(issuerSeed: base64.decode(json['seal'] as String), rootKey: base64.decode(json['root'] as String));

  /// Fresh keys, made once when the institute sets the app up.
  factory InstituteKeys.generate() {
    final random = Random.secure();
    List<int> key() => [for (var i = 0; i < keyLength; i++) random.nextInt(256)];
    return InstituteKeys(issuerSeed: key(), rootKey: key());
  }

  /// The public development keys of keys/dev: codes made with them open only
  /// a student app built with them.
  static final development = InstituteKeys(
    issuerSeed: _hex('fd5d0883a7c40124e8f474b80895c73697327fd164dd1d0570f355aecb5a09c5'),
    rootKey: _hex('a3e9aaf0310e6610087999481d28072369cec22b67d6d31a4d72fb40b31768df'),
  );

  final Uint8List issuerSeed;
  final Uint8List rootKey;

  bool get isDevelopment => _equal(issuerSeed, development.issuerSeed);

  Map<String, Object?> toJson() => {'seal': base64.encode(issuerSeed), 'root': base64.encode(rootKey)};
}

/// A build for the institute passes `--dart-define=FVI_PRODUCTION=true`: it
/// never uses the development keys, and makes or restores the real ones.
const isProductionBuild = bool.fromEnvironment('FVI_PRODUCTION');

class BackupException implements Exception {
  const BackupException(this.wrongPassword);

  /// True for a backup that the password does not open; false for a file
  /// that is not a backup of this app at all.
  final bool wrongPassword;
}

/// The backup file (docs/REQUIREMENTS.md 4): the records, the keys and the
/// settings in one file, encrypted with a password the admin chooses. It is
/// JSON: the PBKDF2 salt and count, and the AES-256-GCM nonce and data.
abstract final class Backup {
  static const format = 'fvi-admin-backup';
  static const iterations = 200000;
  static final _aes = AesGcm.with256bits();

  static Future<Uint8List> seal(Map<String, Object?> payload, String password) async {
    final random = Random.secure();
    final salt = [for (var i = 0; i < 16; i++) random.nextInt(256)];
    final box = await _aes.encrypt(utf8.encode(jsonEncode(payload)),
        secretKey: await _key(password, salt, iterations), aad: utf8.encode(format));
    return Uint8List.fromList(utf8.encode(jsonEncode({
      'format': format,
      'version': 1,
      'kdf': 'pbkdf2-sha256',
      'iterations': iterations,
      'salt': base64.encode(salt),
      'nonce': base64.encode(box.nonce),
      'data': base64.encode([...box.cipherText, ...box.mac.bytes]),
    })));
  }

  static Future<Map<String, Object?>> open(List<int> file, String password) async {
    final Map<String, Object?> json;
    try {
      json = jsonDecode(utf8.decode(file)) as Map<String, Object?>;
    } on FormatException {
      throw const BackupException(false);
    }
    if (json['format'] != format || json['version'] != 1) throw const BackupException(false);
    final data = base64.decode(json['data'] as String);
    try {
      final plain = await _aes.decrypt(
        SecretBox(data.sublist(0, data.length - 16),
            nonce: base64.decode(json['nonce'] as String), mac: Mac(data.sublist(data.length - 16))),
        secretKey: await _key(password, base64.decode(json['salt'] as String), json['iterations'] as int),
        aad: utf8.encode(format),
      );
      return jsonDecode(utf8.decode(plain)) as Map<String, Object?>;
    } on SecretBoxAuthenticationError {
      throw const BackupException(true);
    }
  }

  static Future<SecretKey> _key(String password, List<int> salt, int iterations) =>
      Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256)
          .deriveKeyFromPassword(password: password, nonce: salt);
}

/// The PIN that opens the app, kept as a slow hash (docs/REQUIREMENTS.md 4).
abstract final class PinHash {
  static Future<String> make(String pin) async {
    final random = Random.secure();
    final salt = [for (var i = 0; i < 16; i++) random.nextInt(256)];
    return '${base64.encode(salt)}:${base64.encode(await _hash(pin, salt))}';
  }

  static Future<bool> check(String pin, String stored) async {
    final [salt, hash] = stored.split(':');
    return _equal(await _hash(pin, base64.decode(salt)), base64.decode(hash));
  }

  static Future<List<int>> _hash(String pin, List<int> salt) async =>
      (await Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 50000, bits: 256)
              .deriveKeyFromPassword(password: pin, nonce: salt))
          .extractBytes();
}

Uint8List _hex(String hex) =>
    Uint8List.fromList([for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)]);

bool _equal(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
