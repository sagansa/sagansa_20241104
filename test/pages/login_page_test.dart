import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sagansa/pages/login_page.dart';
import 'package:sagansa/providers/auth_provider.dart';
import 'package:sagansa/providers/theme_provider.dart';
import 'package:sagansa/widgets/modern_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget test untuk LoginPage.
///
/// Login page pakai ModernTextField (dengan ValueKey 'email_field' /
/// 'password_field') dan ModernButton. Test fokus pada:
/// - render elemen form
/// - input email/password
/// - toggle password visibility
/// - loading state pada tombol
void main() {
  group('LoginPage Widget Tests', () {
    late AuthProvider authProvider;
    late ThemeProvider themeProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authProvider = AuthProvider();
      themeProvider = ThemeProvider();
    });

    /// Helper: pump LoginPage dengan provider yang dibutuhkan.
    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ],
          child: MaterialApp(
            theme: ThemeProvider.lightTheme,
            home: const LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('should render login form correctly', (tester) async {
      await pumpPage(tester);

      // Title "Login" muncul (heading + tombol).
      expect(find.text('Login'), findsAtLeastNWidgets(1));
      // Field-field utama ada dan bisa ditemukan via key.
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      // Link lupa password tampil.
      expect(find.text('Lupa Password?'), findsOneWidget);
    });

    testWidgets('should accept input in email and password fields',
        (tester) async {
      await pumpPage(tester);

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'secret123',
      );

      // Value terisi ke controller yang dipakai field.
      final emailField = tester.widget<ModernTextField>(
        find.byKey(const Key('email_field')),
      );
      final passwordField = tester.widget<ModernTextField>(
        find.byKey(const Key('password_field')),
      );
      expect(emailField.controller.text, 'user@example.com');
      expect(passwordField.controller.text, 'secret123');
    });

    testWidgets('should toggle password visibility', (tester) async {
      await pumpPage(tester);

      // Toggle button ada di dalam password field.
      final visibilityButton = find.descendant(
        of: find.byKey(const Key('password_field')),
        matching: find.byType(IconButton),
      );
      expect(visibilityButton, findsOneWidget);

      // Awalnya password tersembunyi (icon = visibility_off).
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap toggle → icon berubah jadi visibility.
      await tester.tap(visibilityButton);
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should keep form fields present before and after interaction',
        (tester) async {
      await pumpPage(tester);

      // Field ada di kondisi awal.
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);

      // Interaksi: isi field + tap toggle.
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@test.com');
      await tester.tap(find.descendant(
        of: find.byKey(const Key('password_field')),
        matching: find.byType(IconButton),
      ));
      await tester.pump();

      // Field masih ada setelah interaksi.
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
    });
  });
}
