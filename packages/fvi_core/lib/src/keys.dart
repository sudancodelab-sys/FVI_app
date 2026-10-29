import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'encoding.dart';
import 'node_id.dart';

const keyLength = 32;

final _sha256 = Sha256();
final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: keyLength);

/// Fixed HKDF salt for the content-key tree (domain separation from every
/// other HKDF use in the system).
final _contentSalt = utf8.encode('fvi/v1/content-keys');

/// Derives per-node content keys from the root content key.
///
/// ```text
/// key(department) = HKDF(root, "fvi/v1/node/<department>")
/// key(course)     = HKDF(key(department), "fvi/v1/node/<department>/<course>")
/// key(unit)       = HKDF(key(course), "fvi/v1/node/<department>/<course>/<unit>")
/// ```
///
/// Holding a node's key is therefore enough to derive every key below it, and
/// nothing above it. The root key itself is never given to a student.
abstract final class ContentKeys {
  static Future<Uint8List> forNode(List<int> rootKey, NodeId node) =>
      _deriveChain(rootKey, node.lineage);

  /// Derives the key of [node] from the key of one of its ancestors (or of
  /// [node] itself).
  static Future<Uint8List> descend({
    required List<int> ancestorKey,
    required NodeId ancestor,
    required NodeId node,
  }) {
    if (!ancestor.isAncestorOrSelfOf(node)) {
      throw ArgumentError('$ancestor is not an ancestor of $node');
    }
    return _deriveChain(ancestorKey, node.lineage.sublist(ancestor.depth));
  }

  static Future<Uint8List> _deriveChain(
    List<int> startKey,
    List<NodeId> steps,
  ) async {
    _checkKey(startKey);
    var key = Uint8List.fromList(startKey);
    for (final step in steps) {
      final derived = await _hkdf.deriveKey(
        secretKey: SecretKeyData(key),
        nonce: _contentSalt,
        info: utf8.encode('fvi/v1/node/${step.value}'),
      );
      key = Uint8List.fromList(await derived.extractBytes());
    }
    return key;
  }
}

/// The institute's signing key. The private seed lives only in the admin app
/// (and its encrypted backup); the public key is compiled into the student app.
class IssuerKeyPair {
  IssuerKeyPair._(this._keyPair, this.seed, this.publicKey);

  final SimpleKeyPair _keyPair;
  final Uint8List seed;
  final Uint8List publicKey;

  static Future<IssuerKeyPair> fromSeed(List<int> seed) async {
    _checkKey(seed);
    final keyPair = await Ed25519().newKeyPairFromSeed(seed);
    final publicKey = await keyPair.extractPublicKey();
    return IssuerKeyPair._(
      keyPair,
      Uint8List.fromList(seed),
      Uint8List.fromList(publicKey.bytes),
    );
  }

  static Future<IssuerKeyPair> generate([Random? random]) =>
      fromSeed(randomBytes(keyLength, random));

  Future<Uint8List> sign(List<int> message) async {
    final signature = await Ed25519().sign(message, keyPair: _keyPair);
    return Uint8List.fromList(signature.bytes);
  }
}

/// Short identifier of an issuer public key, carried in every activation code
/// so the student app can tell a development code from a production one.
Future<Uint8List> issuerKeyId(List<int> issuerPublicKey) async =>
    Uint8List.fromList(
      (await _sha256.hash(issuerPublicKey)).bytes.sublist(0, 4),
    );

Future<bool> verifyIssuerSignature({
  required List<int> issuerPublicKey,
  required List<int> message,
  required List<int> signature,
}) => Ed25519().verify(
  message,
  signature: Signature(
    signature,
    publicKey: SimplePublicKey(issuerPublicKey, type: KeyPairType.ed25519),
  ),
);

/// A student device's key-agreement key. Generated once on first launch and
/// kept in secure storage; activation codes carry content keys encrypted to it.
class DeviceKeyPair {
  DeviceKeyPair._(this._keyPair, this.privateKey, this.publicKey);

  final SimpleKeyPair _keyPair;
  final Uint8List privateKey;
  final Uint8List publicKey;

  SimpleKeyPair get keyPair => _keyPair;

  static Future<DeviceKeyPair> fromPrivateKey(List<int> privateKey) async {
    _checkKey(privateKey);
    final keyPair = await X25519().newKeyPairFromSeed(privateKey);
    final publicKey = await keyPair.extractPublicKey();
    return DeviceKeyPair._(
      keyPair,
      Uint8List.fromList(privateKey),
      Uint8List.fromList(publicKey.bytes),
    );
  }

  static Future<DeviceKeyPair> generate([Random? random]) =>
      fromPrivateKey(randomBytes(keyLength, random));
}

/// Binds an activation code to one device: the first 16 bytes of
/// SHA-256(device public key).
Future<Uint8List> deviceFingerprint(List<int> devicePublicKey) async =>
    Uint8List.fromList(
      (await _sha256.hash(devicePublicKey)).bytes.sublist(0, 16),
    );

/// The short code shown to the student and the admin, e.g. `7K3Q-9XM2`.
/// It is for people to recognise a device at a glance; the full fingerprint
/// is what codes are bound to.
Future<String> deviceDisplayCode(List<int> devicePublicKey) async {
  final fp = await deviceFingerprint(devicePublicKey);
  final text = crockfordBase32(fp.sublist(0, 5));
  return '${text.substring(0, 4)}-${text.substring(4)}';
}

void _checkKey(List<int> key) {
  if (key.length != keyLength) {
    throw ArgumentError('expected a $keyLength-byte key, got ${key.length}');
  }
}
