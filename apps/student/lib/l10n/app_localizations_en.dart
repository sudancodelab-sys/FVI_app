// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Future Vision Institute';

  @override
  String get courseEnglish => 'English';

  @override
  String courseEnglishSub(int count) {
    return 'Languages · $count levels on the CEFR scale';
  }

  @override
  String lessonsCount(int count) {
    return '$count lessons';
  }

  @override
  String unitN(int n) {
    return 'Unit $n';
  }

  @override
  String lessonNofM(int n, int m) {
    return 'Lesson $n of $m';
  }

  @override
  String get inArabic => 'Explained in Arabic';

  @override
  String get nextLesson => 'Next lesson';

  @override
  String get previousLesson => 'Previous lesson';

  @override
  String get phonicsPart => 'Part 1: Phonics';

  @override
  String get speakingPart => 'Part 2: Speaking';

  @override
  String get stagePreIntermediate => 'Pre-Intermediate';

  @override
  String get stageIntermediate => 'Intermediate';

  @override
  String get stageAdvanced => 'Advanced';

  @override
  String get appLanguage => 'App language';

  @override
  String get otherLanguage => 'العربية';

  @override
  String get exercises => 'Exercises';

  @override
  String exercisesN(int count) {
    return 'Exercises · $count';
  }

  @override
  String get howQuestion => 'Choose the right answer.';

  @override
  String get howMeaning => 'What does this word mean?';

  @override
  String get howIdiom => 'What does this mean?';

  @override
  String get howForm => 'Complete the sentence as in the story.';

  @override
  String get howReply => 'Choose the right reply.';

  @override
  String get howOrder => 'Put the words in order.';

  @override
  String get check => 'Check';

  @override
  String get next => 'Next';

  @override
  String get seeScore => 'See your score';

  @override
  String get right => 'Right!';

  @override
  String get rightAnswer => 'The right answer:';

  @override
  String nOfM(int n, int m) {
    return '$n of $m';
  }

  @override
  String get exercisesDone => 'You finished the exercises of this lesson.';

  @override
  String get allRight => 'All right!';

  @override
  String get doAgain => 'Do them again';

  @override
  String get backToLesson => 'Back to the lesson';

  @override
  String get howLetters => 'Which letters complete the word?';

  @override
  String get howSilent => 'Which letter is silent?';
}
