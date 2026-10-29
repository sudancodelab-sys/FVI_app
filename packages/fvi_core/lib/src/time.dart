/// Khartoum time (UTC+2, no daylight saving since 2017). The admin app can
/// override it from its settings.
const defaultInstituteUtcOffset = Duration(hours: 2);

DateTime wholeSecondsUtc(DateTime time) =>
    fromEpochSeconds(toEpochSeconds(time));

int toEpochSeconds(DateTime time) =>
    time.toUtc().millisecondsSinceEpoch ~/ 1000;

DateTime fromEpochSeconds(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

/// The last second of [date]'s calendar day in the institute's time zone, as
/// UTC. "Valid until 3 November" means through the end of 3 November there.
DateTime endOfInstituteDay(
  DateTime date, {
  Duration utcOffset = defaultInstituteUtcOffset,
}) => DateTime.utc(
  date.year,
  date.month,
  date.day,
  23,
  59,
  59,
).subtract(utcOffset);

/// The calendar date in the institute's time zone at [instant].
DateTime instituteDate(
  DateTime instant, {
  Duration utcOffset = defaultInstituteUtcOffset,
}) {
  final local = instant.toUtc().add(utcOffset);
  return DateTime.utc(local.year, local.month, local.day);
}
