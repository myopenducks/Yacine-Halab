import 'package:intl/intl.dart';

import 'money.dart';

final DateFormat appDateFormat = DateFormat('dd MMM yyyy', kAlgerianLocale);

final DateFormat appDateTimeFormat =
    DateFormat('dd MMM yyyy · HH:mm', kAlgerianLocale);

final DateFormat appTimeFormat = DateFormat('HH:mm', kAlgerianLocale);

String formatAppDate(DateTime date) => appDateFormat.format(date.toLocal());

String formatAppDateTime(DateTime date) =>
    appDateTimeFormat.format(date.toLocal());

String formatAppTime(DateTime date) => appTimeFormat.format(date.toLocal());
