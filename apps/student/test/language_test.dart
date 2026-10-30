import 'package:flutter_test/flutter_test.dart';
import 'package:fvi_student/src/language.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('English until the student picks Arabic, and the choice is kept', () async {
    SharedPreferences.setMockInitialValues({});
    final first = AppLanguage();
    await first.load();
    expect(first.locale, AppLanguage.english);

    await first.choose(AppLanguage.arabic);
    expect(first.isArabic, isTrue);

    final again = AppLanguage();
    await again.load();
    expect(again.isArabic, isTrue);
  });
}
