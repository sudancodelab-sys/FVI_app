import 'dart:typed_data';

import 'binary.dart';
import 'encoding.dart';
import 'errors.dart';
import 'keys.dart';
import 'node_id.dart';

/// What the student app sends to the institute over WhatsApp to ask for an
/// activation code. It carries no secret: only the device's public key and
/// the details the student typed in, which the admin should treat as claims.
class ActivationRequest {
  ActivationRequest({
    required List<int> devicePublicKey,
    required String name,
    required String phone,
    required this.requestedNode,
    required this.appVersion,
  }) : devicePublicKey = Uint8List.fromList(devicePublicKey),
       name = name.trim(),
       phone = phone.trim() {
    final problem = _problem(
      this.devicePublicKey,
      this.name,
      this.phone,
      appVersion,
    );
    if (problem != null) throw ArgumentError(problem);
  }

  static const prefix = 'FVI1-REQ.';
  static const _version = 1;
  static const maxNameLength = 100;
  static const maxPhoneLength = 30;
  static final _tokenPattern = RegExp(r'FVI1-REQ\.[A-Za-z0-9_-]+');

  final Uint8List devicePublicKey;
  final String name;
  final String phone;

  /// The level the student says they study; the admin may grant more, less
  /// or something else.
  final NodeId? requestedNode;
  final String appVersion;

  String encode() {
    final w = ByteWriter()
      ..u8(_version)
      ..fixed(devicePublicKey, keyLength)
      ..string(name)
      ..string(phone)
      ..string(requestedNode?.value ?? '')
      ..string(appVersion);
    return '$prefix${base64UrlNoPad(w.toBytes())}';
  }

  static ActivationRequest decode(String token) {
    if (!token.startsWith(prefix)) {
      throw const FviFormatException('not an activation request');
    }
    final r = ByteReader(decodeBase64UrlNoPad(token.substring(prefix.length)));
    final version = r.u8();
    if (version != _version) {
      throw FviFormatException('unsupported request version $version');
    }
    final devicePublicKey = r.fixed(keyLength);
    final name = r.string();
    final phone = r.string();
    final node = r.string();
    final appVersion = r.string();
    r.expectDone();
    final problem = _problem(
      devicePublicKey,
      name.trim(),
      phone.trim(),
      appVersion,
    );
    if (problem != null) throw FviFormatException(problem);
    final NodeId? requestedNode;
    try {
      requestedNode = node.isEmpty ? null : NodeId(node);
    } on FormatException catch (e) {
      throw FviFormatException('invalid requested node: ${e.message}');
    }
    return ActivationRequest(
      devicePublicKey: devicePublicKey,
      name: name,
      phone: phone,
      requestedNode: requestedNode,
      appVersion: appVersion,
    );
  }

  /// Finds and decodes the request token inside a pasted WhatsApp message.
  /// Returns null when the text contains no token at all.
  static ActivationRequest? findIn(String text) {
    final match = _tokenPattern.firstMatch(text);
    return match == null ? null : decode(match[0]!);
  }

  Future<String> deviceCode() => deviceDisplayCode(devicePublicKey);

  static String? _problem(
    List<int> devicePublicKey,
    String name,
    String phone,
    String appVersion,
  ) {
    if (devicePublicKey.length != keyLength) {
      return 'device public key must be $keyLength bytes';
    }
    if (name.isEmpty || name.length > maxNameLength) {
      return 'name must be 1..$maxNameLength characters';
    }
    if (phone.length > maxPhoneLength) {
      return 'phone must be at most $maxPhoneLength characters';
    }
    if (appVersion.length > 32) return 'app version is too long';
    return null;
  }
}
