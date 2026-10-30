import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'معهد الرؤية المستقبلية'**
  String get appTitle;

  /// No description provided for @courseEnglish.
  ///
  /// In ar, this message translates to:
  /// **'اللغة الإنجليزية'**
  String get courseEnglish;

  /// No description provided for @courseEnglishSub.
  ///
  /// In ar, this message translates to:
  /// **'قسم اللغات · {count} مستويات وفق إطار CEFR'**
  String courseEnglishSub(int count);

  /// No description provided for @lessonsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} درساً'**
  String lessonsCount(int count);

  /// No description provided for @unitN.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة {n}'**
  String unitN(int n);

  /// No description provided for @lessonNofM.
  ///
  /// In ar, this message translates to:
  /// **'الدرس {n} من {m}'**
  String lessonNofM(int n, int m);

  /// No description provided for @inArabic.
  ///
  /// In ar, this message translates to:
  /// **'الشرح بالعربية'**
  String get inArabic;

  /// No description provided for @nextLesson.
  ///
  /// In ar, this message translates to:
  /// **'الدرس التالي'**
  String get nextLesson;

  /// No description provided for @previousLesson.
  ///
  /// In ar, this message translates to:
  /// **'الدرس السابق'**
  String get previousLesson;

  /// No description provided for @phonicsPart.
  ///
  /// In ar, this message translates to:
  /// **'الجزء الأول: الصوتيات'**
  String get phonicsPart;

  /// No description provided for @speakingPart.
  ///
  /// In ar, this message translates to:
  /// **'الجزء الثاني: المخاطبة'**
  String get speakingPart;

  /// No description provided for @stagePreIntermediate.
  ///
  /// In ar, this message translates to:
  /// **'ما قبل المتوسط'**
  String get stagePreIntermediate;

  /// No description provided for @stageIntermediate.
  ///
  /// In ar, this message translates to:
  /// **'المتوسط'**
  String get stageIntermediate;

  /// No description provided for @stageAdvanced.
  ///
  /// In ar, this message translates to:
  /// **'المتقدم'**
  String get stageAdvanced;

  /// No description provided for @appLanguage.
  ///
  /// In ar, this message translates to:
  /// **'لغة التطبيق'**
  String get appLanguage;

  /// No description provided for @otherLanguage.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get otherLanguage;

  /// No description provided for @exercises.
  ///
  /// In ar, this message translates to:
  /// **'التمارين'**
  String get exercises;

  /// No description provided for @exercisesN.
  ///
  /// In ar, this message translates to:
  /// **'التمارين · {count}'**
  String exercisesN(int count);

  /// No description provided for @howQuestion.
  ///
  /// In ar, this message translates to:
  /// **'اختر الجواب الصحيح حسب الدرس'**
  String get howQuestion;

  /// No description provided for @howMeaning.
  ///
  /// In ar, this message translates to:
  /// **'ما معنى هذه الكلمة؟'**
  String get howMeaning;

  /// No description provided for @howIdiom.
  ///
  /// In ar, this message translates to:
  /// **'ما معنى هذا التعبير؟'**
  String get howIdiom;

  /// No description provided for @howForm.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الجملة كما جاءت في القصة'**
  String get howForm;

  /// No description provided for @howReply.
  ///
  /// In ar, this message translates to:
  /// **'اختر الردّ المناسب'**
  String get howReply;

  /// No description provided for @howOrder.
  ///
  /// In ar, this message translates to:
  /// **'رتّب الكلمات لتكوّن العبارة'**
  String get howOrder;

  /// No description provided for @check.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق'**
  String get check;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @seeScore.
  ///
  /// In ar, this message translates to:
  /// **'النتيجة'**
  String get seeScore;

  /// No description provided for @right.
  ///
  /// In ar, this message translates to:
  /// **'صحيح'**
  String get right;

  /// No description provided for @rightAnswer.
  ///
  /// In ar, this message translates to:
  /// **'الجواب الصحيح:'**
  String get rightAnswer;

  /// No description provided for @nOfM.
  ///
  /// In ar, this message translates to:
  /// **'{n} من {m}'**
  String nOfM(int n, int m);

  /// No description provided for @exercisesDone.
  ///
  /// In ar, this message translates to:
  /// **'انتهت تمارين الدرس.'**
  String get exercisesDone;

  /// No description provided for @allRight.
  ///
  /// In ar, this message translates to:
  /// **'كلها صحيحة.'**
  String get allRight;

  /// No description provided for @doAgain.
  ///
  /// In ar, this message translates to:
  /// **'أعد التمارين'**
  String get doAgain;

  /// No description provided for @backToLesson.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلى الدرس'**
  String get backToLesson;

  /// No description provided for @howLetters.
  ///
  /// In ar, this message translates to:
  /// **'اختر الحروف التي تكمل الكلمة'**
  String get howLetters;

  /// No description provided for @howSilent.
  ///
  /// In ar, this message translates to:
  /// **'أيّ حرف لا يُنطق؟'**
  String get howSilent;

  /// No description provided for @welcomeName.
  ///
  /// In ar, this message translates to:
  /// **'معهد الرؤية المستقبلية'**
  String get welcomeName;

  /// No description provided for @welcomeNameSub.
  ///
  /// In ar, this message translates to:
  /// **'للحاسوب واللغات'**
  String get welcomeNameSub;

  /// No description provided for @welcomeTagline.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق المذاكرة والمراجعة'**
  String get welcomeTagline;

  /// No description provided for @chooseLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اختر لغة التطبيق'**
  String get chooseLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageEnglishSub.
  ///
  /// In ar, this message translates to:
  /// **'Left-to-right interface'**
  String get languageEnglishSub;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageArabicSub.
  ///
  /// In ar, this message translates to:
  /// **'الواجهة من اليمين إلى اليسار'**
  String get languageArabicSub;

  /// No description provided for @continueButton.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueButton;

  /// No description provided for @versionN.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {v}'**
  String versionN(String v);

  /// No description provided for @requestTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب التفعيل'**
  String get requestTitle;

  /// No description provided for @requestIntro.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بياناتك، وسيصل طلبك إلى إدارة المعهد عبر واتساب لإصدار كود التفعيل.'**
  String get requestIntro;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneNumber;

  /// No description provided for @yourLevel.
  ///
  /// In ar, this message translates to:
  /// **'المستوى الذي تدرس فيه'**
  String get yourLevel;

  /// No description provided for @levelOption.
  ///
  /// In ar, this message translates to:
  /// **'{course} · {level}'**
  String levelOption(String course, String level);

  /// No description provided for @deviceCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز جهازك'**
  String get deviceCodeLabel;

  /// No description provided for @deviceCodeNote.
  ///
  /// In ar, this message translates to:
  /// **'يُرسل الرمز تلقائياً مع الطلب، ويربط التفعيل بهذا الهاتف فقط.'**
  String get deviceCodeNote;

  /// No description provided for @requestOnWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'اطلب التفعيل عبر واتساب'**
  String get requestOnWhatsapp;

  /// No description provided for @haveCode.
  ///
  /// In ar, this message translates to:
  /// **'لديّ كود تفعيل بالفعل'**
  String get haveCode;

  /// No description provided for @nameNeeded.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسمك الكامل.'**
  String get nameNeeded;

  /// No description provided for @phoneNeeded.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقم هاتفك.'**
  String get phoneNeeded;

  /// No description provided for @levelNeeded.
  ///
  /// In ar, this message translates to:
  /// **'اختر مستواك.'**
  String get levelNeeded;

  /// No description provided for @messageHeading.
  ///
  /// In ar, this message translates to:
  /// **'طلب تفعيل تطبيق FVI'**
  String get messageHeading;

  /// No description provided for @messageName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم: {v}'**
  String messageName(String v);

  /// No description provided for @messagePhone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف: {v}'**
  String messagePhone(String v);

  /// No description provided for @messageLevel.
  ///
  /// In ar, this message translates to:
  /// **'المستوى: {v}'**
  String messageLevel(String v);

  /// No description provided for @messageDevice.
  ///
  /// In ar, this message translates to:
  /// **'رمز الجهاز: {v}'**
  String messageDevice(String v);

  /// No description provided for @whatsappFailed.
  ///
  /// In ar, this message translates to:
  /// **'لم يُفتح واتساب. هل هو مثبّت على هذا الهاتف؟'**
  String get whatsappFailed;

  /// No description provided for @activateTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل التطبيق'**
  String get activateTitle;

  /// No description provided for @waitingTitle.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار كود التفعيل'**
  String get waitingTitle;

  /// No description provided for @waitingText.
  ///
  /// In ar, this message translates to:
  /// **'عندما يصلك رد الإدارة في واتساب، انسخ الرسالة ثم ارجع إلى التطبيق، وسيجد الكود تلقائياً.'**
  String get waitingText;

  /// No description provided for @stepDetails.
  ///
  /// In ar, this message translates to:
  /// **'إدخال البيانات'**
  String get stepDetails;

  /// No description provided for @stepSent.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب عبر واتساب'**
  String get stepSent;

  /// No description provided for @stepCode.
  ///
  /// In ar, this message translates to:
  /// **'استلام كود التفعيل من الإدارة'**
  String get stepCode;

  /// No description provided for @orEnterCode.
  ///
  /// In ar, this message translates to:
  /// **'أو أدخل الكود يدوياً'**
  String get orEnterCode;

  /// No description provided for @pasteHere.
  ///
  /// In ar, this message translates to:
  /// **'الصق كود التفعيل هنا'**
  String get pasteHere;

  /// No description provided for @paste.
  ///
  /// In ar, this message translates to:
  /// **'لصق'**
  String get paste;

  /// No description provided for @activate.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get activate;

  /// No description provided for @sendAgain.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الطلب'**
  String get sendAgain;

  /// No description provided for @codeFound.
  ///
  /// In ar, this message translates to:
  /// **'وُجد كود تفعيل فيما نسخته.'**
  String get codeFound;

  /// No description provided for @problemNoCode.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد كود تفعيل في هذا النص. انسخ رسالة الإدارة كاملة وحاول مرة أخرى.'**
  String get problemNoCode;

  /// No description provided for @problemOtherInstitute.
  ///
  /// In ar, this message translates to:
  /// **'هذا الكود ليس من معهد الرؤية المستقبلية.'**
  String get problemOtherInstitute;

  /// No description provided for @problemAltered.
  ///
  /// In ar, this message translates to:
  /// **'تغيّر هذا الكود بعد إرساله. انسخه مرة أخرى من الرسالة.'**
  String get problemAltered;

  /// No description provided for @problemOtherPhone.
  ///
  /// In ar, this message translates to:
  /// **'هذا الكود لهاتف آخر، أو لهذا الهاتف قبل إعادة تثبيت التطبيق. أرسل طلباً جديداً.'**
  String get problemOtherPhone;

  /// No description provided for @problemClock.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ هاتفك غير صحيح. صحّحه من إعدادات الهاتف ثم حاول مرة أخرى.'**
  String get problemClock;

  /// No description provided for @activated.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل التطبيق.'**
  String get activated;

  /// No description provided for @clockTitle.
  ///
  /// In ar, this message translates to:
  /// **'صحّح تاريخ هاتفك'**
  String get clockTitle;

  /// No description provided for @clockText.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ هاتفك أقدم من تاريخ رآه التطبيق من قبل، فأُغلقت المستويات. صحّح التاريخ من إعدادات الهاتف، أو اطلب كوداً جديداً من الإدارة.'**
  String get clockText;

  /// No description provided for @tryAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get tryAgain;

  /// No description provided for @enterCode.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كود تفعيل'**
  String get enterCode;

  /// No description provided for @lockedTitle.
  ///
  /// In ar, this message translates to:
  /// **'هذا المستوى مقفل'**
  String get lockedTitle;

  /// No description provided for @lockedText.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من إدارة المعهد تفعيل {level} لك.'**
  String lockedText(String level);

  /// No description provided for @expiredTitle.
  ///
  /// In ar, this message translates to:
  /// **'انتهى تفعيل هذا المستوى'**
  String get expiredTitle;

  /// No description provided for @expiredText.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من الإدارة تجديد {level}. تقدّمك محفوظ.'**
  String expiredText(String level);

  /// No description provided for @renewOnWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'اطلب التجديد عبر واتساب'**
  String get renewOnWhatsapp;

  /// No description provided for @endsOn.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي تفعيل {level} في {date}.'**
  String endsOn(String level, String date);

  /// No description provided for @openUntil.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح حتى {date}'**
  String openUntil(String date);
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return L10nAr();
    case 'en':
      return L10nEn();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
