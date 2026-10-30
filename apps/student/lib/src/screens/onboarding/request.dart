import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fvi_core/fvi_core.dart' show ActivationCode;
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../activation/activation.dart';
import '../../theme.dart';

/// Opens WhatsApp with the activation request for [levelId] (named
/// [levelName]), written in the app's language (docs/REQUIREMENTS.md 5.2).
/// Returns whether WhatsApp opened.
Future<bool> sendRequest(BuildContext context, {required String levelId, required String levelName}) async {
  final t = L10n.of(context);
  final activation = ActivationScope.read(context);
  final p = activation.profile!;
  final message = [
    t.messageHeading,
    t.messageName(p.name),
    t.messagePhone(p.phone),
    t.messageLevel(t.levelOption(t.courseEnglish, levelName)),
    t.messageDevice(activation.deviceCode),
    '',
    activation.requestToken(level: levelId),
  ].join('\n');
  var opened = false;
  try {
    opened = await launchUrl(activation.whatsappUri(message), mode: LaunchMode.externalApplication);
  } on PlatformException {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.whatsappFailed)));
  }
  return opened;
}

/// The field for an activation code, with Paste and Activate. It looks in
/// what the student copied when it opens and whenever the app comes back,
/// so copying the institute's message is enough (docs/REQUIREMENTS.md 3.1).
class CodeEntry extends StatefulWidget {
  const CodeEntry({super.key, this.onActivated});

  final VoidCallback? onActivated;

  @override
  State<CodeEntry> createState() => _CodeEntryState();
}

class _CodeEntryState extends State<CodeEntry> with WidgetsBindingObserver {
  final _field = TextEditingController();
  String? _problem;
  var _found = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lookInClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _field.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _lookInClipboard();
  }

  Future<String?> _clipboard() async {
    try {
      return (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    } on PlatformException {
      return null; // a phone that does not let apps read the clipboard
    }
  }

  Future<void> _lookInClipboard() async {
    final text = await _clipboard();
    if (!mounted || text == null || ActivationCode.findToken(text) == null) return;
    setState(() {
      _field.text = text;
      _found = true;
      _problem = null;
    });
  }

  Future<void> _paste() async {
    final text = await _clipboard();
    if (text != null) setState(() => _field.text = text);
  }

  Future<void> _activate() async {
    final t = L10n.of(context);
    setState(() => _busy = true);
    final problem = await ActivationScope.read(context).apply(_field.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _found = false;
      _problem = switch (problem) {
        null => null,
        CodeProblem.noCode => t.problemNoCode,
        CodeProblem.otherInstitute => t.problemOtherInstitute,
        CodeProblem.altered => t.problemAltered,
        CodeProblem.otherPhone => t.problemOtherPhone,
        CodeProblem.clockBehind => t.problemClock,
      };
    });
    if (problem == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.activated)));
      widget.onActivated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: _field,
        minLines: 1,
        maxLines: 3,
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontFamily: Fvi.english, fontSize: 13),
        onChanged: (_) => setState(() => _problem = null),
        decoration: fieldDecoration(
          hint: t.pasteHere,
          icon: Icons.key_rounded,
          suffix: IconButton(tooltip: t.paste, onPressed: _paste, icon: const Icon(Icons.content_paste_rounded)),
        ),
      ),
      if (_found) ...[
        const SizedBox(height: 6),
        Text(t.codeFound, style: const TextStyle(fontSize: 13.5, color: Fvi.green, fontWeight: FontWeight.w600)),
      ],
      if (_problem != null) ...[
        const SizedBox(height: 6),
        Text(_problem!, style: const TextStyle(fontSize: 13.5, color: Fvi.red, fontWeight: FontWeight.w600)),
      ],
      const SizedBox(height: 14),
      FilledButton(
        style: primaryButton(Fvi.navy),
        onPressed: _busy || _field.text.trim().isEmpty ? null : _activate,
        child: Text(t.activate),
      ),
    ]);
  }
}

/// A field as in the approved design: white, rounded, with its icon.
InputDecoration fieldDecoration({String? hint, required IconData icon, Widget? suffix}) => InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Fvi.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: Fvi.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Fvi.line)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Fvi.line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Fvi.navy, width: 2)),
    );

ButtonStyle primaryButton(Color color) => FilledButton.styleFrom(
      backgroundColor: color,
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    );
