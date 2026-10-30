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

  @override
  String get welcomeName => 'Future Vision Institute';

  @override
  String get welcomeNameSub => 'for Computer and Languages';

  @override
  String get welcomeTagline => 'Study and review app';

  @override
  String get chooseLanguage => 'Choose the app\'s language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageEnglishSub => 'Left-to-right interface';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageArabicSub => 'الواجهة من اليمين إلى اليسار';

  @override
  String get continueButton => 'Continue';

  @override
  String versionN(String v) {
    return 'Version $v';
  }

  @override
  String get requestTitle => 'Request activation';

  @override
  String get requestIntro =>
      'Enter your details. Your request goes to the institute on WhatsApp, and they send you an activation code.';

  @override
  String get fullName => 'Full name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get yourLevel => 'The level you study';

  @override
  String levelOption(String course, String level) {
    return '$course · $level';
  }

  @override
  String get deviceCodeLabel => 'Your device code';

  @override
  String get deviceCodeNote =>
      'The code is sent with your request and ties the activation to this phone only.';

  @override
  String get requestOnWhatsapp => 'Request activation on WhatsApp';

  @override
  String get haveCode => 'I already have an activation code';

  @override
  String get nameNeeded => 'Write your full name.';

  @override
  String get phoneNeeded => 'Write your phone number.';

  @override
  String get levelNeeded => 'Choose your level.';

  @override
  String get messageHeading => 'FVI app activation request';

  @override
  String messageName(String v) {
    return 'Name: $v';
  }

  @override
  String messagePhone(String v) {
    return 'Phone: $v';
  }

  @override
  String messageLevel(String v) {
    return 'Level: $v';
  }

  @override
  String messageDevice(String v) {
    return 'Device code: $v';
  }

  @override
  String get whatsappFailed =>
      'WhatsApp did not open. Is it installed on this phone?';

  @override
  String get activateTitle => 'Activate the app';

  @override
  String get waitingTitle => 'Waiting for the activation code';

  @override
  String get waitingText =>
      'When the institute replies on WhatsApp, copy their message and come back to the app: it finds the code by itself.';

  @override
  String get stepDetails => 'Enter your details';

  @override
  String get stepSent => 'Send the request on WhatsApp';

  @override
  String get stepCode => 'Receive the activation code';

  @override
  String get orEnterCode => 'or enter the code yourself';

  @override
  String get pasteHere => 'Paste the activation code here';

  @override
  String get paste => 'Paste';

  @override
  String get activate => 'Activate';

  @override
  String get sendAgain => 'Send the request again';

  @override
  String get codeFound => 'An activation code was found in what you copied.';

  @override
  String get problemNoCode =>
      'There is no activation code in this text. Copy the institute\'s whole message and try again.';

  @override
  String get problemOtherInstitute =>
      'This code is not from Future Vision Institute.';

  @override
  String get problemAltered =>
      'This code was changed after it was sent. Copy it again from the message.';

  @override
  String get problemOtherPhone =>
      'This code is for another phone, or for this phone before the app was installed again. Send a new request.';

  @override
  String get problemClock =>
      'Your phone\'s date is wrong. Correct it in the phone\'s settings, then try again.';

  @override
  String get activated => 'The app is activated.';

  @override
  String get clockTitle => 'Correct your phone\'s date';

  @override
  String get clockText =>
      'Your phone\'s date is earlier than a date the app has already seen, so the levels are closed. Correct the date in the phone\'s settings, or ask the institute for a new code.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get enterCode => 'Enter an activation code';

  @override
  String get lockedTitle => 'This level is locked';

  @override
  String lockedText(String level) {
    return 'Ask the institute to activate $level for you.';
  }

  @override
  String get expiredTitle => 'Your access to this level has ended';

  @override
  String expiredText(String level) {
    return 'Ask the institute to renew $level. Your progress is kept.';
  }

  @override
  String get renewOnWhatsapp => 'Renew on WhatsApp';

  @override
  String endsOn(String level, String date) {
    return 'Your access to $level ends on $date.';
  }

  @override
  String openUntil(String date) {
    return 'Open until $date';
  }
}
