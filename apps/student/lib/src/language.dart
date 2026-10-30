import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's language: English, unless the student picks Arabic; then the
/// interface, the exercise instructions and the Arabic grammar notes are in
/// Arabic (decision #45). The choice is kept on the phone.
class AppLanguage extends ChangeNotifier {
  static const english = Locale('en');
  static const arabic = Locale('ar');
  static const _key = 'language';

  Locale _locale = english;

  Locale get locale => _locale;
  bool get isArabic => _locale == arabic;

  /// Reads the choice kept on the phone, if there is one.
  Future<void> load() async {
    final saved = (await SharedPreferences.getInstance()).getString(_key);
    if (saved == arabic.languageCode && !isArabic) {
      _locale = arabic;
      notifyListeners();
    }
  }

  Future<void> choose(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(_key, locale.languageCode);
  }

  static AppLanguage of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()!.notifier!;
}

/// Gives the screens the [AppLanguage], to show and change it.
class LanguageScope extends InheritedNotifier<AppLanguage> {
  const LanguageScope({super.key, required AppLanguage language, required super.child})
      : super(notifier: language);
}
