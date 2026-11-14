import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kwick/shared/widgets/confirmation_dialog.dart';
import 'package:kwick/shared/widgets/primary_button.dart';

void main() {
  group('PrimaryButton Widget Tests', () {
    testWidgets('renders button label and handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Book Service',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Book Service'), findsOneWidget);
      await tester.tap(find.text('Book Service'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows loading spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Submitting',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ConfirmationDialog Widget Tests', () {
    testWidgets('renders dialog and responds to cancel and confirm', (
      tester,
    ) async {
      bool? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  confirmed = await ConfirmationDialog.show(
                    context,
                    title: 'Cancel Request',
                    message: 'Are you sure?',
                    confirmLabel: 'Yes, Cancel',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Request'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);

      await tester.tap(find.text('Yes, Cancel'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });
  });
}
