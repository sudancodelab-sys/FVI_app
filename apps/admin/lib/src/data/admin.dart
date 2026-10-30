import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fvi_core/fvi_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'records.dart';
import 'secrets.dart';

/// Where the admin app keeps its data on the phone: the keys and the PIN in
/// secure storage (the Android Keystore), the records encrypted with a key
/// that is itself in secure storage.
abstract class Store {
  Future<String?> secret(String key);
  Future<void> setSecret(String key, String value);
  Future<String?> value(String key);
  Future<void> setValue(String key, String value);
}

class PhoneStore implements Store {
  static const _secure = FlutterSecureStorage();

  @override
  Future<String?> secret(String key) => _secure.read(key: key);

  @override
  Future<void> setSecret(String key, String value) => _secure.write(key: key, value: value);

  @override
  Future<String?> value(String key) async => (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> setValue(String key, String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);
}

/// For tests.
class MemoryStore implements Store {
  final secrets = <String, String>{};
  final values = <String, String>{};

  @override
  Future<String?> secret(String key) async => secrets[key];

  @override
  Future<void> setSecret(String key, String value) async => secrets[key] = value;

  @override
  Future<String?> value(String key) async => values[key];

  @override
  Future<void> setValue(String key, String value) async => values[key] = value;
}

/// The result of issuing a code: who it is for, and the WhatsApp message.
class Issued {
  Issued(this.student, this.code);

  final StudentRecord student;
  final CodeRecord code;
}

/// The admin app's state: the keys, the records, the settings and the lock.
class Admin extends ChangeNotifier {
  Admin({Store? store, DateTime Function()? clock})
      : _store = store ?? PhoneStore(),
        _clock = clock ?? DateTime.now;

  static const defaultWhatsapp = '249904011473';
  static final _aes = AesGcm.with256bits();

  final Store _store;
  final DateTime Function() _clock;

  var loaded = false;
  var unlocked = false;
  InstituteKeys? keys;
  var records = Records();
  var whatsapp = defaultWhatsapp;
  DateTime? lastBackup;
  var biometrics = false;
  String? _pin;

  DateTime get now => _clock().toUtc();
  bool get hasPin => _pin != null;

  Future<void> load() async {
    _pin = await _store.secret('pin');
    final keysJson = await _store.secret('keys');
    keys = keysJson != null
        ? InstituteKeys.fromJson(jsonDecode(keysJson) as Map<String, Object?>)
        : (isProductionBuild ? null : InstituteKeys.development);
    final settings = await _store.value('settings');
    if (settings != null) _settingsFrom(jsonDecode(settings) as Map<String, Object?>);
    final blob = await _store.value('records');
    if (blob != null) records = Records.fromJson(await _decrypt(blob));
    loaded = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------- the lock

  Future<void> setPin(String pin) async {
    _pin = await PinHash.make(pin);
    await _store.setSecret('pin', _pin!);
    unlocked = true;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    if (_pin == null || !await PinHash.check(pin, _pin!)) return false;
    unlocked = true;
    notifyListeners();
    return true;
  }

  /// After the phone's fingerprint check passed.
  void unlockWithBiometrics() {
    unlocked = true;
    notifyListeners();
  }

  void lock() {
    unlocked = false;
    notifyListeners();
  }

  Future<void> setBiometrics(bool on) async {
    biometrics = on;
    await _saveSettings();
  }

  // ---------------------------------------------------------------- keys

  /// The institute's first setup in a production build: new keys, kept on
  /// this phone and in every backup.
  Future<void> createKeys() => _setKeys(InstituteKeys.generate());

  Future<void> _setKeys(InstituteKeys value) async {
    keys = value;
    await _store.setSecret('keys', jsonEncode(value.toJson()));
    notifyListeners();
  }

  // ---------------------------------------------------------------- codes

  /// Issues a code for the phone of [request], opening [nodes] until [until].
  Future<Issued> issue(ActivationRequest request, List<NodeId> nodes, DateTime until) async {
    final device = base64.encode(request.devicePublicKey);
    final student = records.byDevice(device) ??
        StudentRecord(
          devicePublicKey: device,
          deviceCode: await request.deviceCode(),
          name: request.name,
          phone: request.phone,
          firstSeen: now,
        );
    student
      ..name = request.name
      ..phone = request.phone
      ..requested = request.requestedNode ?? student.requested;
    if (!records.students.contains(student)) records.students.add(student);
    return _issue(student, request.devicePublicKey, nodes, until);
  }

  /// A new code for a student already in the records: a renewal, or more content.
  Future<Issued> issueAgain(StudentRecord student, List<NodeId> nodes, DateTime until) =>
      _issue(student, base64.decode(student.devicePublicKey), nodes, until);

  Future<Issued> _issue(StudentRecord student, List<int> device, List<NodeId> nodes, DateTime until) async {
    final k = keys!;
    final issued = await ActivationCode.issue(
      issuer: await IssuerKeyPair.fromSeed(k.issuerSeed),
      rootKey: k.rootKey,
      devicePublicKey: device,
      grants: [for (final n in nodes) Grant(n, until)],
      now: now,
      whatsappNumber: whatsapp,
    );
    final code = CodeRecord(
      id: issued.codeId.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      issuedAt: issued.issuedAt,
      grants: [for (final g in issued.grants) GrantRecord(g.node, g.expiresAt)],
      token: issued.token,
    );
    student.codes.add(code);
    await _saveRecords();
    notifyListeners();
    return Issued(student, code);
  }

  /// The last second of the institute's day [months] months from [from] (or
  /// from today): "a month" from 29 October is through 29 November.
  DateTime until({required int months, DateTime? from}) {
    final day = instituteDate(from != null && from.isAfter(now) ? from : now);
    final last = DateTime.utc(day.year, day.month + months + 1, 0).day; // 31 January + 1 month: 28 February
    return endOfInstituteDay(DateTime.utc(day.year, day.month + months, min(day.day, last)));
  }

  /// The WhatsApp message that carries a code: short instructions first, in
  /// both of the student app's languages, then the code (docs/REQUIREMENTS.md 5.3).
  static String message(String token) =>
      'Copy this message, then open the FVI app.\nانسخ هذه الرسالة ثم افتح تطبيق FVI.\n\n$token';

  /// The chat with a student: a Sudanese number written 09… becomes 2499….
  static Uri whatsappTo(String phone, String text) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = '249${digits.substring(1)}';
    return Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(text)}');
  }

