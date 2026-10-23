import 'package:flutter_test/flutter_test.dart';
import 'package:nexhelp/core/utilities/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats null paise as assessment placeholder', () {
      expect(CurrencyFormatter.formatPaise(null), 'Price on assessment');
    });

    test('formats zero paise correctly', () {
      expect(CurrencyFormatter.formatPaise(0), '₹0.00');
    });

    test('formats integer paise to INR decimal string', () {
      expect(CurrencyFormatter.formatPaise(25000), '₹250.00');
      expect(CurrencyFormatter.formatPaise(35050), '₹350.50');
      expect(CurrencyFormatter.formatPaise(100000), '₹1,000.00');
    });

    test('formats integer paise without decimals when requested', () {
      expect(
        CurrencyFormatter.formatPaise(25000, includeDecimals: false),
        '₹250',
      );
      expect(
        CurrencyFormatter.formatPaise(500000, includeDecimals: false),
        '₹5,000',
      );
    });

    test('converts rupee float input to integer paise', () {
      expect(CurrencyFormatter.rupeesToPaise(250.0), 25000);
      expect(CurrencyFormatter.rupeesToPaise(350.50), 35050);
      expect(CurrencyFormatter.rupeesToPaise(0.0), 0);
    });
  });
}
