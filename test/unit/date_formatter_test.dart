import 'package:flutter_test/flutter_test.dart';
import 'package:kwick/core/utilities/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    test('formatDateTime formats known date correctly', () {
      final date = DateTime(2026, 10, 23, 14, 30);
      final formatted = DateFormatter.formatDateTime(date);
      expect(formatted, contains('23 Oct 2026'));
      expect(formatted, contains('02:30 PM'));
    });

    test('formatDate returns expected day and month', () {
      final date = DateTime(2026, 1, 15);
      final formatted = DateFormatter.formatDate(date);
      expect(formatted, equals('15 Jan 2026'));
    });

    test('formatTimeOfDay formats AM/PM correctly', () {
      final morning = DateTime(2026, 5, 10, 9, 5);
      expect(DateFormatter.formatTime(morning), equals('09:05 AM'));

      final noon = DateTime(2026, 5, 10, 12, 0);
      expect(DateFormatter.formatTime(noon), equals('12:00 PM'));

      final midnight = DateTime(2026, 5, 10, 0, 15);
      expect(DateFormatter.formatTime(midnight), equals('12:15 AM'));
    });

    test('formatRelative provides readable relative time strings', () {
      final justNow = DateTime.now().subtract(const Duration(seconds: 15));
      expect(DateFormatter.formatRelative(justNow), equals('Just now'));

      final twentyMinsAgo = DateTime.now().subtract(
        const Duration(minutes: 20),
      );
      expect(DateFormatter.formatRelative(twentyMinsAgo), equals('20m ago'));

      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      expect(DateFormatter.formatRelative(twoHoursAgo), equals('2h ago'));
    });
  });
}
