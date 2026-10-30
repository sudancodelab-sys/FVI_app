import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../activation/activation.dart';
import '../content/repository.dart';
import '../theme.dart';
import 'course_screen.dart';
import 'onboarding/onboarding.dart';
import 'onboarding/request.dart';

/// The first screen: the activation steps until a code is applied, the
/// clock warning if the phone's date went back, then the course. It checks
/// the clock again whenever the student returns to the app.
class Gate extends StatefulWidget {
  const Gate({super.key, required this.content});

  final ContentRepository content;

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ActivationScope.read(context).checkClock();
  }

  @override
  Widget build(BuildContext context) {
    final activation = ActivationScope.of(context);
    if (!activation.loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (activation.clockBehind) return const _ClockBehind();
    if (!activation.activated) return OnboardingFlow(content: widget.content);
    return CourseScreen(content: widget.content);
  }
}

/// The phone's date went back: nothing opens until it is right, or a new
/// code vouches for it (docs/REQUIREMENTS.md 5.5).
class _ClockBehind extends StatelessWidget {
  const _ClockBehind();

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Scaffold(
      backgroundColor: Fvi.bg,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 30),
          const Icon(Icons.event_busy_rounded, size: 64, color: Fvi.orange),
          const SizedBox(height: 16),
          Text(t.clockTitle, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Fvi.text)),
          const SizedBox(height: 8),
          Text(t.clockText, textAlign: TextAlign.center, style: const TextStyle(color: Fvi.muted, height: 1.6)),
          const SizedBox(height: 22),
          FilledButton(
            style: primaryButton(Fvi.navy),
            onPressed: () => ActivationScope.read(context).checkClock(),
            child: Text(t.tryAgain),
          ),
          const SizedBox(height: 26),
          Text(t.enterCode, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const CodeEntry(),
        ]),
      ),
    );
  }
}
