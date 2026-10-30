import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the activation is kept on the phone. The device key and the level
/// keys are secrets, so everything goes to the Android Keystore-backed
/// secure storage, never to plain files (docs/REQUIREMENTS.md 7).
abstract class Vault {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureVault implements Vault {
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
}

/// For tests.
class MemoryVault implements Vault {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
