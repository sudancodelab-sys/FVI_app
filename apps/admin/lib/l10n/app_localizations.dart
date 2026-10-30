import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar')];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة معهد الرؤية'**
  String get appTitle;

  /// No description provided for @adminBadge.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق الإدارة'**
  String get adminBadge;

  /// No description provided for @lockTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز الدخول'**
  String get lockTitle;

  /// No description provided for @lockSub.
  ///
  /// In ar, this message translates to:
  /// **'أو استخدم بصمة الهاتف'**
  String get lockSub;

  /// No description provided for @lockSubPin.
  ///
  /// In ar, this message translates to:
  /// **'رمز من 4 أرقام'**
  String get lockSubPin;

  /// No description provided for @wrongPin.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح.'**
  String get wrongPin;

  /// No description provided for @createPinTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر رمز الدخول'**
  String get createPinTitle;

  /// No description provided for @createPinSub.
  ///
  /// In ar, this message translates to:
  /// **'4 أرقام تفتح بها تطبيق الإدارة'**
  String get createPinSub;

  /// No description provided for @confirmPinTitle.
  ///
  /// In ar, this message translates to:
  /// **'أعد كتابة الرمز'**
  String get confirmPinTitle;

  /// No description provided for @pinMismatch.
  ///
  /// In ar, this message translates to:
  /// **'الرمزان مختلفان. اختر الرمز مرة أخرى.'**
  String get pinMismatch;

  /// No description provided for @useBiometrics.
  ///
  /// In ar, this message translates to:
  /// **'البصمة'**
  String get useBiometrics;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @setupTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعداد تطبيق الإدارة'**
  String get setupTitle;

  /// No description provided for @setupText.
  ///
  /// In ar, this message translates to:
  /// **'مفاتيح المعهد تُصنع مرة واحدة على هذا الهاتف، وبها تُختم الأكواد. احفظ بعدها نسخة احتياطية خارج الهاتف.'**
  String get setupText;

  /// No description provided for @createKeys.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء مفاتيح المعهد'**
  String get createKeys;

  /// No description provided for @developmentBuild.
  ///
  /// In ar, this message translates to:
  /// **'نسخة تطوير: المفاتيح تجريبية، وأكوادها تفتح النسخة التجريبية من تطبيق الطالب فقط.'**
  String get developmentBuild;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navNew.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل جديد'**
  String get navNew;

  /// No description provided for @navStudents.
  ///
  /// In ar, this message translates to:
  /// **'الطلاب'**
  String get navStudents;

  /// No description provided for @navSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get navSettings;

  /// No description provided for @dashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الإدارة'**
  String get dashboardTitle;

  /// No description provided for @newActivationSub.
  ///
  /// In ar, this message translates to:
  /// **'الصق رسالة الطالب من واتساب'**
  String get newActivationSub;

  /// No description provided for @statActive.
  ///
  /// In ar, this message translates to:
  /// **'طالب مفعّل'**
  String get statActive;

  /// No description provided for @statEnding.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي قريباً'**
  String get statEnding;

  /// No description provided for @statExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get statExpired;

  /// No description provided for @statCodes.
  ///
  /// In ar, this message translates to:
  /// **'كوداً هذا الشهر'**
  String get statCodes;

  /// No description provided for @endingSoon.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي قريباً'**
  String get endingSoon;

  /// No description provided for @seeAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get seeAll;

  /// No description provided for @nothingEnding.
  ///
  /// In ar, this message translates to:
  /// **'لا تفعيلات تنتهي هذا الأسبوع.'**
  String get nothingEnding;

  /// No description provided for @backupDaysAgo.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{آخر نسخة احتياطية اليوم} =1{آخر نسخة احتياطية قبل يوم} =2{آخر نسخة احتياطية قبل يومين} few{آخر نسخة احتياطية قبل {n} أيام} other{آخر نسخة احتياطية قبل {n} يوماً}}'**
  String backupDaysAgo(int n);

  /// No description provided for @backupNever.
  ///
  /// In ar, this message translates to:
  /// **'لم تُنشأ نسخة احتياطية بعد'**
  String get backupNever;

  /// No description provided for @backupNow.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الآن'**
  String get backupNow;

  /// No description provided for @daysLeft.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{اليوم} =1{يوم} =2{يومان} few{{n} أيام} other{{n} يوماً}}'**
  String daysLeft(int n);

  /// No description provided for @pasteRequest.
  ///
  /// In ar, this message translates to:
  /// **'الصق رسالة طلب الطالب هنا'**
  String get pasteRequest;

  /// No description provided for @paste.
  ///
  /// In ar, this message translates to:
  /// **'لصق'**
  String get paste;

  /// No description provided for @noRequest.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رسالة طلب في هذا النص. انسخ رسالة الطالب كاملة من واتساب.'**
  String get noRequest;

  /// No description provided for @studentData.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الطالب'**
  String get studentData;

  /// No description provided for @readFromWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'قُرئت من رسالة واتساب'**
  String get readFromWhatsapp;

  /// No description provided for @name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get phone;

  /// No description provided for @deviceCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز الجهاز'**
  String get deviceCode;

  /// No description provided for @newDevice.
  ///
  /// In ar, this message translates to:
  /// **'جهاز جديد · لم يُفعَّل من قبل'**
  String get newDevice;

  /// No description provided for @knownDevice.
  ///
  /// In ar, this message translates to:
  /// **'سبق تفعيل هذا الجهاز: {name}'**
  String knownDevice(String name);

  /// No description provided for @sameNameOrPhone.
  ///
  /// In ar, this message translates to:
  /// **'الاسم أو الرقم موجود بجهاز آخر ({names}): غالباً أعاد الطالب تثبيت التطبيق، أو غيّر هاتفه.'**
  String sameNameOrPhone(String names);

  /// No description provided for @whatOpens.
  ///
  /// In ar, this message translates to:
  /// **'ما الذي يُفتح للطالب؟'**
  String get whatOpens;

  /// No description provided for @requestedTag.
  ///
  /// In ar, this message translates to:
  /// **'طلبه الطالب'**
  String get requestedTag;

  /// No description provided for @duration.
  ///
  /// In ar, this message translates to:
  /// **'مدة التفعيل'**
  String get duration;

  /// No description provided for @oneMonth.
  ///
  /// In ar, this message translates to:
  /// **'شهر'**
  String get oneMonth;

  /// No description provided for @twoMonths.
  ///
  /// In ar, this message translates to:
  /// **'شهران'**
  String get twoMonths;

  /// No description provided for @threeMonths.
  ///
  /// In ar, this message translates to:
  /// **'3 أشهر'**
  String get threeMonths;

  /// No description provided for @customDate.
  ///
  /// In ar, this message translates to:
  /// **'مخصص'**
  String get customDate;

  /// No description provided for @endsOn.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي في: {date}'**
  String endsOn(String date);

  /// No description provided for @issueAndSend.
  ///
  /// In ar, this message translates to:
  /// **'إصدار الكود وإرساله عبر واتساب'**
  String get issueAndSend;

  /// No description provided for @chooseSomething.
  ///
  /// In ar, this message translates to:
  /// **'اختر ما يُفتح للطالب.'**
  String get chooseSomething;

  /// No description provided for @issued.
  ///
  /// In ar, this message translates to:
  /// **'صدر الكود.'**
  String get issued;

  /// No description provided for @whatsappFailed.
  ///
  /// In ar, this message translates to:
  /// **'لم يُفتح واتساب.'**
  String get whatsappFailed;

  /// No description provided for @copyCode.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الكود'**
  String get copyCode;

  /// No description provided for @copied.
  ///
  /// In ar, this message translates to:
  /// **'نُسخ الكود.'**
  String get copied;

  /// No description provided for @studentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلاب'**
  String get studentsTitle;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو رقم الهاتف'**
  String get search;

  /// No description provided for @filterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In ar, this message translates to:
  /// **'فعّال {n}'**
  String filterActive(int n);

  /// No description provided for @filterSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريباً {n}'**
  String filterSoon(int n);

  /// No description provided for @filterExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهٍ {n}'**
  String filterExpired(int n);

  /// No description provided for @statusActive.
  ///
  /// In ar, this message translates to:
  /// **'فعّال'**
  String get statusActive;

  /// No description provided for @statusExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهٍ'**
  String get statusExpired;

  /// No description provided for @statusNew.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get statusNew;

  /// No description provided for @noStudents.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد طلاب بعد. أول تفعيل يضيف الطالب هنا.'**
  String get noStudents;

  /// No description provided for @noMatch.
  ///
  /// In ar, this message translates to:
  /// **'لا أحد بهذا الاسم أو الرقم.'**
  String get noMatch;

  /// No description provided for @studentTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل الطالب'**
  String get studentTitle;

  /// No description provided for @since.
  ///
  /// In ar, this message translates to:
  /// **'منذ {date}'**
  String since(String date);

  /// No description provided for @deviceChip.
  ///
  /// In ar, this message translates to:
  /// **'رمز الجهاز {code}'**
  String deviceChip(String code);

  /// No description provided for @activations.
  ///
  /// In ar, this message translates to:
  /// **'التفعيلات'**
  String get activations;

  /// No description provided for @ended.
  ///
  /// In ar, this message translates to:
  /// **'انتهى'**
  String get ended;

  /// No description provided for @renewedTag.
  ///
  /// In ar, this message translates to:
  /// **'جُدِّد'**
  String get renewedTag;

  /// No description provided for @period.
  ///
  /// In ar, this message translates to:
  /// **'{from} ← {to}'**
  String period(String from, String to);

  /// No description provided for @renew.
  ///
  /// In ar, this message translates to:
  /// **'تجديد {label}'**
  String renew(String label);

  /// No description provided for @moreContent.
  ///
  /// In ar, this message translates to:
  /// **'فتح محتوى إضافي'**
  String get moreContent;

  /// No description provided for @resendLast.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال آخر كود عبر واتساب'**
  String get resendLast;

  /// No description provided for @renewTitle.
  ///
  /// In ar, this message translates to:
  /// **'تجديد'**
  String get renewTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @backupSection.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get backupSection;

  /// No description provided for @makeBackup.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء نسخة احتياطية'**
  String get makeBackup;

  /// No description provided for @makeBackupSub.
  ///
  /// In ar, this message translates to:
  /// **'السجل + مفاتيح المعهد، مشفّرة بكلمة سر'**
  String get makeBackupSub;

  /// No description provided for @restore.
  ///
  /// In ar, this message translates to:
  /// **'استعادة من نسخة احتياطية'**
  String get restore;

  /// No description provided for @restoreSub.
  ///
  /// In ar, this message translates to:
  /// **'عند تغيير هاتف الإدارة'**
  String get restoreSub;

  /// No description provided for @whatsappSection.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get whatsappSection;

  /// No description provided for @whatsappNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم طلبات التفعيل'**
  String get whatsappNumber;

  /// No description provided for @change.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get change;

  /// No description provided for @whatsappNote.
  ///
  /// In ar, this message translates to:
  /// **'عند تغيير الرقم، يحمل كل كود جديد الرقم الجديد، فيتحدّث عند الطلاب المفعّلين تلقائياً.'**
  String get whatsappNote;

  /// No description provided for @security.
  ///
  /// In ar, this message translates to:
  /// **'الأمان'**
  String get security;

  /// No description provided for @biometricLogin.
  ///
  /// In ar, this message translates to:
  /// **'الدخول بالبصمة'**
  String get biometricLogin;

  /// No description provided for @changePin.
  ///
  /// In ar, this message translates to:
  /// **'تغيير رمز الدخول'**
  String get changePin;

  /// No description provided for @sealKey.
  ///
  /// In ar, this message translates to:
  /// **'مفتاح الختم'**
  String get sealKey;

  /// No description provided for @sealKeySub.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ ومشفّر على هذا الهاتف'**
  String get sealKeySub;

  /// No description provided for @sealOk.
  ///
  /// In ar, this message translates to:
  /// **'سليم'**
  String get sealOk;

  /// No description provided for @sealDevelopment.
  ///
  /// In ar, this message translates to:
  /// **'تجريبي'**
  String get sealDevelopment;

  /// No description provided for @lockNow.
  ///
  /// In ar, this message translates to:
  /// **'قفل التطبيق'**
  String get lockNow;

  /// No description provided for @backupPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة سر النسخة الاحتياطية'**
  String get backupPassword;

  /// No description provided for @passwordHint.
  ///
  /// In ar, this message translates to:
  /// **'8 أحرف على الأقل. احفظها في مكان آمن: بدونها لا تُفتح النسخة.'**
  String get passwordHint;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر قصيرة: 8 أحرف على الأقل.'**
  String get passwordTooShort;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @backupMade.
  ///
  /// In ar, this message translates to:
  /// **'أُنشئت النسخة الاحتياطية. احفظ الملف خارج الهاتف.'**
  String get backupMade;

  /// No description provided for @restoreDone.
  ///
  /// In ar, this message translates to:
  /// **'تمت الاستعادة.'**
  String get restoreDone;

  /// No description provided for @wrongPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر غير صحيحة.'**
  String get wrongPassword;

  /// No description provided for @notBackup.
  ///
  /// In ar, this message translates to:
  /// **'هذا الملف ليس نسخة احتياطية لتطبيق الإدارة.'**
  String get notBackup;

  /// No description provided for @restoreWarning.
  ///
  /// In ar, this message translates to:
  /// **'الاستعادة تستبدل كل ما في هذا الهاتف بما في النسخة.'**
  String get restoreWarning;

  /// No description provided for @openRestore.
  ///
  /// In ar, this message translates to:
  /// **'اختر الملف'**
  String get openRestore;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return L10nAr();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
