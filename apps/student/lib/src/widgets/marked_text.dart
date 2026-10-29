import 'package:flutter/material.dart';

import '../theme.dart';

/// How [brackets] are shown, as in the books.
enum Mark {
  /// Grammar in stories, conversations and podcasts: orange.
  grammar,

  /// Key words in topics and science: navy, underlined in orange.
  keyword,

  /// Key words in a news article: navy.
  news,

  /// Inside "What did you learn?": orange and bold.
  emphasis,

  /// Starter words: c[a]t marks the letters taught, mak{e} a silent letter.
  phonics,
}

/// Shows lesson text with the markup of the books:
/// [grammar] or [key words], ((idioms, proverbs and phrases)), and in the
/// Starter sound lessons c[a]t and mak{e}.
class MarkedText extends StatelessWidget {
  const MarkedText(this.text, {super.key, this.mark = Mark.grammar, this.style, this.textAlign, this.textDirection});

  final String text;
  final Mark mark;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;

  static final _pattern = RegExp(r'\(\(([^()]+)\)\)|\[([^\]]+)\]|\{([^}]+)\}');

  /// The text without its markup, for search and for accessibility.
  static String plain(String text) => text.replaceAllMapped(_pattern, (m) => m[1] ?? m[2] ?? m[3]!);

  static List<InlineSpan> spans(String text, Mark mark) {
    final out = <InlineSpan>[];
    var pos = 0;
    for (final m in _pattern.allMatches(text)) {
      if (m.start > pos) out.add(TextSpan(text: text.substring(pos, m.start)));
      if (m[1] != null) {
        out.add(TextSpan(text: m[1], style: idiomStyle));
      } else if (m[2] != null) {
        out.add(TextSpan(text: m[2], style: _bracket(mark)));
      } else if (mark == Mark.phonics) {
        out.add(TextSpan(text: m[3], style: silentStyle));
      } else {
        out.add(TextSpan(text: m[0]));
      }
      pos = m.end;
    }
    if (pos < text.length) out.add(TextSpan(text: text.substring(pos)));
    return out;
  }

  static const idiomStyle = TextStyle(
    color: Fvi.amber,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    decorationStyle: TextDecorationStyle.dotted,
    decorationColor: Fvi.amber,
    decorationThickness: 2,
  );

  static const silentStyle = TextStyle(
    color: Color(0xFFB9BCCF),
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.underline,
    decorationStyle: TextDecorationStyle.dotted,
    decorationColor: Color(0xFFB9BCCF),
  );

  static TextStyle _bracket(Mark mark) => switch (mark) {
        Mark.grammar => const TextStyle(color: Fvi.orange, fontWeight: FontWeight.w600),
        Mark.keyword => const TextStyle(
            color: Fvi.navy,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: Fvi.orange,
            decorationThickness: 1.6,
          ),
        Mark.news => const TextStyle(color: Fvi.navy, fontWeight: FontWeight.w700),
        Mark.emphasis || Mark.phonics => const TextStyle(color: Fvi.orange, fontWeight: FontWeight.w700),
      };

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: spans(text, mark)),
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        semanticsLabel: plain(text),
      );
}
