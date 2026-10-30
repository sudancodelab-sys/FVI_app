import 'dart:convert';
import 'dart:io';

import 'package:content_builder/content_builder.dart';
import 'package:fvi_core/fvi_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late BuildKeys keys;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('content_builder');
    keys = await BuildKeys.create(Directory('${tmp.path}/keys'));
    final input = await Directory('${tmp.path}/in').create();
    await File('${input.path}/index.json').writeAsString(jsonEncode([
      {'slug': 'starter', 'id': 'languages/english/starter', 'name': 'Starter'},
      {'slug': 'pre-intermediate-1', 'id': 'languages/english/pre-intermediate-1', 'name': 'Pre-Intermediate 1'},
    ]));
    await File('${input.path}/starter.json').writeAsString('{"name": "Starter"}');
    await File('${input.path}/pre-intermediate-1.json').writeAsString('{"name": "Pre-Intermediate 1"}');
    await Directory('${tmp.path}/out').create();
    await File('${tmp.path}/out/starter.json').writeAsString('{"plain": "an old export"}');
  });

  tearDown(() => tmp.delete(recursive: true));

  test('each level opens with its own key only, and no plain level is left', () async {
    await buildContent(input: Directory('${tmp.path}/in'), output: Directory('${tmp.path}/out'),
        rootKey: keys.rootKey);
    expect(File('${tmp.path}/out/starter.json').existsSync(), isFalse);
    final blob = await File('${tmp.path}/out/starter.fvc').readAsBytes();
    expect(utf8.decode(blob, allowMalformed: true), isNot(contains('Starter')));

    final starter = await ContentKeys.forNode(keys.rootKey, NodeId('languages/english/starter'));
    final plain = await ContentCipher.decrypt(key: starter, path: 'starter.fvc', blob: blob);
    expect(utf8.decode(plain), '{"name": "Starter"}');

    final other = await ContentKeys.forNode(keys.rootKey, NodeId('languages/english/pre-intermediate-1'));
    expect(ContentCipher.decrypt(key: other, path: 'starter.fvc', blob: blob),
        throwsA(isA<ContentDecryptionException>()));
  });

  test('a development code opens the level key on the device that asked', () async {
    final device = await DeviceKeyPair.generate();
    final request = ActivationRequest(devicePublicKey: device.publicKey, name: 'Test Student', phone: '0912345678',
        requestedNode: NodeId('languages/english/starter'), appVersion: '1.0.0');
    final now = DateTime.utc(2026, 10, 30, 9);
    final issued = await issueDevelopmentCode(keys: keys, requestText: 'Hello\n${request.encode()}',
        nodes: [NodeId('languages/english/starter')], days: 30, now: now);
    final opened = await ActivationCode.open(issued.token,
        issuerPublicKey: (await keys.issuer()).publicKey, device: device);
    expect(opened.grants.single.key,
        await ContentKeys.forNode(keys.rootKey, NodeId('languages/english/starter')));
    expect(opened.grants.single.expiresAt, endOfInstituteDay(DateTime.utc(2026, 11, 29)));
  });
}
