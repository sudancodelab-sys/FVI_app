import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../content/model.dart';
import '../../theme.dart';
import '../../widgets/marked_text.dart';
import '../../widgets/spoken.dart';
import 'icons.dart';

const _body = TextStyle(fontFamily: Fvi.english, fontSize: 16, height: 1.65, color: Fvi.text);
const _small = TextStyle(fontFamily: Fvi.english, fontSize: 14, height: 1.5, color: Fvi.muted);

/// Builds a lesson the way the books lay it out, section by section.
class LessonSections {
  LessonSections(this.context, this.level, this.lesson);

  final BuildContext context;
  final Level level;
  final Lesson lesson;
  final _out = <Widget>[];
  var _number = 0;

  Json get j => lesson.json;
  Color get color => Fvi.kind(lesson.kind);

  List<Widget> build() {
    _out.add(_hero());
    switch (lesson.kind) {
      case 'story':
        _story();
      case 'topic' || 'science':
        _topic();
      case 'news':
        _news();
      case 'podcast':
        _podcast();
      case 'conversation' || 'speaking':
        _conversation();
      case 'intro':
        _alphabet();
      default:
        _phonics();
    }
    if (j['questions'] != null && lesson.kind != 'story') _questions();
    if (j['idioms'] != null) _idioms();
    if (j['words'] != null) _words();
    return _out;
  }

  // ---------------------------------------------------------------- parts

