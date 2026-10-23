import 'package:intl/intl.dart';

/// Utilities for converting integer minor paise to formatted INR strings
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrWholeFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Converts paise (integer) to formatted INR string, e.g. 25000 paise -> "₹250.00"
  static String formatPaise(int? paise, {bool includeDecimals = true}) {
    if (paise == null) return 'Price on assessment';
    final rupees = paise / 100.0;
    if (includeDecimals) {
      return _inrFormat.format(rupees);
    } else {
      return _inrWholeFormat.format(rupees);
    }
  }

  /// Converts a rupee float/double string input from user to paise (int)
  static int rupeesToPaise(double rupees) {
    return (rupees * 100).round();
  }
}
