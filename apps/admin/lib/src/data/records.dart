import 'package:fvi_core/fvi_core.dart';

/// One grant of a code: a node, open until a time (UTC).
class GrantRecord {
  GrantRecord(this.node, this.until);

  GrantRecord.fromJson(Map<String, Object?> json)
      : node = NodeId(json['node'] as String),
        until = fromEpochSeconds(json['until'] as int);

  final NodeId node;
  final DateTime until;

  Map<String, Object?> toJson() => {'node': node.value, 'until': toEpochSeconds(until)};
}

/// A code the admin issued, kept so it can be sent again and matched to what
/// a student reports.
class CodeRecord {
  CodeRecord({required this.id, required this.issuedAt, required this.grants, required this.token});

  CodeRecord.fromJson(Map<String, Object?> json)
      : id = json['id'] as String,
        issuedAt = fromEpochSeconds(json['issued'] as int),
        grants = [for (final g in json['grants'] as List) GrantRecord.fromJson(g as Map<String, Object?>)],
        token = json['token'] as String;

  final String id;
  final DateTime issuedAt;
  final List<GrantRecord> grants;
  final String token;

  Map<String, Object?> toJson() => {
        'id': id,
        'issued': toEpochSeconds(issuedAt),
        'grants': [for (final g in grants) g.toJson()],
        'token': token,
      };
}

enum StudentStatus { active, endingSoon, expired, none }

/// A student, known by the phone that asked: the device key binds every code.
class StudentRecord {
  StudentRecord({
    required this.devicePublicKey,
    required this.deviceCode,
    required this.name,
    required this.phone,
    required this.firstSeen,
    this.requested,
    List<CodeRecord>? codes,
  }) : codes = codes ?? [];

  StudentRecord.fromJson(Map<String, Object?> json)
      : devicePublicKey = json['device'] as String,
        deviceCode = json['deviceCode'] as String,
        name = json['name'] as String,
        phone = json['phone'] as String,
        firstSeen = fromEpochSeconds(json['firstSeen'] as int),
        requested = json['requested'] == null ? null : NodeId(json['requested'] as String),
        codes = [for (final c in json['codes'] as List) CodeRecord.fromJson(c as Map<String, Object?>)];

  /// The device's X25519 public key, base64.
  final String devicePublicKey;
  final String deviceCode;
  String name;
  String phone;
  final DateTime firstSeen;
  NodeId? requested;
  final List<CodeRecord> codes;

  Map<String, Object?> toJson() => {
        'device': devicePublicKey,
        'deviceCode': deviceCode,
        'name': name,
        'phone': phone,
        'firstSeen': toEpochSeconds(firstSeen),
        'requested': requested?.value,
        'codes': [for (final c in codes) c.toJson()],
      };

  /// Each node ever granted, with the latest time it is open until (codes add up).
  Map<NodeId, DateTime> get openUntil {
    final out = <NodeId, DateTime>{};
    for (final g in codes.expand((c) => c.grants)) {
      if (out[g.node] == null || g.until.isAfter(out[g.node]!)) out[g.node] = g.until;
    }
    return out;
  }

  /// The soonest end among what is open at [now], or null if nothing is.
  DateTime? soonestEnd(DateTime now) {
    final open = openUntil.values.where((u) => u.isAfter(now));
    return open.isEmpty ? null : open.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  StudentStatus status(DateTime now, {Duration soon = Records.soon}) {
    if (codes.isEmpty) return StudentStatus.none;
    final end = soonestEnd(now);
    if (end == null) return StudentStatus.expired;
    return end.difference(now) <= soon ? StudentStatus.endingSoon : StudentStatus.active;
  }
}

/// What the admin should know before issuing a code to a request
/// (docs/REQUIREMENTS.md 4, "automatic alerts").
sealed class Familiar {}

/// This phone asked before: its student is in the records.
class KnownDevice extends Familiar {
  KnownDevice(this.student);

  final StudentRecord student;
}

/// The same name or number with another phone: most likely the app was
/// installed again, or the student changed phones.
class SameNameOrPhone extends Familiar {
  SameNameOrPhone(this.students);

  final List<StudentRecord> students;
}

/// A phone never seen before.
class NewDevice extends Familiar {}

/// Everyone the admin has issued codes to.
class Records {
  Records([List<StudentRecord>? students]) : students = students ?? [];

  Records.fromJson(Map<String, Object?> json)
      : students = [for (final s in json['students'] as List) StudentRecord.fromJson(s as Map<String, Object?>)];

  /// "Ending soon" on the dashboard and in the list: the students' own warning comes 7 days before.
  static const soon = Duration(days: 7);

  final List<StudentRecord> students;

  Map<String, Object?> toJson() => {'students': [for (final s in students) s.toJson()]};

  StudentRecord? byDevice(String devicePublicKey) =>
      students.where((s) => s.devicePublicKey == devicePublicKey).firstOrNull;

  Familiar familiar({required String devicePublicKey, required String name, required String phone}) {
    final known = byDevice(devicePublicKey);
    if (known != null) return KnownDevice(known);
    final digits = _digits(phone);
    final same = students
        .where((s) => s.name.trim() == name.trim() || (digits.isNotEmpty && _digits(s.phone) == digits))
        .toList();
    return same.isEmpty ? NewDevice() : SameNameOrPhone(same);
  }

  int count(StudentStatus status, DateTime now) => students.where((s) => s.status(now) == status).length;

  /// Students with something open (ending soon or not).
  int active(DateTime now) =>
      students.where((s) => {StudentStatus.active, StudentStatus.endingSoon}.contains(s.status(now))).length;

  /// Codes issued in [now]'s calendar month, in the institute's time zone.
  int codesThisMonth(DateTime now) {
    final month = instituteDate(now);
    return students.expand((s) => s.codes).where((c) {
      final d = instituteDate(c.issuedAt);
      return d.year == month.year && d.month == month.month;
    }).length;
  }

  /// Search by name or phone number.
  List<StudentRecord> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return students;
    final digits = _digits(q);
    return students
        .where((s) => s.name.toLowerCase().contains(q) || (digits.isNotEmpty && _digits(s.phone).contains(digits)))
        .toList();
  }

  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');
}
