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
  String get listenAll => 'Listen to the whole lesson';

  @override
  String get stopListening => 'Stop';

  @override
  String get inArabic => 'Explained in Arabic';

  @override
  String get audioMissing => 'The audio for this part has not been added yet.';

  @override
  String get nextLesson => 'Next lesson';

  @override
  String get previousLesson => 'Previous lesson';

  @override
  String get phonicsPart => 'Part 1: Phonics';

  @override
  String get speakingPart => 'Part 2: Speaking';

  @override
  String get play => 'Listen';

  @override
  String get stagePreIntermediate => 'Pre-Intermediate';

  @override
  String get stageIntermediate => 'Intermediate';

  @override
  String get stageAdvanced => 'Advanced';
}
