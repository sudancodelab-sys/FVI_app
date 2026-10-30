import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/admin.dart';
import '../data/catalog.dart';
import '../data/records.dart';
import '../theme.dart';
import '../widgets.dart';
import 'lock.dart';
import 'new_activation.dart';
import 'settings.dart';
import 'students.dart';

/// The four tabs of the designs: home, new activation, students, settings.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.catalog});

  final Catalog catalog;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _tab = 0;
  StudentStatus? _filter;

  void _go(int tab, {StudentStatus? filter}) => setState(() {
        _tab = tab;
        _filter = filter;
      });

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Scaffold(
      body: switch (_tab) {
        0 => _Dashboard(catalog: widget.catalog, go: _go),
        1 => NewActivationScreen(catalog: widget.catalog, onDone: () => _go(2)),
        2 => StudentsScreen(catalog: widget.catalog, filter: _filter),
        _ => const SettingsScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _go,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: t.navHome),
          NavigationDestination(icon: const Icon(Icons.key_outlined), selectedIcon: const Icon(Icons.key_rounded), label: t.navNew),
          NavigationDestination(icon: const Icon(Icons.people_outline_rounded), selectedIcon: const Icon(Icons.people_rounded), label: t.navStudents),
          NavigationDestination(icon: const Icon(Icons.tune_rounded), label: t.navSettings),
        ],
      ),
    );
  }
}

/// A2: what needs the admin's attention today.
class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.catalog, required this.go});

  final Catalog catalog;
  final void Function(int tab, {StudentStatus? filter}) go;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final admin = AdminScope.of(context);
    final now = admin.now;
    final r = admin.records;
    final ending = r.students.where((s) => s.status(now) == StudentStatus.endingSoon).toList()
      ..sort((a, b) => a.soonestEnd(now)!.compareTo(b.soonestEnd(now)!));
    Widget stat(int n, String label, IconData icon, Color color, Color soft, VoidCallback onTap) => Expanded(
          child: Material(
            color: Fvi.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Fvi.line)),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$n', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, height: 1.2)),
                      Text(label, style: const TextStyle(color: Fvi.muted, fontSize: 13.5)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        );
    final backupDays = admin.lastBackup == null ? null : daysLeft(admin.lastBackup!, now);
    return ListView(padding: EdgeInsets.zero, children: [
      Container(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 18, 20, 56),
        decoration: const BoxDecoration(
          color: Fvi.navy,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Image.asset('assets/branding/logo.png', width: 52, height: 52),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.dashboardTitle, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              Text(longDay(now), style: const TextStyle(color: Color(0xFFC9CEF2), fontSize: 14.5)),
            ]),
          ),
        ]),
      ),
      Transform.translate(
        offset: const Offset(0, -40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            Material(
              color: Fvi.orange,
              elevation: 6,
              shadowColor: Fvi.orange.withValues(alpha: .4),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => go(1),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.content_paste_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t.navNew, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                        Text(t.newActivationSub, style: const TextStyle(color: Color(0xFFFFE3D9))),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white, textDirection: TextDirection.ltr),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              stat(r.active(now), t.statActive, Icons.people_outline_rounded, Fvi.navy, Fvi.navySoft,
                  () => go(2, filter: StudentStatus.active)),
              const SizedBox(width: 10),
              stat(r.count(StudentStatus.endingSoon, now), t.statEnding, Icons.schedule_rounded, Fvi.amber, Fvi.amberSoft,
                  () => go(2, filter: StudentStatus.endingSoon)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              stat(r.count(StudentStatus.expired, now), t.statExpired, Icons.lock_outline_rounded, Fvi.red, Fvi.redSoft,
                  () => go(2, filter: StudentStatus.expired)),
              const SizedBox(width: 10),
              stat(r.codesThisMonth(now), t.statCodes, Icons.key_outlined, Fvi.green, Fvi.greenSoft, () => go(2)),
            ]),
            const SizedBox(height: 12),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: Text(t.endingSoon, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  if (ending.isNotEmpty)
                    TextButton(
                      onPressed: () => go(2, filter: StudentStatus.endingSoon),
                      child: Text(t.seeAll, style: const TextStyle(color: Fvi.orange, fontWeight: FontWeight.w700)),
                    ),
                ]),
                if (ending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(t.nothingEnding, style: const TextStyle(color: Fvi.muted)),
                  ),
                for (final s in ending.take(3))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Initial(s.name),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(catalog.label(s.codes.last.grants.first.node), style: const TextStyle(color: Fvi.muted)),
                    trailing: statusBadge(t, s, now),
                    onTap: () => openStudent(context, catalog, s),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              decoration: BoxDecoration(color: Fvi.amberSoft, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                const Icon(Icons.cloud_upload_outlined, color: Fvi.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(backupDays == null ? t.backupNever : t.backupDaysAgo(backupDays),
                      style: const TextStyle(color: Fvi.amber, fontWeight: FontWeight.w700)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Fvi.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => makeBackup(context),
                  child: Text(t.backupNow, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    ]);
  }
}

/// Asks a password and saves the backup where the admin chooses (another
/// computer, the cloud): never only on this phone.
Future<void> makeBackup(BuildContext context) async {
  final t = L10n.of(context);
  final admin = AdminScope.read(context);
  final messenger = ScaffoldMessenger.of(context);
  final password = await askPassword(context);
  if (password == null) return;
  final file = await admin.backup(password);
  final date = admin.now.toIso8601String().substring(0, 10);
  await FilePicker.saveFile(fileName: 'fvi-admin-backup-$date.fvibackup', bytes: file);
  messenger.showSnackBar(SnackBar(content: Text(t.backupMade)));
}
