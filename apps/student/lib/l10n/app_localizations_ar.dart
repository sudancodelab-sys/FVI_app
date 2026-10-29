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
  String get listenAll => 'استمع للدرس كله';

  @override
  String get stopListening => 'إيقاف';

  @override
  String get inArabic => 'الشرح بالعربية';

  @override
  String get audioMissing => 'صوت هذا الجزء لم يُضف بعد.';

  @override
  String get nextLesson => 'الدرس التالي';

  @override
  String get previousLesson => 'الدرس السابق';

  @override
  String get phonicsPart => 'الجزء الأول: الصوتيات';

  @override
  String get speakingPart => 'الجزء الثاني: المخاطبة';

  @override
  String get play => 'استمع';

  @override
  String get stagePreIntermediate => 'ما قبل المتوسط';

  @override
  String get stageIntermediate => 'المتوسط';

  @override
  String get stageAdvanced => 'المتقدم';
}
