/// The public key the app checks activation codes with (docs/REQUIREMENTS.md 5.1).
///
/// A build for the students passes the production key:
/// `--dart-define=FVI_ISSUER_KEY=<64 hex digits>`. Without it the app uses the
/// development key of keys/dev, and accepts only codes signed with it.
const _production = String.fromEnvironment('FVI_ISSUER_KEY');
const _development = '0e3f726aca1cdd3b5cbf9d442986317f1261e1323eeda441e0c624c3d3aa1d9e';

bool get isDevelopmentBuild => _production.isEmpty;

List<int> get issuerPublicKey {
  const hex = _production == '' ? _development : _production;
  return [for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)];
}

/// The institute's WhatsApp number until a code brings the current one:
/// `--dart-define=FVI_WHATSAPP=249912345678`. Without it, "Request on
/// WhatsApp" lets the student choose the chat.
const defaultWhatsappNumber = String.fromEnvironment('FVI_WHATSAPP');

/// The version sent with an activation request; as in pubspec.yaml.
const appVersion = '0.1.0';
