import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fvi_core/fvi_core.dart';

import '../../l10n/app_localizations.dart';
import '../data/admin.dart';
import '../data/catalog.dart';
import '../data/records.dart';
import '../theme.dart';
import '../widgets.dart';

/// A3: the student's WhatsApp message in, a code out. The admin pastes the
/// message, checks who it is, chooses what opens and for how long, and the
/// code goes back on WhatsApp. With [student], it opens more content for a
/// student already in the records.
class NewActivationScreen extends StatefulWidget {
  const NewActivationScreen({super.key, required this.catalog, this.onDone, this.student});

  final Catalog catalog;
  final VoidCallback? onDone;
  final StudentRecord? student;

  @override
  State<NewActivationScreen> createState() => _NewActivationScreenState();
}

class _NewActivationScreenState extends State<NewActivationScreen> {
  final _field = TextEditingController();
  ActivationRequest? _request;
  String? _deviceCode;
  var _unreadable = false;
  final _chosen = <NodeId>{};
  var _months = 1;
  DateTime? _customDay;
  var _busy = false;
  var _tried = false;

  Future<void> _read(String text) async {
    ActivationRequest? request;
    try {
      request = ActivationRequest.findIn(text);
    } on FormatException {
      request = null;
    }
    final code = await request?.deviceCode();
    if (!mounted) return;
    // Show the start of the message (the student's name), not the end of the code.
    if (request != null) _field.selection = const TextSelection.collapsed(offset: 0);
    setState(() {
      _request = request;
      _deviceCode = code;
      _unreadable = text.trim().isNotEmpty && request == null;
      _chosen
        ..clear()
        ..addAll([?request?.requestedNode]);
    });
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    _field.text = text;
    await _read(text);
  }

  DateTime _until(Admin admin) => _customDay != null ? endOfInstituteDay(_customDay!) : admin.until(months: _months);

  Future<void> _issue() async {
    final admin = AdminScope.read(context);
    final t = L10n.of(context);
    setState(() => _tried = true);
    if (_chosen.isEmpty) return;
    setState(() => _busy = true);
    final nodes = _chosen.toList()..sort();
    final issued = widget.student != null
        ? await admin.issueAgain(widget.student!, nodes, _until(admin))
        : await admin.issue(_request!, nodes, _until(admin));
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.issued)));
    await openWhatsapp(context, Admin.whatsappTo(issued.student.phone, Admin.message(issued.code.token)));
    if (!mounted) return;
    if (widget.student != null) {
      Navigator.of(context).pop();
    } else {
      _field.clear();
      setState(() {
        _request = null;
        _chosen.clear();
        _tried = false;
      });
      widget.onDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final admin = AdminScope.of(context);
    final student = widget.student;
    final ready = student != null || _request != null;
    return Scaffold(
      appBar: AppBar(title: Text(student == null ? t.navNew : t.moreContent)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        if (student == null) ...[
          TextField(
            controller: _field,
            minLines: 2,
            maxLines: 4,
            onChanged: _read,
            decoration: InputDecoration(
              hintText: t.pasteRequest,
              filled: true,
              fillColor: Fvi.surface,
              prefixIcon: const Icon(Icons.chat_outlined),
              suffixIcon: IconButton(tooltip: t.paste, onPressed: _paste, icon: const Icon(Icons.content_paste_rounded)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Fvi.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Fvi.line)),
              errorText: _unreadable ? t.noRequest : null,
              errorMaxLines: 3,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (ready) ...[
          _StudentCard(
            name: student?.name ?? _request!.name,
            phone: student?.phone ?? _request!.phone,
            deviceCode: student?.deviceCode ?? _deviceCode ?? '',
            familiar: student != null
                ? KnownDevice(student)
                : admin.records.familiar(
                    devicePublicKey: base64.encode(_request!.devicePublicKey),
                    name: _request!.name,
                    phone: _request!.phone),
            fromWhatsapp: student == null,
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(t.whatOpens, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              for (final root in widget.catalog.roots)
                _Tree(
                  catalog: widget.catalog,
                  node: root,
                  chosen: _chosen,
                  requested: student?.requested ?? _request?.requestedNode,
                  onChanged: () => setState(() {}),
                ),
              if (_tried && _chosen.isEmpty)
                Text(t.chooseSomething, style: const TextStyle(color: Fvi.red, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(t.duration, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final (months, label) in [(1, t.oneMonth), (2, t.twoMonths), (3, t.threeMonths)])
                  choice(
                    label,
                    selected: _customDay == null && _months == months,
                    onSelected: () => setState(() {
                      _months = months;
                      _customDay = null;
                    }),
                  ),
                choice(
                  t.customDate,
                  icon: Icons.calendar_month_outlined,
                  selected: _customDay != null,
                  onSelected: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: admin.now,
                      lastDate: admin.now.add(const Duration(days: 730)),
                      initialDate: _until(admin),
                    );
                    if (picked != null) setState(() => _customDay = DateTime.utc(picked.year, picked.month, picked.day));
                  },
                ),
              ]),
              const SizedBox(height: 10),
              Text(t.endsOn(day(_until(admin))), style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: bigButton(Fvi.whatsapp),
            onPressed: _busy ? null : _issue,
            icon: const Icon(Icons.send_rounded, textDirection: TextDirection.ltr),
            label: Text(t.issueAndSend),
          ),
        ],
      ]),
    );
  }
}

