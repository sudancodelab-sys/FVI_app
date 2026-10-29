/// Thrown when encoded data (a request, a code, a content blob header) is not
/// in the expected shape. The data is untrusted input, so callers should show
/// a friendly "invalid code" message rather than this text.
class FviFormatException implements Exception {
  const FviFormatException(this.message);

  final String message;

  @override
  String toString() => 'FviFormatException: $message';
}

/// Why an activation code was rejected by the student app.
enum ActivationFailure {
  /// The text is not an activation code, or it was truncated/altered so it
  /// cannot be parsed.
  malformed,

  /// The code was signed by a different issuer key — e.g. a development code
  /// pasted into a production build, or a code meant for another institute.
  unknownIssuer,

  /// The signature does not match: the code was altered after it was issued.
  badSignature,

  /// The code was issued for a different device (another phone, or this phone
  /// before the app was reinstalled).
  wrongDevice,
}

class ActivationException implements Exception {
  const ActivationException(this.reason, [this.detail]);

  final ActivationFailure reason;
  final String? detail;

  @override
  String toString() =>
      'ActivationException(${reason.name}${detail == null ? '' : ': $detail'})';
}

/// Thrown when an encrypted content blob cannot be decrypted: wrong key, the
/// blob was moved to a different path, or the bytes were altered.
class ContentDecryptionException implements Exception {
  const ContentDecryptionException(this.path);

  final String path;

  @override
  String toString() => 'ContentDecryptionException($path)';
}
