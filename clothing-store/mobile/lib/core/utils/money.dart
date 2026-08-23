import 'package:intl/intl.dart';

/// Algerian French locale — standard for DA amounts in Algeria.
const String kAlgerianLocale = 'fr_DZ';

NumberFormat get _daNumberFormat => NumberFormat('#,##0', kAlgerianLocale);

/// Formats whole DA amounts, e.g. `2500` → `2 500 DA` (fr_DZ grouping).
String formatDAAmount(int amount) {
  if (amount < 0) {
    return '-${formatDAAmount(-amount)}';
  }
  return '${_daNumberFormat.format(amount)} DA';
}

/// Compact label for charts/cards, e.g. `2500` → `2,5K DA`.
String formatDASimple(int amount) {
  if (amount < 0) {
    return '-${formatDASimple(-amount)}';
  }
  if (amount >= 1000000) {
    final m = amount / 1000000;
    return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M DA';
  }
  if (amount >= 1000) {
    final k = amount / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K DA';
  }
  return formatDAAmount(amount);
}