/// The student's details as read from the request, and what the records say.
class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.name,
    required this.phone,
    required this.deviceCode,
    required this.familiar,
    required this.fromWhatsapp,
  });

  final String name;
  final String phone;
  final String deviceCode;
  final Familiar familiar;
  final bool fromWhatsapp;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    Widget row(String label, String value, {bool latin = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Text(label, style: const TextStyle(color: Fvi.muted)),
            const SizedBox(width: 16),
            const Spacer(),
            Flexible(
              child: Text(value,
                  textDirection: latin ? TextDirection.ltr : null,
                  style: TextStyle(fontWeight: FontWeight.w800, fontFamily: latin ? Fvi.english : null, letterSpacing: latin ? 1 : 0)),
            ),
          ]),
        );
    final (icon, text, color, soft) = switch (familiar) {
      NewDevice() => (Icons.check_rounded, t.newDevice, Fvi.green, Fvi.greenSoft),
      KnownDevice(:final student) => (Icons.history_rounded, t.knownDevice(student.name), Fvi.navy, Fvi.navySoft),
      SameNameOrPhone(:final students) =>
        (Icons.warning_amber_rounded, t.sameNameOrPhone(students.map((s) => s.name).join('، ')), Fvi.amber, Fvi.amberSoft),
    };
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(t.studentData, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          if (fromWhatsapp)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Fvi.navySoft, borderRadius: BorderRadius.circular(99)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.chat_outlined, size: 15, color: Fvi.navy),
                const SizedBox(width: 4),
                Text(t.readFromWhatsapp, style: const TextStyle(color: Fvi.navy, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ]),
            ),
        ]),
        const SizedBox(height: 6),
        row(t.name, name),
        row(t.phone, phone, latin: true),
        row(t.deviceCode, deviceCode, latin: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700))),
          ]),
        ),
      ]),
    );
  }
}

/// The content tree with its checkboxes. Choosing a node opens everything
/// under it, as one grant (docs/REQUIREMENTS.md 5.4): the whole course is
/// the course's node, and a level added to it later opens too.
class _Tree extends StatelessWidget {
  const _Tree({
    required this.catalog,
    required this.node,
    required this.chosen,
    required this.requested,
    required this.onChanged,
    this.depth = 0,
  });

  final Catalog catalog;
  final CatalogNode node;
  final Set<NodeId> chosen;
  final NodeId? requested;
  final VoidCallback onChanged;
  final int depth;

  bool get _covered => node.id.lineage.any(chosen.contains);
  bool get _partly => !_covered && chosen.any((c) => node.id.isAncestorOrSelfOf(c));

  void _toggle() {
    if (_covered) {
      // Unchoosing a node under a chosen one keeps the rest of that one chosen.
      final top = node.id.lineage.firstWhere(chosen.contains);
      chosen.remove(top);
      _openDown(catalog[top]!, node.id);
    } else {
      chosen
        ..removeWhere((c) => node.id.isAncestorOrSelfOf(c))
        ..add(node.id);
    }
    onChanged();
  }

  /// Chooses the children of [from] on the way down to [to], except [to].
  void _openDown(CatalogNode from, NodeId to) {
    for (final child in from.children) {
      if (child.id == to) continue;
      if (child.id.isAncestorOrSelfOf(to)) {
        _openDown(child, to);
      } else {
        chosen.add(child.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      InkWell(
        onTap: _toggle,
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: depth * 24.0, top: 2, bottom: 2),
          child: Row(children: [
            Checkbox(value: _covered ? true : (_partly ? null : false), tristate: true, onChanged: (_) => _toggle()),
            Expanded(
              // The tag goes under the name, which keeps a level's name on one line.
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(node.name,
                    style: TextStyle(
                        fontWeight: depth < 2 ? FontWeight.w800 : FontWeight.w700,
                        fontSize: depth < 2 ? 16 : 15.5,
                        fontFamily: depth == 2 ? Fvi.english : null)),
                if (node.id == requested)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    child: Pill(t.requestedTag, color: Fvi.orange, background: Fvi.orangeSoft),
                  ),
              ]),
            ),
          ]),
        ),
      ),
      for (final child in node.children)
        _Tree(
            catalog: catalog,
            node: child,
            chosen: chosen,
            requested: requested,
            onChanged: onChanged,
            depth: depth + 1),
    ]);
  }
}
