import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'binary.dart';
import 'encoding.dart';
import 'errors.dart';
import 'keys.dart';
import 'node_id.dart';
import 'time.dart';

/// Access to one node of the content tree (and everything below it) until
/// [expiresAt]. Times are UTC with whole-second precision, as on the wire.
class Grant {
  Grant(this.node, DateTime expiresAt) : expiresAt = wholeSecondsUtc(expiresAt);

  final NodeId node;
  final DateTime expiresAt;
}

/// A grant opened on the student's device, together with the node's key.
class UnlockedGrant extends Grant {
  UnlockedGrant(super.node, super.expiresAt, List<int> key)
    : key = Uint8List.fromList(key);

  final Uint8List key;
}

/// The result of issuing a code in the admin app: the text to send, plus what
/// the admin app needs for its records.
class IssuedActivation {
  IssuedActivation._(this.token, this.codeId, this.issuedAt, this.grants);

  final String token;

  /// Random 8-byte id, so a code in the admin's log can be matched to a code
  /// a student reports.
  final Uint8List codeId;
  final DateTime issuedAt;
  final List<Grant> grants;
}

/// A verified code, opened with this device's key.
class OpenedActivation {
  OpenedActivation._(
    this.codeId,
    this.issuedAt,
    this.whatsappNumber,
    this.grants,
  );

  final Uint8List codeId;

  /// Signed by the issuer, so it is a trusted lower bound for "now".
  final DateTime issuedAt;

  /// The institute's current WhatsApp number at the time the code was issued.
  /// Empty when the admin did not include one.
  final String whatsappNumber;
  final List<UnlockedGrant> grants;
}

