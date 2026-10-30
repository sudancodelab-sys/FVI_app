import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../content/model.dart';
import '../theme.dart';

const _english = TextStyle(fontFamily: Fvi.english, color: Fvi.text);
const _gap = '\u2007\u2007\u2007\u2007\u2007\u2007\u2007\u2007'; // the gap in a form exercise, underlined

/// The section names of the books, over each exercise.
const _labels = {
  'question': 'QUESTIONS',
  'meaning': 'NEW WORDS',
  'idiom': 'IDIOMS, PROVERBS AND PHRASES',
  'form': 'GRAMMAR',
  'reply': 'USEFUL PHRASES',
  'order': 'USEFUL PHRASES',
};

/// The exercises of a lesson, one at a time, as in the approved sample: the
/// student answers, sees at once whether it was right and the right answer,
/// and gets a score at the end.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  late final _exercises = widget.lesson.exercises;
  var _index = 0;
  var _right = 0;
  int? _picked;
  final _built = <int>[]; // an order exercise: the words put in, by their place in the jumble
  bool? _correct; // null until answered

  Exercise get _ex => _exercises[_index];
  bool get _done => _index >= _exercises.length;
  Color get _color => Fvi.kind(widget.lesson.kind);

  void _answer(bool correct) => setState(() {
        _correct = correct;
        if (correct) _right++;
      });

  void _pick(int i) {
    if (_correct != null) return;
    _picked = i;
    _answer(i == _ex.rightChoice);
  }

  void _check() => _answer([for (final i in _built) _ex.words[i]].join(' ') == _ex.sentence);

  void _next() => setState(() {
        _index++;
        _picked = null;
        _built.clear();
        _correct = null;
      });

  void _restart() => setState(() {
        _index = 0;
        _right = 0;
        _picked = null;
        _built.clear();
        _correct = null;
      });

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Scaffold(
      backgroundColor: Fvi.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.exercises, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Fvi.navy)),
          Text(widget.lesson.title, textDirection: TextDirection.ltr,
              style: const TextStyle(fontFamily: Fvi.english, fontSize: 13, color: Fvi.muted)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _done ? 1 : _index / _exercises.length,
            minHeight: 3,
            color: Fvi.orange,
            backgroundColor: Fvi.line,
          ),
        ),
      ),
      body: _done ? _score(t) : _exercise(t),
      bottomNavigationBar: _done ? null : _bottom(t),
    );
  }

  String _how(L10n t) => switch (_ex.kind) {
        'meaning' => t.howMeaning,
        'idiom' => t.howIdiom,
        'form' => t.howForm,
        'reply' => t.howReply,
        'order' => t.howOrder,
        _ => t.howQuestion,
      };

  Widget _exercise(L10n t) {
    final ex = _ex;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        Text(t.nOfM(_index + 1, _exercises.length),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Fvi.muted)),
        const SizedBox(height: 10),
        Text(_labels[ex.kind] ?? '', style: TextStyle(fontFamily: Fvi.english, fontSize: 11.5, letterSpacing: 1,
            fontWeight: FontWeight.w700, color: _color)),
        const SizedBox(height: 4),
        Text(_how(t), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Fvi.text)),
        const SizedBox(height: 12),
        // The exercise itself is English, left to right in the Arabic app too.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (ex.isOrder) ...[
              if (ex.prompt.isNotEmpty) Text(ex.prompt, style: _english.copyWith(fontSize: 14.5, color: Fvi.muted)),
              const SizedBox(height: 10),
              _order(ex),
            ] else ...[
              _prompt(ex),
              if (ex.example != null) ...[
                const SizedBox(height: 6),
                Text(ex.example!, style: _english.copyWith(fontSize: 14.5, color: Fvi.muted, fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 16),
              for (var i = 0; i < ex.choices.length; i++) _choice(ex, i),
            ],
          ]),
        ),
        if (_correct != null) ...[
          const SizedBox(height: 14),
          _feedback(t, ex),
        ],
      ],
    );
  }

  Widget _prompt(Exercise ex) {
    const style = TextStyle(fontFamily: Fvi.english, fontSize: 20, height: 1.5, fontWeight: FontWeight.w600,
        color: Fvi.text);
    if (ex.kind != 'form') return Text(ex.prompt, style: style);
    return Text.rich(TextSpan(style: style, children: [
      TextSpan(text: ex.before.isEmpty ? '' : '${ex.before} '),
      const TextSpan(text: _gap, style: TextStyle(decoration: TextDecoration.underline,
          decorationColor: Fvi.orange, decorationThickness: 2.5)),
      TextSpan(text: ex.after.isEmpty ? '' : ' ${ex.after}'),
    ]));
  }

  Widget _choice(Exercise ex, int i) {
    final answered = _correct != null;
    final (border, fill) = !answered
        ? (Fvi.line, Fvi.surface)
        : i == ex.rightChoice
            ? (Fvi.green, Fvi.greenSoft)
            : i == _picked
                ? (Fvi.red, Fvi.redSoft)
                : (Fvi.line, Fvi.surface);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: border, width: 1.5)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: answered ? null : () => _pick(i),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Text(ex.choices[i], style: _english.copyWith(fontSize: 16, height: 1.45)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _order(Exercise ex) {
    final answered = _correct != null;
    Widget word(int i, {required bool placed}) => ActionChip(
          label: Text(ex.words[i], style: _english.copyWith(fontSize: 16)),
          backgroundColor: placed ? Fvi.surface : Fvi.navySoft,
          side: const BorderSide(color: Fvi.line, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onPressed: answered ? null : () => setState(() => placed ? _built.remove(i) : _built.add(i)),
        );
    final (border, fill) = !answered
        ? (Fvi.line, Fvi.surface)
        : _correct!
            ? (Fvi.green, Fvi.greenSoft)
            : (Fvi.red, Fvi.redSoft);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.5)),
        child: Wrap(spacing: 6, runSpacing: 6, children: [for (final i in _built) word(i, placed: true)]),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (var i = 0; i < ex.words.length; i++)
          if (!_built.contains(i)) word(i, placed: false),
      ]),
    ]);
  }

  Widget _feedback(L10n t, Exercise ex) {
    if (_correct!) {
      return Text(t.right, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Fvi.green));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t.rightAnswer, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Fvi.red)),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Text(ex.rightText, style: _english.copyWith(fontSize: 16)),
      ),
    ]);
  }

  Widget _bottom(L10n t) {
    final answered = _correct != null;
    final (label, onPressed) = answered
        ? (_index + 1 < _exercises.length ? t.next : t.seeScore, _next)
        : _ex.isOrder
            ? (t.check, _built.length == _ex.words.length ? _check : null)
            : (t.next, null);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Fvi.line))),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Fvi.orange,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
          ),
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }

  Widget _score(L10n t) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(t.exercisesDone, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Fvi.text)),
            const SizedBox(height: 8),
            Text(t.nOfM(_right, _exercises.length),
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Fvi.navy)),
            if (_right == _exercises.length)
              Text(t.allRight, style: const TextStyle(fontSize: 15, color: Fvi.green, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Fvi.orange, minimumSize: const Size(0, 48)),
                onPressed: _restart,
                child: Text(t.doAgain),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Fvi.orange, minimumSize: const Size(0, 48),
                    side: const BorderSide(color: Fvi.orange, width: 1.5)),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.backToLesson),
              ),
            ]),
          ]),
        ),
      );
}
