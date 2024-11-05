import 'package:flutter/material.dart';
import 'home_page.dart';
import '../services/auth_service.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _passwordVisible = false;
  final _authService = AuthService();

  Future<void> _login() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await _authService.login(
        emailController.text,
        passwordController.text,
      );

      print('Login response: $result');

      setState(() {
        isLoading = false;
      });

      if (result['message'] == 'Login successful') {
        print('Login berhasil, navigating to HomePage...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        _showErrorDialog(result['message']);
      }
    } catch (e) {
      print('Error in _login: $e');
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
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  AppBar().preferredSize.height,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Logo dan form fields
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 120,
                            width: 120,
                          ),
                          SizedBox(height: 32),
                          Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          ModernTextField(
                            controller: emailController,
                            labelText: 'Email',
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          SizedBox(height: 16),
                          ModernTextField(
                            controller: passwordController,
                            labelText: 'Password',
                            prefixIcon: Icons.lock,
                            obscureText: !_passwordVisible,
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
                              onPressed: () {
                                print('Forgot password clicked');
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
                    ),
                    // Bottom section dengan login button dan register text
                    Column(
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
                              onTap: () {
                                print('Register clicked');
                              },
                              child: Text(
                                'Daftar Sekarang',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        ModernButton(
                          text: 'Login',
                          onPressed: _login,
                          isLoading: isLoading,
                        ),
                        SizedBox(height: 16), // Tambahan padding di bawah
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
