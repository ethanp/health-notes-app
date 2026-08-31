import 'package:intl/intl.dart';

extension HealthDateFormat on DateTime {
  String get monthDayYear => DateFormat('MMM dd, yyyy').format(this);

  String get weekdayMonthDayYear =>
      DateFormat('EEEE, MMMM dd, yyyy').format(this);

  String get hourMinuteAmPm => DateFormat('h:mm a').format(this);

  String get monthYear => DateFormat('MMM yyyy').format(this);

  String get weekdayMonthDayYearAtTime =>
      '$weekdayMonthDayYear at $hourMinuteAmPm';
}