/// Activation code wire format, version 1:
///
/// ```text
/// FVI1-ACT.<base64url(body)>.<base64url(signature)>
///
/// body   = header || sealed
/// header = u8 version | 4B issuer key id | 16B device fingerprint
///        | 8B code id | u32 issued-at | str whatsapp
///        | u8 n | n × (str node id | u32 expires-at)
/// sealed = 32B ephemeral X25519 public key | 12B nonce
///        | bytes16 AES-256-GCM(n × 32B node keys, aad = header) | 16B tag
/// signature = Ed25519(issuer, "fvi/v1/activation" || body)
/// ```
///
/// The node keys are encrypted to the device's X25519 key, so a code copied to
/// another phone is useless there even if its checks were bypassed.
abstract final class ActivationCode {
  static const prefix = 'FVI1-ACT.';
  static const maxGrants = 64;
  static const maxWhatsappLength = 30;
  static const _version = 1;
  static final _tokenPattern = RegExp(
    r'FVI1-ACT\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
  );
  static final _signatureDomain = utf8.encode('fvi/v1/activation');
  static final _wrapInfo = utf8.encode('fvi/v1/grant-wrap');
  static final _aes = AesGcm.with256bits();
  static final _x25519 = X25519();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: keyLength);

  /// The code inside a pasted WhatsApp message, or null if there is none.
  static String? findToken(String text) => _tokenPattern.firstMatch(text)?[0];

  /// Issues a code for the device that sent [devicePublicKey]. Used by the
  /// admin app only: it needs the issuer's private key and the root key.
  ///
  /// Throws [FviFormatException] if [devicePublicKey] (which comes from an
  /// untrusted request) is not a usable X25519 key.
  static Future<IssuedActivation> issue({
    required IssuerKeyPair issuer,
    required List<int> rootKey,
    required List<int> devicePublicKey,
    required List<Grant> grants,
    required DateTime now,
    String whatsappNumber = '',
    Random? random,
  }) async {
    if (devicePublicKey.length != keyLength) {
      throw const FviFormatException('invalid device public key');
    }
    if (grants.isEmpty || grants.length > maxGrants) {
      throw ArgumentError('a code must carry 1..$maxGrants grants');
    }
    if (grants.map((g) => g.node).toSet().length != grants.length) {
      throw ArgumentError('a node appears more than once');
    }
    if (whatsappNumber.length > maxWhatsappLength) {
      throw ArgumentError('WhatsApp number is too long');
    }
    final issuedAt = wholeSecondsUtc(now);
    for (final grant in grants) {
      if (!grant.expiresAt.isAfter(issuedAt)) {
        throw ArgumentError('the grant for ${grant.node} has already expired');
      }
    }

    final codeId = randomBytes(8, random);
    final header = ByteWriter()
      ..u8(_version)
      ..fixed(await issuerKeyId(issuer.publicKey), 4)
      ..fixed(await deviceFingerprint(devicePublicKey), 16)
      ..fixed(codeId, 8)
      ..u32(toEpochSeconds(issuedAt))
      ..string(whatsappNumber)
      ..u8(grants.length);
    for (final grant in grants) {
      header
        ..string(grant.node.value)
        ..u32(toEpochSeconds(grant.expiresAt));
    }
    final headerBytes = header.toBytes();

    final nodeKeys = BytesBuilder(copy: false);
    for (final grant in grants) {
      nodeKeys.add(await ContentKeys.forNode(rootKey, grant.node));
    }

    final ephemeral = await _x25519.newKeyPairFromSeed(
      randomBytes(keyLength, random),
    );
    final ephemeralPublic = (await ephemeral.extractPublicKey()).bytes;
    final wrapKey = await _wrapKey(
      localKeyPair: ephemeral,
      remotePublicKey: devicePublicKey,
      ephemeralPublicKey: ephemeralPublic,
      devicePublicKey: devicePublicKey,
      codeId: codeId,
    );
    final box = await _aes.encrypt(
      nodeKeys.toBytes(),
      secretKey: wrapKey,
      nonce: randomBytes(12, random),
      aad: headerBytes,
    );

    final sealed = ByteWriter()
      ..fixed(ephemeralPublic, keyLength)
      ..fixed(box.nonce, 12)
      ..bytes16(box.cipherText)
      ..fixed(box.mac.bytes, 16);
    final body = Uint8List.fromList([...headerBytes, ...sealed.toBytes()]);
    final signature = await issuer.sign([..._signatureDomain, ...body]);

    return IssuedActivation._(
      '$prefix${base64UrlNoPad(body)}.${base64UrlNoPad(signature)}',
      codeId,
      issuedAt,
      List.unmodifiable(grants),
    );
  }

  /// Verifies a code found in [text] and opens it with this [device]'s key.
  /// Throws [ActivationException] explaining why a code is rejected.
  static Future<OpenedActivation> open(
    String text, {
    required List<int> issuerPublicKey,
    required DeviceKeyPair device,
  }) async {
    final token = findToken(text);
    if (token == null) {
      throw const ActivationException(ActivationFailure.malformed, 'no code');
    }
    final parts = token.substring(prefix.length).split('.');
    final _Parsed parsed;
    final Uint8List signature;
    try {
      parsed = _Parsed.from(decodeBase64UrlNoPad(parts[0]));
      signature = decodeBase64UrlNoPad(parts[1]);
    } on FviFormatException catch (e) {
      throw ActivationException(ActivationFailure.malformed, e.message);
    }

    if (!bytesEqual(parsed.issuerKeyId, await issuerKeyId(issuerPublicKey))) {
      throw const ActivationException(ActivationFailure.unknownIssuer);
    }
    final signatureOk =
        signature.length == 64 &&
        await verifyIssuerSignature(
          issuerPublicKey: issuerPublicKey,
          message: [..._signatureDomain, ...parsed.body],
          signature: signature,
        );
    if (!signatureOk) {
      throw const ActivationException(ActivationFailure.badSignature);
    }
    if (!bytesEqual(
      parsed.fingerprint,
      await deviceFingerprint(device.publicKey),
    )) {
      throw const ActivationException(ActivationFailure.wrongDevice);
    }

    final List<int> nodeKeys;
    try {
      final wrapKey = await _wrapKey(
        localKeyPair: device.keyPair,
        remotePublicKey: parsed.ephemeralPublicKey,
        ephemeralPublicKey: parsed.ephemeralPublicKey,
        devicePublicKey: device.publicKey,
        codeId: parsed.codeId,
      );
      nodeKeys = await _aes.decrypt(
        SecretBox(parsed.cipherText, nonce: parsed.nonce, mac: Mac(parsed.mac)),
        secretKey: wrapKey,
        aad: parsed.header,
      );
    } on SecretBoxAuthenticationError {
      // Signed and addressed to this fingerprint, yet not decryptable: the
      // device key does not match the fingerprint it claims.
      throw const ActivationException(ActivationFailure.wrongDevice);
    } on FviFormatException catch (e) {
      throw ActivationException(ActivationFailure.malformed, e.message);
    }
    if (nodeKeys.length != parsed.grants.length * keyLength) {
      throw const ActivationException(
        ActivationFailure.malformed,
        'key count mismatch',
      );
    }

    return OpenedActivation._(
      parsed.codeId,
      parsed.issuedAt,
      parsed.whatsappNumber,
      [
        for (var i = 0; i < parsed.grants.length; i++)
          UnlockedGrant(
            parsed.grants[i].node,
            parsed.grants[i].expiresAt,
            nodeKeys.sublist(i * keyLength, (i + 1) * keyLength),
          ),
      ],
    );
  }

  static Future<SecretKey> _wrapKey({
    required SimpleKeyPair localKeyPair,
    required List<int> remotePublicKey,
    required List<int> ephemeralPublicKey,
    required List<int> devicePublicKey,
    required List<int> codeId,
  }) async {
    final shared = await _x25519.sharedSecretKey(
      keyPair: localKeyPair,
      remotePublicKey: SimplePublicKey(
        remotePublicKey,
        type: KeyPairType.x25519,
      ),
    );
    final sharedBytes = await shared.extractBytes();
    if (sharedBytes.every((b) => b == 0)) {
      // A low-order public key forces an all-zero secret, which would make
      // the wrapped keys readable by anyone. Never wrap or unwrap with it.
      throw const FviFormatException('invalid X25519 public key');
    }
    return _hkdf.deriveKey(
      secretKey: SecretKeyData(sharedBytes),
      nonce: codeId,
      info: [..._wrapInfo, ...ephemeralPublicKey, ...devicePublicKey],
    );
  }
}

