import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/admin.dart';
import '../data/catalog.dart';
import '../data/records.dart';
import '../theme.dart';
import '../widgets.dart';
import 'new_activation.dart';

/// A4: every student, searched by name or number, filtered by state.
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key, required this.catalog, this.filter});

  final Catalog catalog;
  final StudentStatus? filter;

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  late StudentStatus? _filter = widget.filter;
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final admin = AdminScope.of(context);
    final now = admin.now;
    final r = admin.records;
    final shown = r.search(_query).where((s) => switch (_filter) {
          null => true,
          StudentStatus.active => {StudentStatus.active, StudentStatus.endingSoon}.contains(s.status(now)),
          final f => s.status(now) == f,
        }).toList()
      ..sort((a, b) => b.codes.last.issuedAt.compareTo(a.codes.last.issuedAt));
    Widget chip(StudentStatus? f, String label) =>
        choice(label, selected: _filter == f, onSelected: () => setState(() => _filter = f));
    return Scaffold(
      appBar: AppBar(
        title: Text.rich(TextSpan(children: [
          TextSpan(text: t.studentsTitle),
          TextSpan(text: ' (${r.students.length})', style: const TextStyle(fontSize: 15, color: Fvi.muted)),
        ])),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: t.search,
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Fvi.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Fvi.line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Fvi.line)),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          chip(null, t.filterAll),
          chip(StudentStatus.active, t.filterActive(r.active(now))),
          chip(StudentStatus.endingSoon, t.filterSoon(r.count(StudentStatus.endingSoon, now))),
          chip(StudentStatus.expired, t.filterExpired(r.count(StudentStatus.expired, now))),
        ]),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(r.students.isEmpty ? t.noStudents : t.noMatch,
                textAlign: TextAlign.center, style: const TextStyle(color: Fvi.muted)),
          )
        else
          Panel(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: Fvi.line),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Initial(shown[i].name),
                  title: Text(shown[i].name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  subtitle: Text(_summary(t, widget.catalog, shown[i], r), style: const TextStyle(color: Fvi.muted)),
                  trailing: statusBadge(t, shown[i], now),
                  onTap: () => openStudent(context, widget.catalog, shown[i]),
                ),
              ],
            ]),
          ),
      ]),
    );
  }
}

/// What a student has: one node's name, or the first and how many more; and,
/// on a line of its own, the phone's code when another phone has the same
/// name (a reinstall).
String _summary(L10n t, Catalog catalog, StudentRecord s, Records records) {
  final nodes = s.openUntil.keys.toList()..sort();
  final what = nodes.length == 1 ? catalog.label(nodes.single) : '${catalog.label(nodes.first)} + ${nodes.length - 1}';
  final twin = records.students.any((o) => o != s && o.name.trim() == s.name.trim());
  return twin ? '$what\n${t.deviceChip(s.deviceCode)}' : what;
}

void openStudent(BuildContext context, Catalog catalog, StudentRecord student) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => StudentScreen(catalog: catalog, student: student)));

/// A5: one student's codes, and renewing, adding or resending.
class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key, required this.catalog, required this.student});

  final Catalog catalog;
  final StudentRecord student;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final admin = AdminScope.of(context);
    final now = admin.now;
    final s = student;
    final grants = [
      for (final c in s.codes.reversed)
        for (final g in c.grants) (c, g),
    ];
    final last = s.codes.last;
    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(color: Fvi.navyTint, borderRadius: BorderRadius.circular(99)),
          child: Text(text, style: const TextStyle(color: Fvi.navy, fontWeight: FontWeight.w700, fontSize: 13)),
        );
    return Scaffold(
      appBar: AppBar(title: Text(t.studentTitle)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        Panel(
          child: Column(children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Fvi.navy, shape: BoxShape.circle),
              child: Text(String.fromCharCode(s.name.trim().runes.first),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 10),
            Text(s.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(s.phone, textDirection: TextDirection.ltr,
                style: const TextStyle(color: Fvi.muted, fontFamily: Fvi.english)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              chip(t.deviceChip(s.deviceCode)),
              chip(t.since(day(s.firstSeen))),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t.activations, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final (code, g) in grants)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Icon(Icons.circle, size: 12, color: g.until.isAfter(now) && !_renewed(g) ? Fvi.orange : Fvi.line),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(catalog.label(g.node), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                      Text(t.period(day(code.issuedAt), day(g.until)), style: const TextStyle(color: Fvi.muted, fontSize: 13.5)),
                    ]),
                  ),
                  _renewed(g)
                      ? Pill(t.renewedTag, color: Fvi.muted, background: Fvi.navyTint)
                      : g.until.isAfter(now)
                      ? Pill(t.daysLeft(daysLeft(now, g.until)),
                          color: daysLeft(now, g.until) <= 7 ? Fvi.amber : Fvi.green,
                          background: daysLeft(now, g.until) <= 7 ? Fvi.amberSoft : Fvi.greenSoft)
                      : Pill(t.ended, color: Fvi.muted, background: Fvi.navyTint),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          style: bigButton(Fvi.navy),
          onPressed: () => _renew(context),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(t.renew(catalog.label(last.grants.first.node)), overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            foregroundColor: Fvi.navy,
            backgroundColor: Fvi.surface,
            side: const BorderSide(color: Fvi.line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => NewActivationScreen(catalog: catalog, student: s))),
          icon: const Icon(Icons.add_rounded),
          label: Text(t.moreContent, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () => openWhatsapp(context, Admin.whatsappTo(s.phone, Admin.message(last.token))),
          icon: const Icon(Icons.chat_outlined, color: Fvi.navy),
          label: Text(t.resendLast, style: const TextStyle(color: Fvi.navy, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ]),
    );
  }

  /// A later code opens this grant's node (or more) for longer.
  bool _renewed(GrantRecord g) =>
      student.codes.any((c) => c.grants.any((o) => o.node.isAncestorOrSelfOf(g.node) && o.until.isAfter(g.until)));

  /// The nodes of the last code again, from where they end (or today).
  Future<void> _renew(BuildContext context) async {
    final t = L10n.of(context);
    final admin = AdminScope.read(context);
    final nodes = [for (final g in student.codes.last.grants) g.node];
    final from = nodes.map((n) => student.openUntil[n]!).reduce((a, b) => a.isBefore(b) ? a : b);
    final months = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(t.renewTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
          for (final (m, label) in [(1, t.oneMonth), (2, t.twoMonths), (3, t.threeMonths)])
            ListTile(
              title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(t.endsOn(day(admin.until(months: m, from: from)))),
              onTap: () => Navigator.of(context).pop(m),
            ),
        ]),
      ),
    );
    if (months == null || !context.mounted) return;
    final issued = await admin.issueAgain(student, nodes, admin.until(months: months, from: from));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.issued)));
    await openWhatsapp(context, Admin.whatsappTo(issued.student.phone, Admin.message(issued.code.token)));
  }
}
