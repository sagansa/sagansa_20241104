import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/services/google_autofill_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Autofill Service Tests', () {
    test('should provide correct autofill hints for email', () {
      final emailHints = GoogleAutofillService.emailAutofillHints;

      expect(emailHints, isNotEmpty);
      expect(emailHints, contains('email'));
      expect(emailHints, contains(AutofillHints.email));
      expect(emailHints, contains(AutofillHints.username));
    });

    test('should provide correct autofill hints for password', () {
      final passwordHints = GoogleAutofillService.passwordAutofillHints;

      expect(passwordHints, isNotEmpty);
      expect(passwordHints, contains('password'));
      expect(passwordHints, contains(AutofillHints.password));
    });

    test('should report autofill as supported', () {
      final isSupported = GoogleAutofillService.isAutofillSupported;
      expect(isSupported, isTrue);
    });

    test('should handle text controller prefilling gracefully', () async {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();

      // This should not throw an error even if no credentials are available
      await GoogleAutofillService.prefillCredentials(
        emailController: emailController,
        passwordController: passwordController,
      );

      // Controllers should remain empty if no credentials are available
      expect(emailController.text, isEmpty);
      expect(passwordController.text, isEmpty);

      emailController.dispose();
      passwordController.dispose();
    });

    testWidgets('should show save credentials dialog',
        (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result =
                        await GoogleAutofillService.showSaveCredentialsDialog(
                      context: context,
                      email: 'test@example.com',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Simpan Kredensial'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);

      // Tap "Simpan" button
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isTrue);
    });

    testWidgets('should handle dialog cancellation',
        (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result =
                        await GoogleAutofillService.showSaveCredentialsDialog(
                      context: context,
                      email: 'test@example.com',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap "Tidak" button
      await tester.tap(find.text('Tidak'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isFalse);
    });
  });
}
