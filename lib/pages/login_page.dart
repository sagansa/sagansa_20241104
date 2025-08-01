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

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Email dan password tidak boleh kosong');
      return;
    }

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

      // Show simple error dialog
      _showErrorDialog(authProvider.errorMessage);
    }
  }

  void _showErrorDialogWithTroubleshooting(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Login Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.isNotEmpty ? message : 'Terjadi kesalahan saat login.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (message.contains('terhubung') || message.contains('server'))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solusi yang bisa dicoba:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('• Periksa koneksi internet Anda'),
                  const Text('• Coba gunakan WiFi atau data seluler'),
                  const Text('• Restart aplikasi'),
                  const Text('• Coba lagi dalam beberapa saat'),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('OK'),
          ),
          if (message.contains('terhubung') || message.contains('server'))
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _retryLogin();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Coba Lagi'),
            ),
        ],
      ),
    );
  }

  void _retryLogin() {
    // Clear any existing errors
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.clearError();

    // Retry login
    _login();
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Login Error'),
          ],
        ),
        content: Text(
          message.isNotEmpty
              ? message
              : 'Terjadi kesalahan saat login. Silakan coba lagi.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
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
                            hintText: 'Masukkan email Anda',
                            prefixIcon: Icons.email_outlined,
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
                            hintText: 'Masukkan password Anda',
                            prefixIcon: Icons.lock_outlined,
                            obscureText: !_passwordVisible,
                            enabled: !authProvider.isLoading,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () {
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () {
                                    // TODO: Implement forgot password
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Fitur lupa password akan segera tersedia'),
                                      ),
                                    );
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                            child: const Text(
                              'Lupa Password?',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Show error message if any
                        if (authProvider.authState == AuthState.error)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    authProvider.errorMessage.isNotEmpty
                                        ? authProvider.errorMessage
                                        : 'Terjadi kesalahan saat login',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onErrorContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          TextButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () {
                                    // TODO: Implement registration
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Fitur registrasi akan segera tersedia'),
                                      ),
                                    );
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text(
                              'Daftar Sekarang',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
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
