// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class L10nAr extends L10n {
  L10nAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'إدارة معهد الرؤية';

  @override
  String get adminBadge => 'تطبيق الإدارة';

  @override
  String get lockTitle => 'أدخل رمز الدخول';

  @override
  String get lockSub => 'أو استخدم بصمة الهاتف';

  @override
  String get lockSubPin => 'رمز من 4 أرقام';

  @override
  String get wrongPin => 'الرمز غير صحيح.';

  @override
  String get createPinTitle => 'اختر رمز الدخول';

  @override
  String get createPinSub => '4 أرقام تفتح بها تطبيق الإدارة';

  @override
  String get confirmPinTitle => 'أعد كتابة الرمز';

  @override
  String get pinMismatch => 'الرمزان مختلفان. اختر الرمز مرة أخرى.';

  @override
  String get useBiometrics => 'البصمة';

  @override
  String get delete => 'حذف';

  @override
  String get setupTitle => 'إعداد تطبيق الإدارة';

  @override
  String get setupText =>
      'مفاتيح المعهد تُصنع مرة واحدة على هذا الهاتف، وبها تُختم الأكواد. احفظ بعدها نسخة احتياطية خارج الهاتف.';

  @override
  String get createKeys => 'إنشاء مفاتيح المعهد';

  @override
  String get developmentBuild =>
      'نسخة تطوير: المفاتيح تجريبية، وأكوادها تفتح النسخة التجريبية من تطبيق الطالب فقط.';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navNew => 'تفعيل جديد';

  @override
  String get navStudents => 'الطلاب';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get dashboardTitle => 'لوحة الإدارة';

  @override
  String get newActivationSub => 'الصق رسالة الطالب من واتساب';

  @override
  String get statActive => 'طالب مفعّل';

  @override
  String get statEnding => 'تنتهي قريباً';

  @override
  String get statExpired => 'منتهية';

  @override
  String get statCodes => 'كوداً هذا الشهر';

  @override
  String get endingSoon => 'تنتهي قريباً';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get nothingEnding => 'لا تفعيلات تنتهي هذا الأسبوع.';

  @override
  String backupDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'آخر نسخة احتياطية قبل $n يوماً',
      few: 'آخر نسخة احتياطية قبل $n أيام',
      two: 'آخر نسخة احتياطية قبل يومين',
      one: 'آخر نسخة احتياطية قبل يوم',
      zero: 'آخر نسخة احتياطية اليوم',
    );
    return '$_temp0';
  }

  @override
  String get backupNever => 'لم تُنشأ نسخة احتياطية بعد';

  @override
  String get backupNow => 'نسخ الآن';

  @override
  String daysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يوماً',
      few: '$n أيام',
      two: 'يومان',
      one: 'يوم',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String get pasteRequest => 'الصق رسالة طلب الطالب هنا';

  @override
  String get paste => 'لصق';

  @override
  String get noRequest =>
      'لا توجد رسالة طلب في هذا النص. انسخ رسالة الطالب كاملة من واتساب.';

  @override
  String get studentData => 'بيانات الطالب';

  @override
  String get readFromWhatsapp => 'قُرئت من رسالة واتساب';

  @override
  String get name => 'الاسم';

  @override
  String get phone => 'الهاتف';

  @override
  String get deviceCode => 'رمز الجهاز';

  @override
  String get newDevice => 'جهاز جديد · لم يُفعَّل من قبل';

  @override
  String knownDevice(String name) {
    return 'سبق تفعيل هذا الجهاز: $name';
  }

  @override
  String sameNameOrPhone(String names) {
    return 'الاسم أو الرقم موجود بجهاز آخر ($names): غالباً أعاد الطالب تثبيت التطبيق، أو غيّر هاتفه.';
  }

  @override
  String get whatOpens => 'ما الذي يُفتح للطالب؟';

  @override
  String get requestedTag => 'طلبه الطالب';

  @override
  String get duration => 'مدة التفعيل';

  @override
  String get oneMonth => 'شهر';

  @override
  String get twoMonths => 'شهران';

  @override
  String get threeMonths => '3 أشهر';

  @override
  String get customDate => 'مخصص';

  @override
  String endsOn(String date) {
    return 'ينتهي في: $date';
  }

  @override
  String get issueAndSend => 'إصدار الكود وإرساله عبر واتساب';

  @override
  String get chooseSomething => 'اختر ما يُفتح للطالب.';

  @override
  String get issued => 'صدر الكود.';

  @override
  String get whatsappFailed => 'لم يُفتح واتساب.';

  @override
  String get copyCode => 'نسخ الكود';

  @override
  String get copied => 'نُسخ الكود.';

  @override
  String get studentsTitle => 'الطلاب';

  @override
  String get search => 'ابحث بالاسم أو رقم الهاتف';

  @override
  String get filterAll => 'الكل';

  @override
  String filterActive(int n) {
    return 'فعّال $n';
  }

  @override
  String filterSoon(int n) {
    return 'قريباً $n';
  }

  @override
  String filterExpired(int n) {
    return 'منتهٍ $n';
  }

  @override
  String get statusActive => 'فعّال';

  @override
  String get statusExpired => 'منتهٍ';

  @override
  String get statusNew => 'جديد';

  @override
  String get noStudents => 'لا يوجد طلاب بعد. أول تفعيل يضيف الطالب هنا.';

  @override
  String get noMatch => 'لا أحد بهذا الاسم أو الرقم.';

  @override
  String get studentTitle => 'سجل الطالب';

  @override
  String since(String date) {
    return 'منذ $date';
  }

  @override
  String deviceChip(String code) {
    return 'رمز الجهاز $code';
  }

  @override
  String get activations => 'التفعيلات';

  @override
  String get ended => 'انتهى';

  @override
  String get renewedTag => 'جُدِّد';

  @override
  String period(String from, String to) {
    return '$from ← $to';
  }

  @override
  String renew(String label) {
    return 'تجديد $label';
  }

  @override
  String get moreContent => 'فتح محتوى إضافي';

  @override
  String get resendLast => 'إعادة إرسال آخر كود عبر واتساب';

  @override
  String get renewTitle => 'تجديد';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get backupSection => 'النسخ الاحتياطي';

  @override
  String get makeBackup => 'إنشاء نسخة احتياطية';

  @override
  String get makeBackupSub => 'السجل + مفاتيح المعهد، مشفّرة بكلمة سر';

  @override
  String get restore => 'استعادة من نسخة احتياطية';

  @override
  String get restoreSub => 'عند تغيير هاتف الإدارة';

  @override
  String get whatsappSection => 'واتساب';

  @override
  String get whatsappNumber => 'رقم طلبات التفعيل';

  @override
  String get change => 'تغيير';

  @override
  String get whatsappNote =>
      'عند تغيير الرقم، يحمل كل كود جديد الرقم الجديد، فيتحدّث عند الطلاب المفعّلين تلقائياً.';

  @override
  String get security => 'الأمان';

  @override
  String get biometricLogin => 'الدخول بالبصمة';

  @override
  String get changePin => 'تغيير رمز الدخول';

  @override
  String get sealKey => 'مفتاح الختم';

  @override
  String get sealKeySub => 'محفوظ ومشفّر على هذا الهاتف';

  @override
  String get sealOk => 'سليم';

  @override
  String get sealDevelopment => 'تجريبي';

  @override
  String get lockNow => 'قفل التطبيق';

  @override
  String get backupPassword => 'كلمة سر النسخة الاحتياطية';

  @override
  String get passwordHint =>
      '8 أحرف على الأقل. احفظها في مكان آمن: بدونها لا تُفتح النسخة.';

  @override
  String get passwordTooShort => 'كلمة السر قصيرة: 8 أحرف على الأقل.';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get backupMade => 'أُنشئت النسخة الاحتياطية. احفظ الملف خارج الهاتف.';

  @override
  String get restoreDone => 'تمت الاستعادة.';

  @override
  String get wrongPassword => 'كلمة السر غير صحيحة.';

  @override
  String get notBackup => 'هذا الملف ليس نسخة احتياطية لتطبيق الإدارة.';

  @override
  String get restoreWarning =>
      'الاستعادة تستبدل كل ما في هذا الهاتف بما في النسخة.';

  @override
  String get openRestore => 'اختر الملف';
}
