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

  @override
  String get howLetters => 'اختر الحروف التي تكمل الكلمة';

  @override
  String get howSilent => 'أيّ حرف لا يُنطق؟';

  @override
  String get welcomeName => 'معهد الرؤية المستقبلية';

  @override
  String get welcomeNameSub => 'للحاسوب واللغات';

  @override
  String get welcomeTagline => 'تطبيق المذاكرة والمراجعة';

  @override
  String get chooseLanguage => 'اختر لغة التطبيق';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageEnglishSub => 'Left-to-right interface';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageArabicSub => 'الواجهة من اليمين إلى اليسار';

  @override
  String get continueButton => 'متابعة';

  @override
  String versionN(String v) {
    return 'الإصدار $v';
  }

  @override
  String get requestTitle => 'طلب التفعيل';

  @override
  String get requestIntro =>
      'أدخل بياناتك، وسيصل طلبك إلى إدارة المعهد عبر واتساب لإصدار كود التفعيل.';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get yourLevel => 'المستوى الذي تدرس فيه';

  @override
  String levelOption(String course, String level) {
    return '$course · $level';
  }

  @override
  String get deviceCodeLabel => 'رمز جهازك';

  @override
  String get deviceCodeNote =>
      'يُرسل الرمز تلقائياً مع الطلب، ويربط التفعيل بهذا الهاتف فقط.';

  @override
  String get requestOnWhatsapp => 'اطلب التفعيل عبر واتساب';

  @override
  String get haveCode => 'لديّ كود تفعيل بالفعل';

  @override
  String get nameNeeded => 'اكتب اسمك الكامل.';

  @override
  String get phoneNeeded => 'اكتب رقم هاتفك.';

  @override
  String get levelNeeded => 'اختر مستواك.';

  @override
  String get messageHeading => 'طلب تفعيل تطبيق FVI';

  @override
  String messageName(String v) {
    return 'الاسم: $v';
  }

  @override
  String messagePhone(String v) {
    return 'الهاتف: $v';
  }

  @override
  String messageLevel(String v) {
    return 'المستوى: $v';
  }

  @override
  String messageDevice(String v) {
    return 'رمز الجهاز: $v';
  }

  @override
  String get whatsappFailed => 'لم يُفتح واتساب. هل هو مثبّت على هذا الهاتف؟';

  @override
  String get activateTitle => 'تفعيل التطبيق';

  @override
  String get waitingTitle => 'بانتظار كود التفعيل';

  @override
  String get waitingText =>
      'عندما يصلك رد الإدارة في واتساب، انسخ الرسالة ثم ارجع إلى التطبيق، وسيجد الكود تلقائياً.';

  @override
  String get stepDetails => 'إدخال البيانات';

  @override
  String get stepSent => 'إرسال الطلب عبر واتساب';

  @override
  String get stepCode => 'استلام كود التفعيل من الإدارة';

  @override
  String get orEnterCode => 'أو أدخل الكود يدوياً';

  @override
  String get pasteHere => 'الصق كود التفعيل هنا';

  @override
  String get paste => 'لصق';

  @override
  String get activate => 'تفعيل';

  @override
  String get sendAgain => 'إعادة إرسال الطلب';

  @override
  String get codeFound => 'وُجد كود تفعيل فيما نسخته.';

  @override
  String get problemNoCode =>
      'لا يوجد كود تفعيل في هذا النص. انسخ رسالة الإدارة كاملة وحاول مرة أخرى.';

  @override
  String get problemOtherInstitute =>
      'هذا الكود ليس من معهد الرؤية المستقبلية.';

  @override
  String get problemAltered =>
      'تغيّر هذا الكود بعد إرساله. انسخه مرة أخرى من الرسالة.';

  @override
  String get problemOtherPhone =>
      'هذا الكود لهاتف آخر، أو لهذا الهاتف قبل إعادة تثبيت التطبيق. أرسل طلباً جديداً.';

  @override
  String get problemClock =>
      'تاريخ هاتفك غير صحيح. صحّحه من إعدادات الهاتف ثم حاول مرة أخرى.';

  @override
  String get activated => 'تم تفعيل التطبيق.';

  @override
  String get clockTitle => 'صحّح تاريخ هاتفك';

  @override
  String get clockText =>
      'تاريخ هاتفك أقدم من تاريخ رآه التطبيق من قبل، فأُغلقت المستويات. صحّح التاريخ من إعدادات الهاتف، أو اطلب كوداً جديداً من الإدارة.';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get enterCode => 'أدخل كود تفعيل';

  @override
  String get lockedTitle => 'هذا المستوى مقفل';

  @override
  String lockedText(String level) {
    return 'اطلب من إدارة المعهد تفعيل $level لك.';
  }

  @override
  String get expiredTitle => 'انتهى تفعيل هذا المستوى';

  @override
  String expiredText(String level) {
    return 'اطلب من الإدارة تجديد $level. تقدّمك محفوظ.';
  }

  @override
  String get renewOnWhatsapp => 'اطلب التجديد عبر واتساب';

  @override
  String endsOn(String level, String date) {
    return 'ينتهي تفعيل $level في $date.';
  }

  @override
  String openUntil(String date) {
    return 'مفتوح حتى $date';
  }

  @override
  String get developmentBuild => 'نسخة تطوير: تقبل الأكواد التجريبية فقط.';
}
