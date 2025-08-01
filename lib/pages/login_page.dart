import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';
import '../services/google_autofill_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoadingCredentials = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      await GoogleAutofillService.prefillCredentials(
        emailController: emailController,
        passwordController: passwordController,
      );
    } catch (e) {
      // Ignore errors when loading credentials
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCredentials = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = emailController.text.trim();
    final password = passwordController.text;

    final success = await authProvider.login(email, password);

    if (!mounted) return;

    if (success) {
      // Handle credential saving after successful login
      await GoogleAutofillService.handleSuccessfulLogin(
        context: context,
        email: email,
        password: password,
      );

      // Navigation will be handled by AuthWrapper
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Cancel autofill context on failed login
      await GoogleAutofillService.cancelAutofillContext();
      _showErrorDialog(authProvider.errorMessage);
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        try {
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
            ),
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AutofillGroup(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 120,
                          width: 120,
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_isLoadingCredentials)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else ...[
                          ModernTextField(
                            key: const Key('email_field'),
                            controller: emailController,
                            labelText: 'Email',
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            enableSuggestions: false,
                            enabled: !authProvider.isLoading,
                            autofillHints:
                                GoogleAutofillService.emailAutofillHints,
                          ),
                          const SizedBox(height: 16),
                          ModernTextField(
                            key: const Key('password_field'),
                            controller: passwordController,
                            labelText: 'Password',
                            prefixIcon: Icons.lock,
                            obscureText: !_passwordVisible,
                            enabled: !authProvider.isLoading,
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
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints:
                                GoogleAutofillService.passwordAutofillHints,
                          ),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () {
                                    // TODO: Implement forgot password
                                  },
                            child: Text(
                              'Lupa Password?',
                              style: TextStyle(
                                color: authProvider.isLoading
                                    ? Colors.grey
                                    : Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                        // Show error message if any
                        if (authProvider.authState == AuthState.error)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authProvider.errorMessage,
                                    style:
                                        TextStyle(color: Colors.red.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Tombol login dan teks register di bottom
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 32,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: authProvider.isLoading
                                ? null
                                : () {
                                    // TODO: Implement registration
                                  },
                            child: Text(
                              'Daftar Sekarang',
                              style: TextStyle(
                                color: authProvider.isLoading
                                    ? Colors.grey
                                    : Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ModernButton(
                        text: 'Login',
                        onPressed: authProvider.isLoading ? null : _login,
                        isLoading: authProvider.isLoading,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } catch (e) {
          print('Error in LoginPage build: $e');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading login page'),
                  Text('$e'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Force rebuild
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
