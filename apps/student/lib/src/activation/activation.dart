import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:fvi_core/fvi_core.dart';

import 'issuer.dart';
import 'vault.dart';

/// What the student typed in to ask for activation (docs/REQUIREMENTS.md 3.1).
class StudentProfile {
  const StudentProfile({required this.name, required this.phone, required this.level});

  StudentProfile.fromJson(Map<String, Object?> json)
      : name = json['name'] as String,
        phone = json['phone'] as String,
        level = json['level'] as String;

  final String name;
  final String phone;

  /// The id of the level the student says they study, e.g. languages/english/starter.
  final String level;

  Map<String, Object?> toJson() => {'name': name, 'phone': phone, 'level': level};
}

/// Why a pasted code was refused.
enum CodeProblem { noCode, otherInstitute, altered, otherPhone, clockBehind }

/// The student's activation: this phone's key, the details sent with the
/// request, and every level opened by the codes received (docs/REQUIREMENTS.md 5).
class Activation extends ChangeNotifier {
  Activation({Vault? vault, DateTime Function()? clock, List<int>? issuerKey})
      : _vault = vault ?? SecureVault(),
        _clock = clock ?? DateTime.now,
        _issuerKey = issuerKey ?? issuerPublicKey;

  static const _deviceKey = 'device';
  static const _profileKey = 'profile';
  static const _grantsKey = 'grants';
  static const _lastSeenKey = 'last-seen';
  static const _whatsappKey = 'whatsapp';

  /// "Your access ends in N days" shows this long before (docs/REQUIREMENTS.md 3.3).
  static const warning = Duration(days: 7);

  final Vault _vault;
  final DateTime Function() _clock;
  final List<int> _issuerKey;

  late DeviceKeyPair _device;
  var _grants = GrantBook();
  DateTime? _lastSeen;
  var _loaded = false;
  var _clockBehind = false;
  String deviceCode = '';
  StudentProfile? profile;
  String whatsappNumber = defaultWhatsappNumber;

  bool get loaded => _loaded;

  /// Whether a code was ever applied on this phone.
  bool get activated => !_grants.isEmpty;

  /// The phone's clock is earlier than a time the app has already seen: the
  /// levels stay closed until it is corrected (docs/REQUIREMENTS.md 5.5).
  bool get clockBehind => _clockBehind;

  DateTime get _now => _clock().toUtc();

  /// Reads the activation from the phone, making this phone's key on the
  /// first launch, and checks the clock.
  Future<void> load() async {
    final saved = await _vault.read(_deviceKey);
    if (saved == null) {
      _device = await DeviceKeyPair.generate();
      await _vault.write(_deviceKey, base64.encode(_device.privateKey));
    } else {
      _device = await DeviceKeyPair.fromPrivateKey(base64.decode(saved));
    }
    deviceCode = await deviceDisplayCode(_device.publicKey);
    final profileJson = await _vault.read(_profileKey);
    if (profileJson != null) profile = StudentProfile.fromJson(jsonDecode(profileJson) as Map<String, Object?>);
    final grantsJson = await _vault.read(_grantsKey);
    if (grantsJson != null) {
      _grants = GrantBook([
        for (final g in (jsonDecode(grantsJson) as List).cast<Map<String, Object?>>())
          UnlockedGrant(NodeId(g['node'] as String), fromEpochSeconds(g['until'] as int),
              base64.decode(g['key'] as String)),
      ]);
    }
    whatsappNumber = await _vault.read(_whatsappKey) ?? defaultWhatsappNumber;
    final lastSeen = await _vault.read(_lastSeenKey);
    _lastSeen = lastSeen == null ? null : fromEpochSeconds(int.parse(lastSeen));
    await checkClock();
    _loaded = true;
    notifyListeners();
  }

  /// Run on every start and every return to the app.
  Future<void> checkClock() async {
    final check = ClockGuard.check(now: _now, lastSeen: _lastSeen);
    await _saw(check);
  }

  Future<void> _saw(ClockCheck check) async {
    _clockBehind = !check.isOk;
    _lastSeen = check.lastSeen;
    await _vault.write(_lastSeenKey, '${toEpochSeconds(check.lastSeen)}');
    notifyListeners();
  }

  Future<void> saveProfile(StudentProfile value) async {
    profile = value;
    await _vault.write(_profileKey, jsonEncode(value.toJson()));
    notifyListeners();
  }

  /// The FVI1-REQ token that goes at the end of the WhatsApp message, asking
  /// for [level] (by default the student's own).
  String requestToken({String? level}) => ActivationRequest(
        devicePublicKey: _device.publicKey,
        name: profile!.name,
        phone: profile!.phone,
        requestedNode: NodeId(level ?? profile!.level),
        appVersion: appVersion,
      ).encode();

  /// The WhatsApp chat with the institute, with [message] ready to send.
  Uri whatsappUri(String message) => Uri.parse(
      'https://wa.me/${whatsappNumber.replaceAll(RegExp(r'\D'), '')}?text=${Uri.encodeComponent(message)}');

  /// Opens the code in [text] (a whole WhatsApp message will do) and adds its
  /// levels; returns null when it worked, or what was wrong.
  Future<CodeProblem?> apply(String text) async {
    final OpenedActivation opened;
    try {
      opened = await ActivationCode.open(text, issuerPublicKey: _issuerKey, device: _device);
    } on ActivationException catch (e) {
      return switch (e.reason) {
        ActivationFailure.malformed => CodeProblem.noCode,
        ActivationFailure.unknownIssuer => CodeProblem.otherInstitute,
        ActivationFailure.badSignature => CodeProblem.altered,
        ActivationFailure.wrongDevice => CodeProblem.otherPhone,
      };
    }
    final check = ClockGuard.afterCode(now: _now, issuedAt: opened.issuedAt, lastSeen: _lastSeen);
    if (!check.isOk) {
      await _saw(check);
      return CodeProblem.clockBehind;
    }
    _grants.addAll(opened.grants);
    await _vault.write(_grantsKey, jsonEncode([
      for (final g in _grants.grants)
        {'node': g.node.value, 'until': toEpochSeconds(g.expiresAt), 'key': base64.encode(g.key)},
    ]));
    if (opened.whatsappNumber.isNotEmpty) {
      whatsappNumber = opened.whatsappNumber;
      await _vault.write(_whatsappKey, whatsappNumber);
    }
    await _saw(check);
    return null;
  }

  bool canOpen(String level) => !_clockBehind && _grants.canOpen(NodeId(level), _now);

  /// Opened once, but not now: "renew" rather than "activate".
  bool expired(String level) => _grants.hasExpired(NodeId(level), _now);

  /// The key of [level]'s content, or null while it is closed.
  Future<Uint8List?> keyFor(String level) async =>
      _clockBehind ? null : _grants.keyFor(NodeId(level), _now);

  /// When [level]'s access ends, if it is open.
  DateTime? openUntil(String level) => _grants.activeGrantFor(NodeId(level), _now)?.expiresAt;

  /// The day in the institute's time zone that [level]'s access ends, if it
  /// ends within [warning].
  DateTime? endsSoon(String level) {
    final until = openUntil(level);
    if (until == null || until.difference(_now) > warning) return null;
    return instituteDate(until);
  }
}

/// Gives the screens the [Activation].
class ActivationScope extends InheritedNotifier<Activation> {
  const ActivationScope({super.key, required Activation activation, required super.child})
      : super(notifier: activation);

  static Activation of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActivationScope>()!.notifier!;

  /// For callbacks: no rebuild when the activation changes.
  static Activation read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ActivationScope>()!.notifier!;
}
