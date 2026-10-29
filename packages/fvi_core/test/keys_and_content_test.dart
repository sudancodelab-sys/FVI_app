import 'dart:convert';
import 'dart:typed_data';

import 'package:fvi_core/fvi_core.dart';
import 'package:test/test.dart';

void main() {
  final rootKey = Uint8List.fromList(List.generate(32, (i) => 255 - i));
  final dept = NodeId('languages');
  final course = NodeId('languages/english');
  final unit = NodeId('languages/english/level-1');

  group('NodeId', () {
    test('accepts department, course and unit ids', () {
      expect(unit.depth, 3);
      expect(unit.parent, course);
      expect(unit.lineage, [dept, course, unit]);
    });

    test('rejects malformed ids', () {
      for (final bad in [
        '',
        'Languages',
        'languages/',
        '/languages',
        'languages//english',
        'languages/english/level-1/lesson-1',
        'لغات',
        'level_1',
        'a--b',
        '-a',
      ]) {
        expect(() => NodeId(bad), throwsFormatException, reason: bad);
      }
    });

    test('ancestry does not confuse shared prefixes', () {
      expect(dept.isAncestorOrSelfOf(unit), isTrue);
      expect(unit.isAncestorOrSelfOf(unit), isTrue);
      expect(unit.isAncestorOrSelfOf(dept), isFalse);
      expect(NodeId('lang').isAncestorOrSelfOf(dept), isFalse);
      expect(NodeId('languages/eng').isAncestorOrSelfOf(unit), isFalse);
      expect(
        NodeId('languages/english/level-1')
            .isAncestorOrSelfOf(NodeId('languages/english/level-10')),
        isFalse,
      );
    });

    test('a grant on a prefix-sharing sibling opens nothing', () async {
      final now = DateTime.utc(2026, 10, 29);
      final level1 = NodeId('languages/english/level-1');
      final book = GrantBook([
        UnlockedGrant(
          level1,
          now.add(const Duration(days: 30)),
          await ContentKeys.forNode(rootKey, level1),
        ),
      ]);
      final level10 = NodeId('languages/english/level-10');
      expect(book.canOpen(level10, now), isFalse);
      expect(book.hasActiveWithin(level10, now), isFalse);
      expect(
        () async => ContentKeys.descend(
          ancestorKey: rootKey,
          ancestor: level1,
          node: level10,
        ),
        throwsArgumentError,
      );
    });
  });

  group('ContentKeys', () {
    test(
      'an ancestor key derives exactly the same unit key as the root',
      () async {
        final fromRoot = await ContentKeys.forNode(rootKey, unit);
        final deptKey = await ContentKeys.forNode(rootKey, dept);
        final courseKey = await ContentKeys.forNode(rootKey, course);

        expect(
          await ContentKeys.descend(
            ancestorKey: deptKey,
            ancestor: dept,
            node: unit,
          ),
          fromRoot,
        );
        expect(
          await ContentKeys.descend(
            ancestorKey: courseKey,
            ancestor: course,
            node: unit,
          ),
          fromRoot,
        );
        expect(
          await ContentKeys.descend(
            ancestorKey: fromRoot,
            ancestor: unit,
            node: unit,
          ),
          fromRoot,
        );
      },
    );

    test('different nodes and different roots give different keys', () async {
      final keys = {
        for (final id in [
          'languages',
          'computer',
          'languages/english',
          'languages/english/level-1',
          'languages/english/level-2',
          'computer/english/level-1',
        ])
          base64.encode(await ContentKeys.forNode(rootKey, NodeId(id))),
      };
      expect(keys, hasLength(6));

      final otherRoot = Uint8List(32);
      expect(
        await ContentKeys.forNode(otherRoot, unit),
        isNot(await ContentKeys.forNode(rootKey, unit)),
      );
    });

    test('a unit key cannot be used to climb to its course', () {
      expect(
        () async => ContentKeys.descend(
          ancestorKey: rootKey,
          ancestor: unit,
          node: course,
        ),
        throwsArgumentError,
      );
    });

    test('derivation is stable across releases (test vector)', () async {
      // If this vector changes, every activation code already given to
      // students stops opening content. Never update it to make a test pass.
      final key = await ContentKeys.forNode(Uint8List(32), unit);
      expect(base64.encode(key), _unitKeyVector);
    });
  });

  group('GrantBook', () {
    final now = DateTime.utc(2026, 10, 29, 12);
    final soon = now.add(const Duration(days: 5));
    final later = now.add(const Duration(days: 60));

    Future<UnlockedGrant> grant(NodeId node, DateTime expires) async =>
        UnlockedGrant(node, expires, await ContentKeys.forNode(rootKey, node));

    test('a course grant opens its units with the correct key', () async {
      final book = GrantBook([await grant(course, later)]);
      expect(book.canOpen(unit, now), isTrue);
      expect(
        await book.keyFor(unit, now),
        await ContentKeys.forNode(rootKey, unit),
      );
      expect(book.canOpen(NodeId('languages/french/level-1'), now), isFalse);
      expect(await book.keyFor(NodeId('computer/office/basics'), now), isNull);
    });

    test('expired grants close content but are remembered', () async {
      final book = GrantBook([await grant(unit, soon)]);
      final afterExpiry = soon.add(const Duration(seconds: 1));
      expect(book.canOpen(unit, now), isTrue);
      expect(book.canOpen(unit, afterExpiry), isFalse);
      expect(book.hasExpired(unit, afterExpiry), isTrue);
      expect(
        book.hasExpired(NodeId('computer/office/basics'), afterExpiry),
        isFalse,
      );
      expect(await book.keyFor(unit, afterExpiry), isNull);
    });

    test('a renewal extends, an older code never shortens', () async {
      final book = GrantBook([await grant(unit, later)]);
      book.addAll([await grant(unit, soon)]);
      expect(book.activeGrantFor(unit, now)!.expiresAt, later);
    });

    test('the longest-lasting covering grant wins', () async {
      final book = GrantBook([
        await grant(unit, soon),
        await grant(dept, later),
      ]);
      expect(book.activeGrantFor(unit, now)!.node, dept);
      expect(
        book.activeGrantFor(unit, soon.add(const Duration(days: 1)))!.node,
        dept,
      );
    });

    test(
      'a department shows as active when one of its units is open',
      () async {
        final book = GrantBook([await grant(unit, later)]);
        expect(book.hasActiveWithin(dept, now), isTrue);
        expect(book.canOpen(dept, now), isFalse);
        expect(book.hasActiveWithin(NodeId('computer'), now), isFalse);
      },
    );

    test('expiring-soon list is sorted and limited to the window', () async {
      final book = GrantBook([
        await grant(unit, later),
        await grant(NodeId('computer/office/basics'), soon),
        await grant(
          NodeId('tutoring/math/grade-9'),
          now.add(const Duration(days: 2)),
        ),
      ]);
      final expiring = book.expiringWithin(const Duration(days: 7), now);
      expect(expiring.map((g) => g.node.value), [
        'tutoring/math/grade-9',
        'computer/office/basics',
      ]);
    });
  });

  group('ClockGuard', () {
    final t = DateTime.utc(2026, 10, 29, 12);

    test('normal forward time is accepted and remembered', () {
      final check = ClockGuard.check(
        now: t,
        lastSeen: t.subtract(const Duration(days: 1)),
      );
      expect(check.isOk, isTrue);
      expect(check.lastSeen, t);
    });

    test('small backwards corrections are tolerated', () {
      final check = ClockGuard.check(
        now: t.subtract(const Duration(minutes: 20)),
        lastSeen: t,
      );
      expect(check.isOk, isTrue);
      expect(check.lastSeen, t);
    });

    test('turning the clock back is detected', () {
      final check = ClockGuard.check(
        now: t.subtract(const Duration(days: 3)),
        lastSeen: t,
      );
      expect(check.status, ClockStatus.behind);
      expect(check.lastSeen, t);
    });

    test('a clock earlier than a code\'s issue time is detected', () {
      final check = ClockGuard.afterCode(
        now: t.subtract(const Duration(days: 2)),
        issuedAt: t,
      );
      expect(check.status, ClockStatus.behind);
    });

    test('a fresh code re-anchors a clock once set into the future', () {
      final wrongFuture = t.add(const Duration(days: 400));
      expect(ClockGuard.check(now: t, lastSeen: wrongFuture).isOk, isFalse);

      final check = ClockGuard.afterCode(
        now: t,
        issuedAt: t.subtract(const Duration(hours: 3)),
        lastSeen: wrongFuture,
      );
      expect(check.isOk, isTrue);
      expect(check.lastSeen, t);
    });

    test('an old code does not re-anchor the clock', () {
      final check = ClockGuard.afterCode(
        now: t,
        issuedAt: t.subtract(const Duration(days: 10)),
        lastSeen: t.add(const Duration(days: 30)),
      );
      expect(check.isOk, isFalse);
    });
  });

  group('ContentCipher', () {
    const path = 'languages/english/level-1/01-alphabet';

    test('round trip', () async {
      final key = await ContentKeys.forNode(rootKey, unit);
      final plain = utf8.encode('# The Alphabet\nA B C …');
      final blob = await ContentCipher.encrypt(
        key: key,
        path: path,
        plain: plain,
      );
      expect(blob.length, plain.length + 4 + 12 + 16);
      expect(
        await ContentCipher.decrypt(key: key, path: path, blob: blob),
        plain,
      );
    });

    test('fails with another unit\'s key', () async {
      final key = await ContentKeys.forNode(rootKey, unit);
      final otherKey = await ContentKeys.forNode(
        rootKey,
        NodeId('languages/english/level-2'),
      );
      final blob = await ContentCipher.encrypt(
        key: key,
        path: path,
        plain: utf8.encode('secret'),
      );
      await expectLater(
        ContentCipher.decrypt(key: otherKey, path: path, blob: blob),
        throwsA(isA<ContentDecryptionException>()),
      );
    });

    test('fails when the blob is moved to another path', () async {
      final key = await ContentKeys.forNode(rootKey, unit);
      final blob = await ContentCipher.encrypt(
        key: key,
        path: path,
        plain: utf8.encode('secret'),
      );
      await expectLater(
        ContentCipher.decrypt(
          key: key,
          path: 'languages/english/level-1/02-greetings',
          blob: blob,
        ),
        throwsA(isA<ContentDecryptionException>()),
      );
    });

    test('fails on altered or truncated data', () async {
      final key = await ContentKeys.forNode(rootKey, unit);
      final blob = await ContentCipher.encrypt(
        key: key,
        path: path,
        plain: utf8.encode('secret text'),
      );
      final altered = Uint8List.fromList(blob)..[20] ^= 1;
      for (final bad in [altered, blob.sublist(0, 10), Uint8List(0)]) {
        await expectLater(
          ContentCipher.decrypt(key: key, path: path, blob: bad),
          throwsA(isA<ContentDecryptionException>()),
        );
      }
    });
  });

  group('time helpers', () {
    test('end of an institute day in Khartoum time', () {
      expect(
        endOfInstituteDay(DateTime(2026, 11, 3)),
        DateTime.utc(2026, 11, 3, 21, 59, 59),
      );
    });

    test('institute date crosses midnight before UTC does', () {
      expect(
        instituteDate(DateTime.utc(2026, 11, 3, 22, 30)),
        DateTime.utc(2026, 11, 4),
      );
    });
  });
}

/// Pinned output of ContentKeys.forNode(32 zero bytes, languages/english/level-1).
const _unitKeyVector = 'mRfPJDwsuwwNzQ7jiT5Bt/EwvBuOZjMq7eBMfv1GT2w=';
