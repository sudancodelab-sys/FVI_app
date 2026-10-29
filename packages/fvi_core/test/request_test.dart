import 'dart:convert';

import 'package:fvi_core/fvi_core.dart';
import 'package:test/test.dart';

void main() {
  late DeviceKeyPair device;

  setUp(() async => device = await DeviceKeyPair.generate());

  ActivationRequest request({String name = 'أحمد محمد عبدالله'}) =>
      ActivationRequest(
        devicePublicKey: device.publicKey,
        name: name,
        phone: '0912345678',
        requestedNode: NodeId('languages/english/level-1'),
        appVersion: '1.0.0',
      );

  test('round trip keeps every field, including Arabic text', () {
    final decoded = ActivationRequest.decode(request().encode());
    expect(decoded.devicePublicKey, device.publicKey);
    expect(decoded.name, 'أحمد محمد عبدالله');
    expect(decoded.phone, '0912345678');
    expect(decoded.requestedNode, NodeId('languages/english/level-1'));
    expect(decoded.appVersion, '1.0.0');
  });

  test('a request without a chosen level', () {
    final r = ActivationRequest(
      devicePublicKey: device.publicKey,
      name: 'سارة',
      phone: '',
      requestedNode: null,
      appVersion: '1.0.0',
    );
    expect(ActivationRequest.decode(r.encode()).requestedNode, isNull);
  });

  test('is found inside the whole WhatsApp message', () {
    final message =
        'طلب تفعيل تطبيق FVI\n'
        'الاسم: أحمد محمد عبدالله\n'
        'الهاتف: 0912345678\n\n'
        '${request().encode()}\n';
    expect(ActivationRequest.findIn(message)!.name, 'أحمد محمد عبدالله');
  });

  test('findIn returns null when there is no request', () {
    expect(ActivationRequest.findIn('السلام عليكم'), isNull);
  });

  test('the device code is the same on both sides', () async {
    final r = request();
    final decoded = ActivationRequest.decode(r.encode());
    final code = await decoded.deviceCode();
    expect(code, await deviceDisplayCode(device.publicKey));
    expect(
      code,
      matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$')),
    );
  });

  test('names are trimmed and limited', () {
    expect(request(name: '  سارة  ').name, 'سارة');
    expect(() => request(name: '   '), throwsArgumentError);
    expect(() => request(name: 'x' * 101), throwsArgumentError);
  });

  group('malformed input is a format error, never a crash', () {
    final bad = <String, String>{
      'wrong prefix': 'FVI1-ACT.AAAA',
      'not base64': 'FVI1-REQ.@@@@',
      'truncated': 'FVI1-REQ.AQ',
      'unknown version': 'FVI1-REQ.${'Ag'}',
    };
    bad.forEach((label, token) {
      test(label, () {
        expect(
          () => ActivationRequest.decode(token),
          throwsA(isA<FviFormatException>()),
        );
      });
    });

    test('trailing bytes', () {
      final token = request().encode();
      expect(
        () => ActivationRequest.decode('${token}AAAA'),
        throwsA(isA<FviFormatException>()),
      );
    });

    test('an invalid node id inside an otherwise valid request', () {
      List<int> str(String v) {
        final b = utf8.encode(v);
        return [b.length >> 8, b.length & 0xFF, ...b];
      }

      final payload = [
        1,
        ...device.publicKey,
        ...str('سارة'),
        ...str(''),
        ...str('Not A Node'),
        ...str('1.0.0'),
      ];
      final token = 'FVI1-REQ.${base64Url.encode(payload).replaceAll('=', '')}';
      expect(
        () => ActivationRequest.decode(token),
        throwsA(isA<FviFormatException>()),
      );
    });
  });
}
