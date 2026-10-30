import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fvi_student/l10n/app_localizations.dart';
import 'package:fvi_student/src/content/model.dart';
import 'package:fvi_student/src/screens/exercise_screen.dart';

final lesson = Lesson({
  'lesson': 1,
  'kind': 'story',
  'title': 'The New Student',
  'exercises': [
    {'type': 'choice', 'kind': 'question', 'prompt': 'Who is the new student?',
     'choices': ['Mr. Ali.', 'Omar.', "He's nineteen."], 'answer': 1},
    {'type': 'order', 'kind': 'order', 'prompt': 'Ask where', 'words': ['are', 'Where', 'you?'],
     'answer': 'Where are you?'},
  ],
}, position: 1, count: 12);

Widget app(Locale locale) => MaterialApp(
      locale: locale,
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ExerciseScreen(lesson: lesson),
    );

void main() {
  testWidgets('a wrong choice shows the right answer; words put in order are right', (tester) async {
    await tester.pumpWidget(app(const Locale('en')));
    expect(find.text('Choose the right answer.'), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);

    await tester.tap(find.text('Mr. Ali.'));
    await tester.pump();
    expect(find.text('The right answer:'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Put the words in order.'), findsOneWidget);
    final check = find.widgetWithText(FilledButton, 'Check');
    expect(tester.widget<FilledButton>(check).onPressed, isNull); // not until every word is in
    for (final w in ['Where', 'are', 'you?']) {
      await tester.tap(find.text(w));
      await tester.pump();
    }
    await tester.tap(check);
    await tester.pump();
    expect(find.text('Right!'), findsOneWidget);

    await tester.tap(find.text('See your score'));
    await tester.pump();
    expect(find.text('1 of 2'), findsOneWidget);
    await tester.tap(find.text('Do them again'));
    await tester.pump();
    expect(find.text('Who is the new student?'), findsOneWidget);
  });

  testWidgets('in the Arabic app the instructions are Arabic and the exercise stays English', (tester) async {
    await tester.pumpWidget(app(const Locale('ar')));
    expect(find.text('اختر الجواب الصحيح حسب الدرس'), findsOneWidget);
    expect(find.text('Who is the new student?'), findsOneWidget);
    await tester.tap(find.text('Omar.'));
    await tester.pump();
    expect(find.text('صحيح'), findsOneWidget);
  });
}
