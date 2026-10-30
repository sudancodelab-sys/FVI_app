/// The public key the app checks activation codes with (docs/REQUIREMENTS.md 5.1).
///
/// The first version uses the key of keys/dev, as the admin app does
/// (decision #49). A later version with secret keys passes its own:
/// `--dart-define=FVI_ISSUER_KEY=<64 hex digits>`.
const _production = String.fromEnvironment('FVI_ISSUER_KEY');
const _development = '0e3f726aca1cdd3b5cbf9d442986317f1261e1323eeda441e0c624c3d3aa1d9e';

List<int> get issuerPublicKey {
  const hex = _production == '' ? _development : _production;
  return [for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)];
}

/// The institute's WhatsApp number (0904011473, with Sudan's 249 for
/// wa.me), until a code brings a newer one. A build may pass another with
/// `--dart-define=FVI_WHATSAPP=<number>`.
const defaultWhatsappNumber = String.fromEnvironment('FVI_WHATSAPP', defaultValue: '249904011473');

/// The version sent with an activation request; as in pubspec.yaml.
const appVersion = '1.0.0';
