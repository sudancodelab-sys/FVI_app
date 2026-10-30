import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../activation/activation.dart';
import '../../activation/issuer.dart';
import '../../content/model.dart';
import '../../content/repository.dart';
import '../../language.dart';
import '../../theme.dart';
import 'request.dart';

/// The first launch, as in the approved design (docs/design/screens/
/// 1-student-onboarding.png): the welcome and the app's language, the
/// student's details and the request on WhatsApp, then the code.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.content});

  final ContentRepository content;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late var _step = ActivationScope.read(context).profile == null ? 0 : 2;

  void _go(int step) => setState(() => _step = step);

  @override
  Widget build(BuildContext context) => switch (_step) {
        0 => _Welcome(onContinue: () => _go(1)),
        1 => _Request(content: widget.content, onBack: () => _go(0), onSent: () => _go(2), onHaveCode: () => _go(2)),
        _ => _Waiting(onBack: () => _go(1), onSendAgain: () => _go(1)),
      };
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final language = AppLanguage.of(context);
    Widget option(Locale locale, String badge, String name, String sub, TextDirection direction) {
      final selected = language.locale == locale;
      return Material(
        color: Fvi.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: selected ? Fvi.navy : Fvi.line, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => language.choose(locale),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Fvi.navy, borderRadius: BorderRadius.circular(12)),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              const SizedBox(width: 14),
              // Each language is named in its own script and direction.
              Expanded(
                child: Directionality(
                  textDirection: direction,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: TextStyle(fontFamily: direction == TextDirection.rtl ? Fvi.arabic : Fvi.english,
                        fontWeight: FontWeight.w700, fontSize: 16.5, color: Fvi.text)),
                    Text(sub, style: TextStyle(fontFamily: direction == TextDirection.rtl ? Fvi.arabic : Fvi.english,
                        fontSize: 13, color: Fvi.muted)),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? Fvi.navy : Fvi.line),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Fvi.bg,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(22, 28, 22, 22), children: [
          Center(child: Image.asset('assets/branding/logo.png', width: 170, height: 170)),
          const SizedBox(height: 14),
          Text(t.welcomeName, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Fvi.navy)),
          Text(t.welcomeNameSub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Fvi.muted)),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(color: Fvi.orangeSoft, borderRadius: BorderRadius.circular(99)),
              child: Text(t.welcomeTagline,
                  style: const TextStyle(color: Fvi.orange, fontWeight: FontWeight.w700, fontSize: 14.5)),
            ),
          ),
          const SizedBox(height: 36),
          Text(t.chooseLanguage, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Fvi.text)),
          const SizedBox(height: 10),
          option(AppLanguage.english, 'En', t.languageEnglish, t.languageEnglishSub, TextDirection.ltr),
          const SizedBox(height: 10),
          option(AppLanguage.arabic, 'ع', t.languageArabic, t.languageArabicSub, TextDirection.rtl),
          const SizedBox(height: 30),
          FilledButton(style: primaryButton(Fvi.navy), onPressed: onContinue, child: Text(t.continueButton)),
          const SizedBox(height: 10),
          Text(t.versionN(appVersion), textAlign: TextAlign.center, style: const TextStyle(color: Fvi.muted, fontSize: 13)),
        ]),
      ),
    );
  }
}

class _Request extends StatefulWidget {
  const _Request({required this.content, required this.onBack, required this.onSent, required this.onHaveCode});

  final ContentRepository content;
  final VoidCallback onBack;
  final VoidCallback onSent;
  final VoidCallback onHaveCode;

  @override
  State<_Request> createState() => _RequestState();
}

