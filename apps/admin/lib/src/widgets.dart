import 'package:flutter/material.dart';
import 'package:fvi_core/fvi_core.dart' show instituteDate;
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import 'data/records.dart';
import 'theme.dart';

/// "29 ديسمبر 2026": Arabic months with the digits of the designs. [utc] is
/// an end of access or an issue time; the day is the institute's.
String day(DateTime utc) => _latin(DateFormat.yMMMMd('ar').format(instituteDate(utc)));

/// "الخميس، 29 أكتوبر 2026".
String longDay(DateTime utc) => _latin(DateFormat.yMMMMEEEEd('ar').format(instituteDate(utc)));

String _latin(String s) => s.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');

/// Whole days from [now] to [until], counted on the institute's calendar.
int daysLeft(DateTime now, DateTime until) => instituteDate(until).difference(instituteDate(now)).inDays;

/// A white card with the designs' border and corners.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Fvi.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Fvi.line),
        ),
        child: child,
      );
}

/// A small rounded label: "5 أيام", "فعّال", "منتهٍ".
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, required this.color, required this.background});

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13.5)),
      );
}

/// A student's state as a badge: days left when it ends soon.
Widget statusBadge(L10n t, StudentRecord s, DateTime now) => switch (s.status(now)) {
      StudentStatus.endingSoon =>
        Pill(t.daysLeft(daysLeft(now, s.soonestEnd(now)!)), color: Fvi.amber, background: Fvi.amberSoft),
      StudentStatus.active => now.difference(s.firstSeen).inDays < 7
          ? Pill(t.statusNew, color: Fvi.green, background: Fvi.greenSoft)
          : Pill(t.statusActive, color: Fvi.green, background: Fvi.greenSoft),
      StudentStatus.expired => Pill(t.statusExpired, color: Fvi.red, background: Fvi.redSoft),
      StudentStatus.none => Pill(t.statusNew, color: Fvi.green, background: Fvi.greenSoft),
    };

/// The round initial of a student, in one of the designs' tints.
class Initial extends StatelessWidget {
  const Initial(this.name, {super.key, this.size = 46});

  final String name;
  final double size;

  static const _tints = [
    (Fvi.navy, Fvi.navySoft),
    (Fvi.green, Fvi.greenSoft),
    (Fvi.orange, Fvi.orangeSoft),
    (Fvi.red, Fvi.redSoft),
  ];

  @override
  Widget build(BuildContext context) {
    final (color, background) = _tints[name.runes.fold(0, (a, b) => a + b) % _tints.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      child: Text(name.trim().isEmpty ? '?' : String.fromCharCode(name.trim().runes.first),
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: size * .42)),
    );
  }
}

/// A choice as in the designs: navy with white text when chosen.
Widget choice(String label, {required bool selected, required VoidCallback onSelected, IconData? icon}) => ChoiceChip(
      avatar: icon == null ? null : Icon(icon, size: 18),
      iconTheme: IconThemeData(color: selected ? Colors.white : Fvi.navy),
      label: Text(label),
      labelStyle: TextStyle(color: selected ? Colors.white : Fvi.text, fontWeight: FontWeight.w700),
      selected: selected,
      showCheckmark: false,
      selectedColor: Fvi.navy,
      backgroundColor: Fvi.surface,
      side: BorderSide(color: selected ? Fvi.navy : Fvi.line),
      shape: const StadiumBorder(),
      onSelected: (_) => onSelected(),
    );

/// A WhatsApp number as people write it, left to right: 249904011473 is +249 90 401 1473.
String phoneNumber(String digits) {
  final grouped = digits.length == 12 && digits.startsWith('249')
      ? '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 8)} ${digits.substring(8)}'
      : digits;
  return '\u200E+$grouped';
}

/// Opens WhatsApp; tells the admin when it did not open.
Future<void> openWhatsapp(BuildContext context, Uri uri) async {
  final t = L10n.of(context);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.whatsappFailed)));
  }
}

ButtonStyle bigButton(Color color) => FilledButton.styleFrom(
      backgroundColor: color,
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontFamily: Fvi.arabic, fontSize: 17, fontWeight: FontWeight.w800),
    );
