import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fvi_core/fvi_core.dart';
import 'package:fvi_student/src/activation/activation.dart';
import 'package:fvi_student/src/activation/vault.dart';

void main() {
  const starter = 'languages/english/starter';
  final root = List<int>.generate(32, (i) => Random(1).nextInt(256));
  late IssuerKeyPair issuer;
  late MemoryVault vault;
  var now = DateTime.utc(2026, 10, 30, 9);

  Activation app() => Activation(vault: vault, clock: () => now, issuerKey: issuer.publicKey);

  Future<String> codeFor(Activation a, {List<String> levels = const [starter], int days = 30}) async {
    final request = ActivationRequest.findIn(a.requestToken())!;
    final issued = await ActivationCode.issue(
      issuer: issuer,
      rootKey: root,
      devicePublicKey: request.devicePublicKey,
      grants: [for (final l in levels) Grant(NodeId(l), now.add(Duration(days: days)))],
      now: now,
      whatsappNumber: '249912345678',
    );
    return 'Copy this message, then open the FVI app.\n\n${issued.token}';
  }

  setUp(() async {
    issuer = await IssuerKeyPair.generate();
    vault = MemoryVault();
    now = DateTime.utc(2026, 10, 30, 9);
  });

  test('a code opens its level with the right key, and stays after a restart', () async {
    final a = app();
    await a.load();
    await a.saveProfile(const StudentProfile(name: 'Ahmed Mohamed', phone: '0912345678', level: starter));
    expect(a.activated, isFalse);

    expect(await a.apply(await codeFor(a)), isNull);
    expect(a.canOpen(starter), isTrue);
    expect(a.canOpen('languages/english/pre-intermediate-1'), isFalse);
    expect(await a.keyFor(starter), await ContentKeys.forNode(root, NodeId(starter)));
    expect(a.whatsappNumber, '249912345678');

    final again = app();
    await again.load();
    expect(again.deviceCode, a.deviceCode);
    expect(again.canOpen(starter), isTrue);
    expect(again.profile?.name, 'Ahmed Mohamed');
  });

  test('a code for another phone is refused', () async {
    final other = Activation(vault: MemoryVault(), clock: () => now, issuerKey: issuer.publicKey);
    await other.load();
    await other.saveProfile(const StudentProfile(name: 'Sara', phone: '0911111111', level: starter));
    final a = app();
    await a.load();
    expect(await a.apply(await codeFor(other)), CodeProblem.otherPhone);
    expect(await a.apply('hello'), CodeProblem.noCode);
    expect(a.activated, isFalse);
  });

  test('the levels close when the clock goes back, and when the access ends', () async {
    final a = app();
    await a.load();
    await a.saveProfile(const StudentProfile(name: 'Ahmed', phone: '0912345678', level: starter));
    await a.apply(await codeFor(a, days: 5));
    expect(a.endsSoon(starter), isNotNull);

    now = now.subtract(const Duration(days: 2));
    await a.checkClock();
    expect(a.clockBehind, isTrue);
    expect(a.canOpen(starter), isFalse);

    now = DateTime.utc(2026, 11, 10);
    await a.checkClock();
    expect(a.clockBehind, isFalse);
    expect(a.canOpen(starter), isFalse);
    expect(a.expired(starter), isTrue);
  });
}
