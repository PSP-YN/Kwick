import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kwick/shared/models/provider_profile.dart';
import 'package:kwick/shared/models/service_request.dart';
import 'package:kwick/shared/widgets/status_badge.dart';

void main() {
  group('StatusBadge Widget Tests', () {
    testWidgets('renders OrderStatus.completed badge correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.fromOrderStatus(OrderStatus.completed),
          ),
        ),
      );

      expect(find.text('Completed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders VerificationStatus.approved badge correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.fromVerificationStatus(
              VerificationStatus.approved,
            ),
          ),
        ),
      );

      expect(find.text('Verified Professional'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('renders AvailabilityStatus.available badge correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.fromAvailabilityStatus(
              AvailabilityStatus.available,
            ),
          ),
        ),
      );

      expect(find.text('Online & Available'), findsOneWidget);
    });
  });
}