  // ---------------------------------------------------------------- settings and backup

  /// The number students write to, as wa.me wants it: 0904011473 is 249904011473.
  Future<void> setWhatsapp(String number) async {
    whatsapp = whatsappTo(number, '').pathSegments.last;
    await _saveSettings();
  }

  Future<Uint8List> backup(String password) async {
    final file = await Backup.seal({
      'keys': keys!.toJson(),
      'records': records.toJson(),
      'settings': _settings(),
    }, password);
    lastBackup = now;
    await _saveSettings();
    return file;
  }

  /// Replaces everything on this phone with the backup: on a new admin phone.
  Future<void> restore(List<int> file, String password) async {
    final payload = await Backup.open(file, password);
    await _setKeys(InstituteKeys.fromJson(payload['keys'] as Map<String, Object?>));
    records = Records.fromJson(payload['records'] as Map<String, Object?>);
    _settingsFrom(payload['settings'] as Map<String, Object?>);
    await _saveRecords();
    await _saveSettings();
  }

  Map<String, Object?> _settings() => {
        'whatsapp': whatsapp,
        'lastBackup': lastBackup == null ? null : toEpochSeconds(lastBackup!),
        'biometrics': biometrics,
      };

  void _settingsFrom(Map<String, Object?> json) {
    whatsapp = json['whatsapp'] as String? ?? defaultWhatsapp;
    lastBackup = json['lastBackup'] == null ? null : fromEpochSeconds(json['lastBackup'] as int);
    biometrics = json['biometrics'] as bool? ?? false;
  }

  Future<void> _saveSettings() async {
    await _store.setValue('settings', jsonEncode(_settings()));
    notifyListeners();
  }

  // ---------------------------------------------------------------- the records, encrypted

  Future<SecretKey> _recordsKey() async {
    var key = await _store.secret('records-key');
    if (key == null) {
      final random = Random.secure();
      key = base64.encode([for (var i = 0; i < 32; i++) random.nextInt(256)]);
      await _store.setSecret('records-key', key);
    }
    return SecretKey(base64.decode(key));
  }

  Future<void> _saveRecords() async {
    final box = await _aes.encrypt(utf8.encode(jsonEncode(records.toJson())), secretKey: await _recordsKey());
    await _store.setValue('records', base64.encode(box.concatenation()));
  }

  Future<Map<String, Object?>> _decrypt(String blob) async {
    final box = SecretBox.fromConcatenation(base64.decode(blob), nonceLength: 12, macLength: 16);
    return jsonDecode(utf8.decode(await _aes.decrypt(box, secretKey: await _recordsKey()))) as Map<String, Object?>;
  }
}

/// Gives the screens the [Admin].
class AdminScope extends InheritedNotifier<Admin> {
  const AdminScope({super.key, required Admin admin, required super.child}) : super(notifier: admin);

  static Admin of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AdminScope>()!.notifier!;

  static Admin read(BuildContext context) => context.getInheritedWidgetOfExactType<AdminScope>()!.notifier!;
}