class _Parsed {
  _Parsed._(
    this.body,
    this.header,
    this.issuerKeyId,
    this.fingerprint,
    this.codeId,
    this.issuedAt,
    this.whatsappNumber,
    this.grants,
    this.ephemeralPublicKey,
    this.nonce,
    this.cipherText,
    this.mac,
  );

  factory _Parsed.from(Uint8List body) {
    final r = ByteReader(body);
    final version = r.u8();
    if (version != ActivationCode._version) {
      throw FviFormatException('unsupported code version $version');
    }
    final issuerKeyId = r.fixed(4);
    final fingerprint = r.fixed(16);
    final codeId = r.fixed(8);
    final issuedAt = fromEpochSeconds(r.u32());
    final whatsapp = r.string();
    final count = r.u8();
    if (count == 0 || count > ActivationCode.maxGrants) {
      throw FviFormatException('invalid grant count $count');
    }
    final grants = <Grant>[];
    for (var i = 0; i < count; i++) {
      final nodeText = r.string();
      final expiresAt = fromEpochSeconds(r.u32());
      try {
        grants.add(Grant(NodeId(nodeText), expiresAt));
      } on FormatException catch (e) {
        throw FviFormatException('invalid node id: ${e.message}');
      }
    }
    final header = r.consumedSince(0);
    final ephemeral = r.fixed(keyLength);
    final nonce = r.fixed(12);
    final cipherText = r.bytes16();
    final mac = r.fixed(16);
    r.expectDone();
    return _Parsed._(
      body,
      header,
      issuerKeyId,
      fingerprint,
      codeId,
      issuedAt,
      whatsapp,
      grants,
      ephemeral,
      nonce,
      cipherText,
      mac,
    );
  }

  final Uint8List body;
  final Uint8List header;
  final Uint8List issuerKeyId;
  final Uint8List fingerprint;
  final Uint8List codeId;
  final DateTime issuedAt;
  final String whatsappNumber;
  final List<Grant> grants;
  final Uint8List ephemeralPublicKey;
  final Uint8List nonce;
  final Uint8List cipherText;
  final Uint8List mac;
}
