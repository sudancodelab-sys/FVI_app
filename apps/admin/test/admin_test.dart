import 'package:flutter_test/flutter_test.dart';
import 'package:fvi_admin/src/data/admin.dart';
import 'package:fvi_admin/src/data/records.dart';
import 'package:fvi_admin/src/data/secrets.dart';
import 'package:fvi_core/fvi_core.dart';

void main() {
  final starter = NodeId('languages/english/starter');
  final level1 = NodeId('languages/english/pre-intermediate-1');
  late MemoryStore store;
  var now = DateTime.utc(2026, 10, 29, 9);

  Admin admin() => Admin(store: store, clock: () => now);

  Future<(DeviceKeyPair, ActivationRequest)> request(String name, String phone, {NodeId? level}) async {
    final device = await DeviceKeyPair.generate();
    return (
      device,
      ActivationRequest(
          devicePublicKey: device.publicKey, name: name, phone: phone, requestedNode: level ?? level1, appVersion: '0.1.0'),
    );
  }

  setUp(() {
    store = MemoryStore();
    now = DateTime.utc(2026, 10, 29, 9);
  });

  test('a code issued here opens on the student phone, and the records stay encrypted', () async {
    final a = admin();
    await a.load();
    expect(a.keys!.isDevelopment, isTrue);
    final (device, req) = await request('Ahmed Mohamed', '0912 345 678');
    final issued = await a.issue(req, [level1], a.until(months: 1));

    final opened = await ActivationCode.open(Admin.message(issued.code.token),
        issuerPublicKey: (await IssuerKeyPair.fromSeed(a.keys!.issuerSeed)).publicKey, device: device);
    expect(opened.grants.single.node, level1);
    expect(opened.grants.single.key, await ContentKeys.forNode(a.keys!.rootKey, level1));
    expect(opened.grants.single.expiresAt, endOfInstituteDay(DateTime.utc(2026, 11, 29)));
    expect(opened.whatsappNumber, '249904011473');
    expect(store.values['records'], isNot(contains('Ahmed')));

    final again = admin();
    await again.load();
    expect(again.records.students.single.name, 'Ahmed Mohamed');
    expect(again.records.students.single.status(now), StudentStatus.active);
    expect(again.records.codesThisMonth(now), 1);
  });

  test('a returning phone, and the same name with another phone, are pointed out', () async {
    final a = admin();
    await a.load();
    final (_, first) = await request('Sara Osman', '0911 111 111');
    await a.issue(first, [starter], a.until(months: 1));
    expect(a.records.familiar(devicePublicKey: a.records.students.single.devicePublicKey, name: 'x', phone: '1'),
        isA<KnownDevice>());
    final (_, reinstalled) = await request('Sara Osman', '0922 222 222');
    expect(a.records.familiar(devicePublicKey: 'other', name: reinstalled.name, phone: reinstalled.phone),
        isA<SameNameOrPhone>());
    expect(a.records.familiar(devicePublicKey: 'other', name: 'Omar', phone: '0933 333 333'), isA<NewDevice>());
  });

  test('statuses follow the dates, and a renewal starts where access ends', () async {
    final a = admin();
    await a.load();
    final (_, req) = await request('Omar Hassan', '0912 000 000');
    final s = (await a.issue(req, [level1], a.until(months: 1))).student;
    now = DateTime.utc(2026, 11, 25);
    expect(s.status(now), StudentStatus.endingSoon);
    expect(a.until(months: 1, from: s.openUntil[level1]), endOfInstituteDay(DateTime.utc(2026, 12, 29)));
    now = DateTime.utc(2026, 12, 5);
    expect(s.status(now), StudentStatus.expired);
    expect(a.until(months: 1, from: s.openUntil[level1]), endOfInstituteDay(DateTime.utc(2027, 1, 5)));
    now = DateTime.utc(2027, 1, 31);
    expect(a.until(months: 1), endOfInstituteDay(DateTime.utc(2027, 2, 28)));
  });

  test('a backup opens with its password only, and brings everything back', () async {
    final a = admin();
    await a.load();
    final (_, req) = await request('Fatima', '0915 555 555');
    await a.issue(req, [starter], a.until(months: 2));
    final file = await a.backup('a long password');
    expect(a.lastBackup, now);

    store = MemoryStore();
    final b = admin();
    await b.load();
    expect(() => b.restore(file, 'wrong'), throwsA(isA<BackupException>().having((e) => e.wrongPassword, 'wrong', true)));
    await b.restore(file, 'a long password');
    expect(b.records.students.single.name, 'Fatima');
    expect(b.keys!.rootKey, a.keys!.rootKey);
  });

  test('the PIN opens the app; a Sudanese number becomes international', () async {
    final a = admin();
    await a.load();
    await a.setPin('2580');
    a.lock();
    expect(await a.unlock('1111'), isFalse);
    expect(await a.unlock('2580'), isTrue);
    expect(Admin.whatsappTo('0912 345 678', 'hi').toString(), 'https://wa.me/249912345678?text=hi');
    expect(Admin.whatsappTo('+249 912 345 678', 'hi').toString(), 'https://wa.me/249912345678?text=hi');
  });
}