class _RequestState extends State<_Request> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _level;
  late final Future<List<LevelSummary>> _levels = widget.content.levels();
  var _tried = false;

  @override
  void initState() {
    super.initState();
    final profile = ActivationScope.read(context).profile;
    if (profile != null) {
      _name.text = profile.name;
      _phone.text = profile.phone;
      _level = profile.level;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send(List<LevelSummary> levels) async {
    setState(() => _tried = true);
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty || _level == null) return;
    await ActivationScope.read(context)
        .saveProfile(StudentProfile(name: _name.text.trim(), phone: _phone.text.trim(), level: _level!));
    if (!mounted) return;
    final level = levels.firstWhere((l) => l.id == _level);
    if (await sendRequest(context, levelId: level.id, levelName: level.name)) widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final activation = ActivationScope.of(context);
    String? need(bool missing, String message) => _tried && missing ? message : null;
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Fvi.text)),
        );
    return Scaffold(
      backgroundColor: Fvi.bg,
      appBar: AppBar(backgroundColor: Fvi.bg, title: Text(t.requestTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Fvi.navy)),
          leading: BackButton(onPressed: widget.onBack)),
      body: FutureBuilder(
        future: _levels,
        builder: (context, snap) {
          final levels = snap.data ?? const <LevelSummary>[];
          return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
            Text(t.requestIntro, style: const TextStyle(color: Fvi.muted, fontSize: 15, height: 1.6)),
            label(t.fullName),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              decoration: fieldDecoration(icon: Icons.person_outline_rounded)
                  .copyWith(errorText: need(_name.text.trim().isEmpty, t.nameNeeded)),
            ),
            label(t.phoneNumber),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')), LengthLimitingTextInputFormatter(30)],
              decoration: fieldDecoration(icon: Icons.phone_outlined)
                  .copyWith(errorText: need(_phone.text.trim().isEmpty, t.phoneNeeded)),
            ),
            label(t.yourLevel),
            DropdownButtonFormField<String>(
              initialValue: _level,
              isExpanded: true,
              hint: Text(t.yourLevel), // also its name for screen readers
              decoration: fieldDecoration(icon: Icons.school_outlined)
                  .copyWith(errorText: need(_level == null, t.levelNeeded)),
              items: [
                for (final l in levels)
                  DropdownMenuItem(value: l.id, child: Text(t.levelOption(t.courseEnglish, l.name))),
              ],
              onChanged: (v) => setState(() => _level = v),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Fvi.navyTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Fvi.line),
              ),
              child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: Fvi.navy, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.shield_outlined, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.deviceCodeLabel, style: const TextStyle(color: Fvi.muted, fontSize: 13.5)),
                    Text(activation.deviceCode, textDirection: TextDirection.ltr,
                        style: const TextStyle(fontFamily: Fvi.english, fontSize: 22, fontWeight: FontWeight.w800,
                            letterSpacing: 2, color: Fvi.navy)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Text(t.deviceCodeNote, style: const TextStyle(color: Fvi.muted, fontSize: 13.5)),
            const SizedBox(height: 26),
            FilledButton.icon(
              style: primaryButton(const Color(0xFF1FA855)),
              onPressed: levels.isEmpty ? null : () => _send(levels),
              icon: const Icon(Icons.chat_rounded),
              label: Text(t.requestOnWhatsapp),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onHaveCode,
              child: Text(t.haveCode, style: const TextStyle(fontWeight: FontWeight.w700, color: Fvi.navy, fontSize: 15)),
            ),
          ]);
        },
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.onBack, required this.onSendAgain});

  final VoidCallback onBack;
  final VoidCallback onSendAgain;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final sent = ActivationScope.of(context).profile != null;
    Widget step(int n, String text, bool done) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? Fvi.green : Fvi.surface,
                border: done ? null : Border.all(color: Fvi.orange, width: 2),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : Text('$n', style: const TextStyle(color: Fvi.orange, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
          ]),
        );
    return Scaffold(
      backgroundColor: Fvi.bg,
      appBar: AppBar(backgroundColor: Fvi.bg, title: Text(t.activateTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Fvi.navy)),
          leading: BackButton(onPressed: onBack)),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(color: Fvi.orangeSoft, shape: BoxShape.circle),
            child: const Icon(Icons.key_rounded, color: Fvi.orange, size: 52),
          ),
        ),
        const SizedBox(height: 16),
        Text(t.waitingTitle, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Fvi.text)),
        const SizedBox(height: 6),
        Text(t.waitingText, textAlign: TextAlign.center, style: const TextStyle(color: Fvi.muted, height: 1.6)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Fvi.surface, borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Fvi.line)),
          child: Column(children: [
            step(1, t.stepDetails, sent),
            step(2, t.stepSent, sent),
            step(3, t.stepCode, false),
          ]),
        ),
        const SizedBox(height: 18),
        Row(children: [
          const Expanded(child: Divider(color: Fvi.line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(t.orEnterCode, style: const TextStyle(color: Fvi.muted, fontWeight: FontWeight.w600)),
          ),
          const Expanded(child: Divider(color: Fvi.line)),
        ]),
        const SizedBox(height: 12),
        const CodeEntry(),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onSendAgain,
          icon: const Icon(Icons.refresh_rounded, color: Fvi.navy),
          label: Text(t.sendAgain, style: const TextStyle(fontWeight: FontWeight.w700, color: Fvi.navy, fontSize: 15)),
        ),
      ]),
    );
  }
}
