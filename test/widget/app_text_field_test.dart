import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexhelp/shared/widgets/app_text_field.dart';

void main() {
  group('AppTextField Widget Tests', () {
    testWidgets('renders label and hint and receives text input', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AppTextField(
                label: 'Service Address',
                hint: 'e.g. 14th Main, HSR Layout Sector 1',
                controller: controller,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Service Address'), findsOneWidget);
      expect(find.text('e.g. 14th Main, HSR Layout Sector 1'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField),
        'Flat 204, Green Glen, HSR',
      );
      await tester.pump();

      expect(controller.text, equals('Flat 204, Green Glen, HSR'));
    });

    testWidgets(
      'triggers validator and renders error message on form validation',
      (tester) async {
        final formKey = GlobalKey<FormState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Phone Number',
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        formKey.currentState?.validate();
                      },
                      child: const Text('Validate'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Validate'));
        await tester.pumpAndSettle();

        expect(find.text('Phone number is required'), findsOneWidget);
      },
    );
  });
}