  Widget _hero() {
    final label = switch (lesson.kind) {
      'phonics' || 'intro' => 'PHONICS',
      'speaking' => 'SPEAKING',
      final k => k.toUpperCase(),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
            child: Icon(lessonIcon(lesson.icon), color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$label · LESSON ${lesson.number}',
                    style: TextStyle(fontFamily: Fvi.english, fontSize: 11.5, letterSpacing: 1.2,
                        fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text(lesson.title,
                    style: const TextStyle(fontFamily: Fvi.english, fontSize: 24, height: 1.2,
                        fontWeight: FontWeight.w800, color: Fvi.navy)),
                if (lesson.subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(lesson.subtitle!, style: _small),
                ],
                if (lesson.goals.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final g in lesson.goals)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Fvi.navySoft, borderRadius: BorderRadius.circular(99)),
                        child: Text(g, style: const TextStyle(fontFamily: Fvi.english, fontSize: 12,
                            fontWeight: FontWeight.w600, color: Fvi.navy)),
                      ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _section(String title, List<Widget> children, {String? note}) {
    _number++;
    _out.add(Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: Fvi.orange,
          child: Text('$_number', style: const TextStyle(fontFamily: Fvi.english, fontSize: 13,
              fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: Fvi.navy)),
            if (note != null) TextSpan(text: '   $note', style: _small.copyWith(fontSize: 13)),
          ]), style: const TextStyle(fontFamily: Fvi.english)),
        ),
      ]),
    ));
    _out.addAll(children);
  }

  /// A paragraph.
  Widget _para(Spoken item, {Mark mark = Mark.grammar, TextStyle style = _body}) => TextBlock(
        child: MarkedText(item.text, mark: mark, style: style),
      );

  /// The reading box of the books: a tinted panel with a colored edge.
  Widget _box(List<Widget> children, {Color? edge, Color background = Fvi.navyTint}) => Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 10, 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: BorderDirectional(start: BorderSide(color: edge ?? color, width: 4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  Widget _avatar(String who, {double radius = 16}) {
    final member = level.cast[who];
    return CircleAvatar(
      radius: radius,
      backgroundColor: Fvi.avatar(member?.color ?? 'e'),
      child: Text(member?.initial ?? who.characters.first,
          style: TextStyle(fontFamily: Fvi.english, fontSize: radius * .72, fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }

  // ---------------------------------------------------------------- kinds

  void _story() {
    _section('The story', [_box([for (final p in Spoken.list(j['story'])) _para(p)])]);
    _questions();
    final pov = j['pov'] as Json;
    _section('Point of view', [
      _box(edge: Fvi.navy, [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            _avatar(pov['speaker'] as String),
            const SizedBox(width: 8),
            Text(pov['speaker'] as String, style: const TextStyle(fontFamily: Fvi.english,
                fontWeight: FontWeight.w700, color: Fvi.navy)),
          ]),
        ),
        for (final p in Spoken.list(pov['text'])) _para(p),
      ]),
    ], note: pov['intro'] as String);
    _learn(j['learn'] as Json);
  }

  void _questions() {
    final qas = [for (final q in j['questions'] as List) QuestionAnswer.fromJson(q as Json)];
    _section('Questions and answers', [
      for (var i = 0; i < qas.length; i++)
        Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Fvi.line))),
          child: TextBlock(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 26, child: Text('${i + 1}', style: _body.copyWith(color: Fvi.orange,
                  fontWeight: FontWeight.w700, fontSize: 14))),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(qas[i].question.text, style: _body.copyWith(fontWeight: FontWeight.w600,
                      color: Fvi.navy, fontSize: 15)),
                  Text(qas[i].answer.text, style: _small),
                ]),
              ),
            ]),
          ),
        ),
    ], note: 'Answer fast. Short answers are fine.');
  }

  void _learn(Json learn) {
    final table = (learn['table'] as List).cast<List>();
    final ask = QuestionAnswer.fromJson(learn['ask'] as Json);
    // The Arabic explanation shows only when Arabic is the app's language (decision #45).
    final ar = Localizations.localeOf(context).languageCode == 'ar' ? learn['ar'] as Json? : null;
    _section('What did you learn?', [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Fvi.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Fvi.orange, width: 1.4),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          MarkedText(learn['title'] as String, mark: Mark.emphasis,
              style: const TextStyle(fontFamily: Fvi.english, fontSize: 19, fontWeight: FontWeight.w800,
                  color: Fvi.navy)),
          const SizedBox(height: 6),
          Text(learn['intro'] as String, style: _small),
          const SizedBox(height: 12),
          _table(table),
          const SizedBox(height: 12),
          for (final n in (learn['notes'] as List).cast<Json>())
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Fvi.navyTint, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                MarkedText(n['title'] as String, mark: Mark.emphasis,
                    style: const TextStyle(fontFamily: Fvi.english, fontWeight: FontWeight.w700,
                        color: Fvi.navy, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(n['text'] as String, style: _small),
              ]),
            ),
          const Divider(height: 18, color: Fvi.line),
          TextBlock(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('QUESTIONS', style: _small.copyWith(color: Fvi.orange, fontSize: 11,
                  letterSpacing: 1.2, fontWeight: FontWeight.w700)),
              Text(ask.question.text, style: _body.copyWith(fontWeight: FontWeight.w600, color: Fvi.navy)),
              Text(ask.answer.text, style: _small),
            ]),
          ),
        ]),
      ),
      if (ar != null) _arabicNote(ar),
    ]);
  }

  Widget _table(List<List> rows) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Table(
          border: const TableBorder(horizontalInside: BorderSide(color: Fvi.line)),
          children: [
            for (var r = 0; r < rows.length; r++)
              TableRow(
                decoration: BoxDecoration(color: r == 0 ? Fvi.navy : (r.isOdd ? Fvi.surface : Fvi.navyTint)),
                children: [
                  for (final cell in rows[r])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: r == 0
                          ? Text((cell as String).toUpperCase(), style: const TextStyle(fontFamily: Fvi.english,
                              fontSize: 11, letterSpacing: .8, fontWeight: FontWeight.w700, color: Colors.white))
                          : MarkedText(cell as String, mark: Mark.emphasis,
                              style: const TextStyle(fontFamily: Fvi.english, fontSize: 14, color: Fvi.text)),
                    ),
                ],
              ),
          ],
        ),
      );

  /// The Arabic explanation of the early levels, shown right to left.
  Widget _arabicNote(Json ar) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Fvi.amberSoft,
            borderRadius: BorderRadius.circular(16),
            border: const BorderDirectional(start: BorderSide(color: Fvi.amber, width: 4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.translate_rounded, size: 18, color: Fvi.amber),
              const SizedBox(width: 6),
              Text(L10n.of(context).inArabic, style: const TextStyle(fontFamily: Fvi.arabic,
                  fontWeight: FontWeight.w800, color: Fvi.amber, fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            Text(ar['summary'] as String, style: const TextStyle(fontFamily: Fvi.arabic, fontSize: 15.5,
                height: 1.7, fontWeight: FontWeight.w600, color: Fvi.text)),
            const SizedBox(height: 6),
            // A point is Arabic only, or [Arabic, English example]; the
            // example gets its own line, left to right, so the two never mix.
            for (final p in ar['points'] as List)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: CircleAvatar(radius: 3, backgroundColor: Fvi.amber),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p is List ? p[0] as String : p as String, style: const TextStyle(
                          fontFamily: Fvi.arabic, fontSize: 15, height: 1.7, color: Fvi.text)),
                      if (p is List)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Fvi.surface, borderRadius: BorderRadius.circular(8)),
                            child: MarkedText(p[1] as String, mark: Mark.emphasis,
                                style: const TextStyle(fontFamily: Fvi.english, fontSize: 14.5, color: Fvi.text),
                                textDirection: TextDirection.ltr),
                          ),
                        ),
                    ]),
                  ),
                ]),
              ),
          ]),
        ),
      );

  void _topic() {
    final science = lesson.kind == 'science';
    _section('Read', [
      _box(edge: science ? Fvi.teal : Fvi.navy,
          [for (final p in Spoken.list(j['text'])) _para(p, mark: Mark.keyword)]),
    ]);
    _facts();
    final dyk = Spoken.maybe(j['did_you_know']);
    if (dyk != null) {
      _out.add(Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: BoxDecoration(color: const Color(0xFFE3F2F3), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Fvi.teal.withValues(alpha: .35))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DID YOU KNOW?', style: _small.copyWith(color: Fvi.teal, fontSize: 11.5,
                letterSpacing: 1.1, fontWeight: FontWeight.w800)),
            _para(dyk, style: _body.copyWith(fontSize: 15)),
          ]),
        ),
      ));
    }
  }

  void _facts() {
    for (final g in (j['facts'] as List? ?? const []).cast<Json>()) {
      final items = (g['items'] as List).cast<Json>();
      final steps = g['steps'] == true;
      _section(g['title'] as String, [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < items.length; i++)
            Container(
              width: 158,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Fvi.surface, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Fvi.line)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${steps ? '${i + 1}  ' : ''}${items[i]['term']}',
                    style: TextStyle(fontFamily: Fvi.english, fontWeight: FontWeight.w800, fontSize: 15,
                        color: color)),
                const SizedBox(height: 2),
                Text(items[i]['text'] as String, style: _small.copyWith(fontSize: 13)),
              ]),
            ),
        ]),
      ]);
    }
  }

  void _news() {
    final headline = Spoken.fromJson(j['headline'] as Json);
    final stand = Spoken.fromJson(j['standfirst'] as Json);
    final quote = j['quote'] as Json?;
    final text = Spoken.list(j['text']);
    _section('Read the article', [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Fvi.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Fvi.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text((j['paper'] as String).toUpperCase(), style: const TextStyle(
                fontFamily: Fvi.english, fontWeight: FontWeight.w800, letterSpacing: .6, color: Fvi.navy))),
            Text(j['date'] as String, style: _small.copyWith(fontSize: 12)),
          ]),
          const Divider(color: Fvi.line, thickness: 3, height: 18),
          _para(headline, style: const TextStyle(fontFamily: Fvi.english, fontSize: 21, height: 1.25,
              fontWeight: FontWeight.w800, color: Fvi.text)),
          _para(stand, style: _body.copyWith(fontWeight: FontWeight.w600, color: Fvi.navy)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text((j['byline'] as String).toUpperCase(), style: const TextStyle(
                fontFamily: Fvi.english, fontSize: 11, letterSpacing: .8, fontWeight: FontWeight.w700,
                color: Fvi.violet)),
          ),
          for (var i = 0; i < text.length; i++) ...[
            _para(text[i], mark: Mark.news, style: _body.copyWith(fontSize: 15)),
            if (quote != null && quote['after'] == i + 1)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsetsDirectional.only(start: 12),
                decoration: const BoxDecoration(border: BorderDirectional(
                    start: BorderSide(color: Fvi.violet, width: 4))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('“${quote['text']}”', style: const TextStyle(fontFamily: Fvi.english, fontSize: 17,
                      fontStyle: FontStyle.italic, fontWeight: FontWeight.w700, color: Fvi.violet)),
                  Text((quote['by'] as String).toUpperCase(), style: _small.copyWith(fontSize: 11)),
                ]),
              ),
          ],
        ]),
      ),
    ]);
    _facts();
  }

  void _podcast() {
    _section('Before you listen', [
      _box(edge: Fvi.pink, background: Fvi.pinkSoft,
          [for (final q in Spoken.list(j['before'])) _para(q)]),
    ]);
    _section('Listen and read', [
      Text(j['scene'] as String, style: _small.copyWith(fontStyle: FontStyle.italic)),
      const SizedBox(height: 8),
      for (final line in (j['script'] as List).cast<Json>()) _line(line, time: line['time'] as String),
    ], note: '${j['show']} · Episode ${j['episode']}');
  }

  void _conversation() {
    _section('Read the conversation', [
      Container(
        padding: const EdgeInsetsDirectional.only(start: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(border: BorderDirectional(start: BorderSide(color: Fvi.orange, width: 3))),
        child: Text(j['scene'] as String, style: _small.copyWith(fontStyle: FontStyle.italic)),
      ),
      for (final line in (j['conversation'] as List).cast<Json>()) _line(line),
    ]);
    _section('Useful phrases', [
      for (final ph in (j['phrases'] as List).cast<Json>())
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
          decoration: BoxDecoration(color: Fvi.surface, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Fvi.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((ph['title'] as String).toUpperCase(), style: const TextStyle(fontFamily: Fvi.english,
                fontSize: 11, letterSpacing: .8, fontWeight: FontWeight.w700, color: Fvi.orange)),
            for (final line in Spoken.list(ph['lines']))
              _para(line, style: _body.copyWith(fontWeight: FontWeight.w500, fontSize: 15)),
            if (Spoken.maybe(ph['reply']) case final reply?)
              _para(reply, style: _small.copyWith(fontSize: 14.5)),
          ]),
        ),
    ]);
  }

  Widget _line(Json line, {String? time}) {
    final item = Spoken.fromJson(line);
    final who = line['who'] as String;
    return TextBlock(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (time != null)
          SizedBox(width: 44, child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(time, style: const TextStyle(fontFamily: Fvi.english, fontSize: 11.5,
                fontWeight: FontWeight.w700, color: Fvi.pink)),
          )),
        _avatar(who),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(who.toUpperCase(), style: const TextStyle(fontFamily: Fvi.english, fontSize: 11,
                letterSpacing: .8, fontWeight: FontWeight.w700, color: Fvi.muted)),
            MarkedText(item.text, style: _body.copyWith(fontSize: 15.5)),
          ]),
        ),
      ]),
    );
  }

  void _idioms() {
    final idioms = (j['idioms'] as List).cast<Json>();
    _section('Idioms, proverbs and phrases', [
      for (final e in idioms)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(color: Fvi.amberSoft, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1DDA8))),
          child: TextBlock(
            padding: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: switch (e['type']) { 'proverb' => Fvi.navy, 'phrase' => Fvi.green, _ => Fvi.amber },
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text((e['type'] as String).toUpperCase(), style: const TextStyle(fontFamily: Fvi.english,
                    fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(height: 6),
              Text(e['expr'] as String, style: const TextStyle(fontFamily: Fvi.english, fontSize: 16.5,
                  fontWeight: FontWeight.w700, color: Fvi.navy)),
              Text(e['meaning'] as String, style: _body.copyWith(fontSize: 14.5)),
              const SizedBox(height: 4),
              Text.rich(TextSpan(children: [
                const TextSpan(text: 'Example: ', style: TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: e['example'] as String, style: const TextStyle(fontStyle: FontStyle.italic)),
              ]), style: _small.copyWith(fontSize: 13.5)),
            ]),
          ),
        ),
    ]);
  }

  void _words() {
    _section('New words', [
      for (final w in (j['words'] as List).cast<Json>())
        Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Fvi.line))),
          child: TextBlock(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 120, child: Text(w['word'] as String, style: const TextStyle(
                  fontFamily: Fvi.english, fontWeight: FontWeight.w700, fontSize: 15.5, color: Fvi.navy))),
              Expanded(child: Text(w['meaning'] as String, style: _small)),
            ]),
          ),
        ),
    ]);
  }

  // ---------------------------------------------------------- Starter

  static const _reliability = {
    'always': 'ALWAYS',
    'almost': 'ALMOST ALWAYS',
    'usually': 'USUALLY TRUE',
    'varies': 'NOT FIXED — LEARN EACH WORD',
    'few': 'NOT A RULE — A FEW WORDS',
  };

  Widget _wordChips(List items) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final w in Spoken.list(items)) _WordChip(item: w),
      ]);

  Widget _ipa(String ipa) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Fvi.orangeSoft, borderRadius: BorderRadius.circular(8)),
        child: Text('/$ipa/', style: const TextStyle(fontFamily: 'NotoSansIPA', fontSize: 16,
            fontWeight: FontWeight.w700, color: Fvi.orange)),
      );

  Widget _badge(String? key) => key == null
      ? const SizedBox.shrink()
      : Text(_reliability[key] ?? key.toUpperCase(), style: TextStyle(fontFamily: Fvi.english,
          fontSize: 10.5, letterSpacing: .8, fontWeight: FontWeight.w700,
          color: key == 'always' || key == 'almost' ? Fvi.green : Fvi.amber));

  Widget _card(List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Fvi.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Fvi.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  void _phonics() {
    for (final part in (j['parts'] as List).cast<Json>()) {
      _section('The letter ${part['letter']}', [
        if (part['intro'] != null) Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(part['intro'] as String, style: _small),
        ),
        for (final s in (part['sounds'] as List).cast<Json>())
          _card([
            Row(children: [_ipa(s['ipa'] as String), const SizedBox(width: 10),
              Expanded(child: Text(s['name'] as String, style: _body.copyWith(fontWeight: FontWeight.w600,
                  color: Fvi.navy, fontSize: 15)))]),
            const SizedBox(height: 10),
            _wordChips(s['examples'] as List),
          ]),
        for (final r in (part['rules'] as List? ?? const []).cast<Json>())
          _card([
            _badge(r['reliability'] as String?),
            Text(r['text'] as String, style: _body.copyWith(fontWeight: FontWeight.w600, color: Fvi.navy)),
            if (r['detail'] != null) Text(r['detail'] as String, style: _small),
            if (r['examples'] != null) ...[const SizedBox(height: 8), _wordChips(r['examples'] as List)],
            if (r['note'] != null) ...[const SizedBox(height: 6), Text(r['note'] as String, style: _small)],
            if (r['note_examples'] != null) ...[const SizedBox(height: 6), _wordChips(r['note_examples'] as List)],
          ]),
        ..._silent(part['silent']),
        for (final t in (part['teams'] as List? ?? const []).cast<Json>())
          _card([
            Row(children: [
              Text(t['letters'] as String, style: const TextStyle(fontFamily: Fvi.english, fontSize: 20,
                  fontWeight: FontWeight.w800, color: Fvi.navy)),
              const SizedBox(width: 10),
              _badge(t['reliability'] as String?),
            ]),
            for (final s in (t['sounds'] as List).cast<Json>()) ...[
              const SizedBox(height: 8),
              Row(children: [if (s['ipa'] != null) _ipa(s['ipa'] as String)]),
              const SizedBox(height: 6),
              _wordChips(s['examples'] as List),
            ],
            if (t['note'] != null) ...[const SizedBox(height: 8), Text(t['note'] as String, style: _small)],
          ]),
      ]);
    }
  }

  List<Widget> _silent(Object? silent) {
    final rules = silent is List ? silent.cast<Json>() : [if (silent is Json) silent];
    return [
      for (final s in rules)
        if (s['none'] != null)
          Padding(padding: const EdgeInsets.only(bottom: 10),
              child: Text('Silent? ${s['none']}', style: _small.copyWith(fontStyle: FontStyle.italic)))
        else
          _card([
            Text('SILENT LETTER', style: _small.copyWith(fontSize: 10.5, letterSpacing: .8,
                fontWeight: FontWeight.w700, color: Fvi.muted)),
            _badge(s['reliability'] as String?),
            Text(s['rule'] as String, style: _body.copyWith(fontWeight: FontWeight.w600, color: Fvi.navy)),
            if (s['detail'] != null) Text(s['detail'] as String, style: _small),
            if (s['examples'] != null) ...[const SizedBox(height: 8), _wordChips(s['examples'] as List)],
            if (s['note'] != null) ...[const SizedBox(height: 6), Text(s['note'] as String, style: _small)],
            if (s['note_examples'] != null) ...[const SizedBox(height: 6), _wordChips(s['note_examples'] as List)],
          ]),
    ];
  }

  void _alphabet() {
    _section('Letter names and sounds', [
      for (final n in (j['names'] as List).cast<Json>())
        _card([
          Row(children: [
            Text(n['letter'] as String, style: const TextStyle(fontFamily: Fvi.english, fontSize: 28,
                fontWeight: FontWeight.w800, color: Fvi.navy)),
            const SizedBox(width: 12),
            _ipa(n['name'] as String),
            const SizedBox(width: 8),
            _ipa(n['sound'] as String),
            const Spacer(),
          ]),
          const SizedBox(height: 8),
          _wordChips([n['word']]),
        ]),
    ]);
    final y = j['y_note'] as Json?;
    if (y != null) {
      _out.add(_card([Text(y['text'] as String, style: _body), const SizedBox(height: 8),
        _wordChips(y['examples'] as List)]));
    }
    for (final g in (j['chart'] as List? ?? const []).cast<Json>()) {
      _section(g['title'] as String, [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final it in (g['items'] as List).cast<Json>())
            Column(mainAxisSize: MainAxisSize.min, children: [
              _ipa(it['ipa'] as String),
              const SizedBox(height: 4),
              _WordChip(item: Spoken.fromJson(it['word'] as Json)),
            ]),
        ]),
      ]);
    }
  }
}

/// A Starter example word: the letters taught in orange, a silent letter
/// in grey.
class _WordChip extends StatelessWidget {
  const _WordChip({required this.item});

  final Spoken item;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: Fvi.navyTint, borderRadius: BorderRadius.circular(12)),
        child: MarkedText(item.text, mark: Mark.phonics, style: const TextStyle(fontFamily: Fvi.english,
            fontSize: 20, fontWeight: FontWeight.w600, color: Fvi.text)),
      );
}
