import 'package:intl/intl.dart';

class AppCurrency {
  AppCurrency._();

  static final _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _formatterWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(num amount) => _formatter.format(amount);

  static String formatDecimal(num amount) =>
      _formatterWithDecimals.format(amount);
}
