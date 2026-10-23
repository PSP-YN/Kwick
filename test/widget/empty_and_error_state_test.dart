import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexhelp/shared/widgets/empty_state_view.dart';
import 'package:nexhelp/shared/widgets/error_state_view.dart';

void main() {
  group('EmptyStateView & ErrorStateView Widget Tests', () {
    testWidgets('EmptyStateView renders title, message and action button', (
      tester,
    ) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.inbox_outlined,
              title: 'No Active Orders',
              message:
                  'You have not booked any plumbing or electrical services yet.',
              actionLabel: 'Book Service',
              onAction: () {
                actionTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No Active Orders'), findsOneWidget);
      expect(
        find.text(
          'You have not booked any plumbing or electrical services yet.',
        ),
        findsOneWidget,
      );
      expect(find.text('Book Service'), findsOneWidget);

      await tester.tap(find.text('Book Service'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });

    testWidgets('ErrorStateView renders message and handles retry callback', (
      tester,
    ) async {
      bool retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateView(
              message: 'Could not connect to Supabase backend service.',
              onRetry: () {
                retryTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(
        find.text('Could not connect to Supabase backend service.'),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(retryTriggered, isTrue);
    });
  });
}
