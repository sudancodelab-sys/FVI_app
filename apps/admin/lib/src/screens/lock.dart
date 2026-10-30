import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../l10n/app_localizations.dart';
import '../data/admin.dart';
import '../data/secrets.dart';
import '../theme.dart';
import '../widgets.dart';

/// A1: the PIN, or the phone's fingerprint. On the first launch it asks for
/// a new PIN twice.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, this.changing = false});

  /// From the settings: choose a new PIN.
  final bool changing;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  static const length = 4;
  var _digits = '';
  String? _first; // a new PIN, typed once
  String? _error;
  var _busy = false;
  final _auth = LocalAuthentication();
  var _canBiometrics = false;

  bool get _creating => widget.changing || !AdminScope.read(context).hasPin;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final can = await _auth.canCheckBiometrics;
      if (!mounted) return;
      setState(() => _canBiometrics = can);
      if (can && !_creating && AdminScope.read(context).biometrics) await _biometrics();
    } on Exception {
      // no fingerprint reader (or the web preview)
    }
  }

  Future<void> _biometrics() async {
    final admin = AdminScope.read(context);
    final t = L10n.of(context);
    try {
      if (await _auth.authenticate(localizedReason: t.lockTitle, biometricOnly: true)) admin.unlockWithBiometrics();
    } on Exception {
      // cancelled: the PIN stays
    }
  }

  Future<void> _type(String d) async {
    if (_busy || _digits.length == length) return;
    setState(() {
      _digits += d;
      _error = null;
    });
    if (_digits.length < length) return;
    final t = L10n.of(context);
    final admin = AdminScope.read(context);
    if (_creating) {
      if (_first == null) {
        setState(() {
          _first = _digits;
          _digits = '';
        });
      } else if (_first == _digits) {
        await admin.setPin(_digits);
        if (widget.changing && mounted) Navigator.of(context).pop();
      } else {
        setState(() {
          _first = null;
          _digits = '';
          _error = t.pinMismatch;
        });
      }
      return;
    }
    setState(() => _busy = true);
    final ok = await admin.unlock(_digits);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) {
        _digits = '';
        _error = t.wrongPin;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final admin = AdminScope.of(context);
    final title = !_creating ? t.lockTitle : (_first == null ? t.createPinTitle : t.confirmPinTitle);
    final sub = _creating ? t.createPinSub : (_canBiometrics && admin.biometrics ? t.lockSub : t.lockSubPin);
    Widget key(Widget child, VoidCallback? onTap, {String? label, bool round = false}) => Semantics(
          button: true,
          label: label,
          child: InkResponse(
            onTap: onTap,
            radius: 44,
            child: Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: round ? BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08)) : null,
              child: child,
            ),
          ),
        );
    Text digit(String d) => Text(d, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700));
    return Scaffold(
      backgroundColor: Fvi.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Image.asset('assets/branding/logo.png', width: 120, height: 120),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                decoration: BoxDecoration(color: Fvi.orange.withValues(alpha: .18), borderRadius: BorderRadius.circular(99)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFFFFB39C)),
                  const SizedBox(width: 6),
                  Text(t.adminBadge, style: const TextStyle(color: Color(0xFFFFB39C), fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              Text(sub, style: const TextStyle(color: Color(0xFFC9CEF2), fontSize: 15)),
              const SizedBox(height: 22),
              Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 9),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _digits.length ? Colors.white : Colors.transparent,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
              ]),
              SizedBox(
                height: 34,
                child: Center(
                  child: Text(_error ?? '', style: const TextStyle(color: Color(0xFFFFB39C), fontWeight: FontWeight.w700)),
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Column(children: [
                  for (final row in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        for (final d in row) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: key(digit(d), () => _type(d), round: true)),
                      ]),
                    ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: key(Icon(Icons.fingerprint, color: _canBiometrics && admin.biometrics && !_creating ? Colors.white : Colors.white24, size: 32),
                          _canBiometrics && admin.biometrics && !_creating ? _biometrics : null, label: t.useBiometrics),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: key(digit('0'), () => _type('0'), round: true)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: key(const Icon(Icons.backspace_outlined, color: Colors.white, size: 28),
                          () => setState(() => _digits = _digits.isEmpty ? '' : _digits.substring(0, _digits.length - 1)),
                          label: t.delete),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The first launch of a production build: make the institute's keys, or
/// bring them from the backup of the old admin phone.
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final admin = AdminScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 20),
          Center(child: Image.asset('assets/branding/logo.png', width: 130, height: 130)),
          const SizedBox(height: 16),
          Text(t.setupTitle, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Fvi.navy)),
          const SizedBox(height: 8),
          Text(t.setupText, textAlign: TextAlign.center, style: const TextStyle(color: Fvi.muted, height: 1.7)),
          const SizedBox(height: 28),
          FilledButton.icon(
            style: bigButton(Fvi.navy),
            onPressed: admin.createKeys,
            icon: const Icon(Icons.key_rounded),
            label: Text(t.createKeys),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), foregroundColor: Fvi.navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            onPressed: () => restoreBackup(context),
            icon: const Icon(Icons.settings_backup_restore_rounded),
            label: Text(t.restore, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}

/// Picks a backup file, asks its password and brings everything back.
Future<void> restoreBackup(BuildContext context) async {
  final t = L10n.of(context);
  final admin = AdminScope.read(context);
  final messenger = ScaffoldMessenger.of(context);
  final file = await FilePicker.pickFile();
  if (file == null || !context.mounted) return;
  final bytes = await file.xFile.readAsBytes();
  if (!context.mounted) return;
  final password = await askPassword(context, warning: t.restoreWarning);
  if (password == null) return;
  try {
    await admin.restore(bytes, password);
    messenger.showSnackBar(SnackBar(content: Text(t.restoreDone)));
  } on BackupException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.wrongPassword ? t.wrongPassword : t.notBackup)));
  }
}

/// The password of a backup; at least 8 characters.
Future<String?> askPassword(BuildContext context, {String? warning}) {
  final t = L10n.of(context);
  final field = TextEditingController();
  String? error;
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(t.backupPassword),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (warning != null) ...[
            Text(warning, style: const TextStyle(color: Fvi.red, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: field,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(helperText: t.passwordHint, helperMaxLines: 3, errorText: error),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancel)),
          FilledButton(
            onPressed: () => field.text.length < 8
                ? setState(() => error = t.passwordTooShort)
                : Navigator.of(context).pop(field.text),
            child: Text(t.save),
          ),
        ],
      ),
    ),
  );
}
