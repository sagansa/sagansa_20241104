import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _passwordVisible = false;

  Future<void> _login() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      emailController.text.trim(),
      passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Navigation will be handled by AuthWrapper
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
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
                      ModernTextField(
                        key: const Key('email_field'),
                        controller: emailController,
                        labelText: 'Email',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enableSuggestions: false,
                        enabled: !authProvider.isLoading,
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
                      ),
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
                                  style: TextStyle(color: Colors.red.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
