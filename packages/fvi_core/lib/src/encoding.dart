import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'errors.dart';

/// URL-safe base64 without padding: the alphabet is `A-Z a-z 0-9 - _`, so a
/// token survives copy/paste through WhatsApp as one unbroken word.
String base64UrlNoPad(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

Uint8List decodeBase64UrlNoPad(String text) {
  final padded = text.padRight((text.length + 3) & ~3, '=');
  try {
    return base64Url.decode(padded);
  } on FormatException {
    throw const FviFormatException('invalid base64url text');
  }
}

/// Crockford base32 omits I, L, O and U so a code read aloud or typed by hand
/// cannot be confused (0/O, 1/I/L).
const _crockford = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// Encodes [bytes] as Crockford base32, most significant bit first. Trailing
/// bits that do not fill a whole character are dropped, so 5 bytes (40 bits)
/// give exactly 8 characters.
String crockfordBase32(List<int> bytes) {
  final out = StringBuffer();
  var buffer = 0;
  var bits = 0;
  for (final byte in bytes) {
    buffer = (buffer << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      out.write(_crockford[(buffer >> bits) & 0x1F]);
    }
    buffer &= (1 << bits) - 1;
  }
  return out.toString();
}

/// Bytes from a cryptographically secure source unless a [random] is supplied
/// (tests only — never pass a non-secure Random in app code).
Uint8List randomBytes(int length, [Random? random]) {
  final source = random ?? Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (_) => source.nextInt(256)),
  );
}

bool bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
