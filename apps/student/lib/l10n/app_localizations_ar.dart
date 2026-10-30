// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class L10nAr extends L10n {
  L10nAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'معهد الرؤية المستقبلية';

  @override
  String get courseEnglish => 'اللغة الإنجليزية';

  @override
  String courseEnglishSub(int count) {
    return 'قسم اللغات · $count مستويات وفق إطار CEFR';
  }

  @override
  String lessonsCount(int count) {
    return '$count درساً';
  }

  @override
  String unitN(int n) {
    return 'الوحدة $n';
  }

  @override
  String lessonNofM(int n, int m) {
    return 'الدرس $n من $m';
  }

  @override
  String get inArabic => 'الشرح بالعربية';

  @override
  String get nextLesson => 'الدرس التالي';

  @override
  String get previousLesson => 'الدرس السابق';

  @override
  String get phonicsPart => 'الجزء الأول: الصوتيات';

  @override
  String get speakingPart => 'الجزء الثاني: المخاطبة';

  @override
  String get stagePreIntermediate => 'ما قبل المتوسط';

  @override
  String get stageIntermediate => 'المتوسط';

  @override
  String get stageAdvanced => 'المتقدم';

  @override
  String get appLanguage => 'لغة التطبيق';

  @override
  String get otherLanguage => 'English';

  @override
  String get exercises => 'التمارين';

  @override
  String exercisesN(int count) {
    return 'التمارين · $count';
  }

  @override
  String get howQuestion => 'اختر الجواب الصحيح حسب الدرس';

  @override
  String get howMeaning => 'ما معنى هذه الكلمة؟';

  @override
  String get howIdiom => 'ما معنى هذا التعبير؟';

  @override
  String get howForm => 'أكمل الجملة كما جاءت في القصة';

  @override
  String get howReply => 'اختر الردّ المناسب';

  @override
  String get howOrder => 'رتّب الكلمات لتكوّن العبارة';

  @override
  String get check => 'تحقّق';

  @override
  String get next => 'التالي';

  @override
  String get seeScore => 'النتيجة';

  @override
  String get right => 'صحيح';

  @override
  String get rightAnswer => 'الجواب الصحيح:';

  @override
  String nOfM(int n, int m) {
    return '$n من $m';
  }

  @override
  String get exercisesDone => 'انتهت تمارين الدرس.';

  @override
  String get allRight => 'كلها صحيحة.';

  @override
  String get doAgain => 'أعد التمارين';

  @override
  String get backToLesson => 'العودة إلى الدرس';
}
