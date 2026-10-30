/// The levels as exported by curriculum/tools/export_app.py.
///
/// Lessons keep their JSON (it mirrors the books, one kind at a time); the
/// parts that every screen needs are typed here.
library;

typedef Json = Map<String, dynamic>;

/// A text that has its own audio clip: shown as [text], heard from the clip
/// [id], said by [voice] (a member of the cast, or a role such as narrator).
class Spoken {
  const Spoken({required this.text, required this.id, required this.voice});

  factory Spoken.fromJson(Json json) =>
      Spoken(text: json['t'] as String, id: json['a'] as String, voice: json['v'] as String);

  final String text;
  final String id;
  final String voice;

  static Spoken? maybe(Object? json) => json is Json && json['a'] is String ? Spoken.fromJson(json) : null;

  static List<Spoken> list(Object? json) =>
      [for (final item in (json as List? ?? const [])) Spoken.fromJson(item as Json)];
}

/// A question and its answer, each with its own clip.
class QuestionAnswer {
  const QuestionAnswer(this.question, this.answer);

  factory QuestionAnswer.fromJson(Json json) =>
      QuestionAnswer(Spoken.fromJson(json['question'] as Json), Spoken.fromJson(json['answer'] as Json));

  final Spoken question;
  final Spoken answer;
}

class CastMember {
  const CastMember({required this.initial, required this.color});

  factory CastMember.fromJson(Json json) =>
      CastMember(initial: json['initial'] as String, color: json['color'] as String);

  final String initial;
  final String color;
}

/// One line of the course screen.
class LevelSummary {
  const LevelSummary({
    required this.slug,
    required this.order,
    required this.name,
    required this.cefr,
    required this.stage,
    required this.lessonCount,
  });

  factory LevelSummary.fromJson(Json json) => LevelSummary(
        slug: json['slug'] as String,
        order: json['order'] as int,
        name: json['name'] as String,
        cefr: json['cefr'] as String,
        stage: json['stage'] as String,
        lessonCount: json['lessons'] as int,
      );

  final String slug;
  final int order;
  final String name;
  final String cefr;
  final String stage;
  final int lessonCount;
}

class Unit {
  const Unit(this.number, this.title);

  final int number;
  final String title;
}

class Lesson {
  Lesson(this.json, {required this.position, required this.count});

  final Json json;

  /// Where the lesson stands in its level (1-based), and how many there are.
  final int position;
  final int count;

  int get number => json['lesson'] as int;
  int? get unit => json['unit'] as int?;

  /// story, topic, science, news, podcast or conversation; for Starter,
  /// phonics, intro or speaking.
  String get kind => json['kind'] as String? ?? 'phonics';
  String get title => json['title'] as String;
  String? get subtitle => json['subtitle'] as String? ?? json['intro'] as String?;
  String get icon => json['icon'] as String? ?? 'book';
  List<String> get goals => [for (final g in (json['goals'] as List? ?? const [])) g as String];
  List<Exercise> get exercises => [
        for (final e in (json['exercises'] as List? ?? const [])) Exercise.fromJson(e as Json),
      ];
}

/// An exercise of a lesson, made from the lesson by curriculum/tools/exercises.py.
///
/// [kind] is question, meaning, idiom, form, reply or order, and in Starter
/// letters or silent. An order exercise gives [words] to put back into
/// [sentence]; the others give [choices], of which [rightChoice] is the
/// right one. A form or letters exercise has a gap between [before] and
/// [after]; a letters exercise also gives the [sound] of the gap (/e/ · Short E).
class Exercise {
  Exercise.fromJson(Json json)
      : kind = json['kind'] as String,
        prompt = json['prompt'] as String? ?? '',
        choices = [for (final c in json['choices'] as List? ?? const []) c as String],
        rightChoice = json['type'] == 'choice' ? json['answer'] as int : -1,
        words = [for (final w in json['words'] as List? ?? const []) w as String],
        sentence = json['type'] == 'order' ? json['answer'] as String : '',
        before = json['before'] as String? ?? '',
        after = json['after'] as String? ?? '',
        example = json['example'] as String?,
        sound = json['sound'] as String?;

  final String kind;
  final String prompt;
  final List<String> choices;
  final int rightChoice;
  final List<String> words;
  final String sentence;
  final String before;
  final String after;
  final String? example;
  final String? sound;

  bool get isOrder => kind == 'order';
  String get rightText => isOrder ? sentence : choices[rightChoice];
}

class Level {
  Level(this.json)
      : lessons = _lessons(json),
        cast = {
          for (final e in (json['cast'] as Json? ?? const {}).entries)
            e.key: CastMember.fromJson(e.value as Json),
        };

  final Json json;
  final List<Lesson> lessons;
  final Map<String, CastMember> cast;

  String get slug => json['slug'] as String;
  String get name => json['name'] as String;
  String get cefr => json['cefr'] as String;
  String get stage => json['stage'] as String;
  bool get isStarter => json.containsKey('phonics');

  List<Unit> get units => [
        for (final u in (json['units'] as List? ?? const []))
          Unit((u as Json)['unit'] as int, u['title'] as String),
      ];

  static List<Lesson> _lessons(Json json) {
    final raw = <Json>[
      ...?(json['lessons'] as List?)?.cast<Json>(),
      ...?(json['phonics'] as List?)?.cast<Json>(),
      ...?(json['speaking'] as List?)?.cast<Json>(),
    ];
    return [for (var i = 0; i < raw.length; i++) Lesson(raw[i], position: i + 1, count: raw.length)];
  }
}
