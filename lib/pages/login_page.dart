import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_version_text.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_text_field.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    
    if (savedEmail != null) {
      setState(() {
        emailController.text = savedEmail;
      });
    }
    if (savedPassword != null) {
      setState(() {
        passwordController.text = savedPassword;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true;
    });

    try {
      final success = await context.read<AuthProvider>().login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (success) {
        debugPrint('Login berhasil, navigating to HomePage...');

        // Simpan email dan password agar tidak perlu mengetik ulang
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', emailController.text.trim());
        await prefs.setString('saved_password', passwordController.text);

        // Determine admin role from stored user data
        bool initialIsAdmin = false;
        final userString = prefs.getString('user');
        if (userString != null) {
          final userData = json.decode(userString);
          final roles = List<String>.from(userData['roles'] ?? []);
          initialIsAdmin = roles.contains('admin') ||
              roles.contains('super_admin') ||
              roles.contains('supervisor');
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(initialIsAdmin: initialIsAdmin),
          ),
        );
      } else {
        final errorMsg = context.read<AuthProvider>().errorMessage;
        _showErrorDialog(errorMsg.isNotEmpty ? errorMsg : 'Login gagal');
      }
    } catch (e) {
      debugPrint('Error in _login: $e');
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Terjadi kesalahan saat login');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                  child: Padding(
                    padding: AppSpacing.paddingMD,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppSpacing.gapVerticalLG,
                            SvgPicture.asset(
                              'assets/images/logo.svg',
                              height: 160,
                              width: 160,
                            ),
                            AppSpacing.gapVerticalLG,
                            Text(
                              'Login',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            AppSpacing.gapVerticalLG,
                            AutofillGroup(
                              child: Column(
                                children: [
                                  ModernTextField(
                                    key: const ValueKey('email_field'),
                                    controller: emailController,
                                    labelText: 'Email',
                                    prefixIcon: Icons.email,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                  ),
                                  AppSpacing.gapVerticalMD,
                                  ModernTextField(
                                    key: const ValueKey('password_field'),
                                    controller: passwordController,
                                    labelText: 'Password',
                                    prefixIcon: Icons.lock,
                                    obscureText: !_passwordVisible,
                                    autofillHints: const [AutofillHints.password],
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _passwordVisible = !_passwordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  debugPrint('Forgot password clicked');
                                },
                                child: Text(
                                  'Lupa Password?',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapVerticalMD,
                        ModernButton(
                          text: 'Login',
                          onPressed: _login,
                          isLoading: isLoading,
                        ),
                        AppSpacing.gapVerticalMD,
                        const AppVersionText(),
                      ],
                    ),
                  ),
              ),
            );
          },
        ),
      ),
    );
  }
}
