
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();

  bool _isLogin = true;
  bool _hidePassword = true;
  bool _isLoading = false;

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(email)) {
      return 'Enter a valid email';
    }

    return null;
  }

  // Login or signup function
  Future<void> submit() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLogin) {
        await _authService.login(email, password);
      } else {
        await _authService.signup(email, password);
      }

      // AuthGate will handle navigation.

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      showMessage(getErrorMessage(e.code));

    } catch (_) {
      if (mounted) {
        showMessage('Something went wrong. Try again.');
      }

    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Firebase error messages
  String getErrorMessage(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password';

      case 'email-already-in-use':
        return 'Account already exists';

      case 'weak-password':
        return 'Password is too weak';

      case 'invalid-email':
        return 'Invalid email address';

      case 'network-request-failed':
        return 'Check your internet connection';

      case 'too-many-requests':
        return 'Too many attempts. Try again later';

      default:
        return 'Authentication failed ($code)';
    }
  }

  // Forgot password
  Future<void> forgotPassword() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final error = validateEmail(email);

    if (error != null) {
      showMessage(error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(email);

      if (mounted) {
        showMessage(
          'If the account exists, a reset email will be sent.',
        );
      }

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      showMessage(
        e.code == 'user-not-found'
            ? 'If the account exists, a reset email will be sent.'
            : getErrorMessage(e.code),
      );

    } catch (_) {
      if (mounted) {
        showMessage('Something went wrong. Try again.');
      }

    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {

            final isDesktop = constraints.maxWidth >= 900;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),

                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100,
                  ),

                  child: isDesktop
                      ? Row(
                          children: [
                            Expanded(child: buildBranding()),
                            const SizedBox(width: 60),
                            Expanded(child: buildForm()),
                          ],
                        )
                      : Column(
                          children: [
                            buildLogo(90),
                            const SizedBox(height: 24),
                            buildForm(),
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

  // AI logo
  Widget buildLogo(double size) {
    return Container(
      width: size,
      height: size,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        gradient: const LinearGradient(
          colors: [
            AppColors.purple,
            AppColors.cyan,
          ],
        ),

        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.4),
            blurRadius: 45,
            spreadRadius: 5,
          ),
        ],
      ),

      child: Icon(
        Icons.memory_rounded,
        size: size * 0.5,
        color: Colors.white,
      ),
    ).animate().fadeIn(duration: 700.ms).scale();
  }

  // Desktop branding section
  Widget buildBranding() {
    return Column(
      children: [
        buildLogo(160),

        const SizedBox(height: 40),

        const Text(
          'LifeLens AI',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        const Text(
          'Your world, understood by AI.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.cyan,
            fontSize: 18,
          ),
        ),

        const SizedBox(height: 25),

        const Text(
          'Scan. Discover. Learn.\n'
          'Experience the power of intelligence.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 15,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  // Login and signup form
  Widget buildForm() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),

        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.3),
        ),
      ),

      child: Form(
        key: _formKey,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            Text(
              _isLogin ? 'Welcome Back' : 'Create Account',
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _isLogin
                  ? 'Sign in to continue exploring'
                  : 'Start your AI-powered journey',
              style: const TextStyle(color: AppColors.grey),
            ),

            const SizedBox(height: 30),

            // Email field
            TextFormField(
              controller: _emailController,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: inputDecoration(
                'Email address',
                Icons.email_outlined,
              ),
              validator: validateEmail,
            ),

            const SizedBox(height: 20),

            // Password field
            TextFormField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: _hidePassword,
              autocorrect: false,
              enableSuggestions: false,

              decoration: inputDecoration(
                'Password',
                Icons.lock_outline,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _hidePassword = !_hidePassword;
                    });
                  },
                ),
              ),

              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }

                if (!_isLogin && value.length < 6) {
                  return 'Minimum 6 characters required';
                }

                return null;
              },
            ),

            if (_isLogin)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : forgotPassword,
                  child: const Text('Forgot Password?'),
                ),
              ),

            const SizedBox(height: 20),

            // Main button
            SizedBox(
              height: 55,

              child: ElevatedButton(
                onPressed: _isLoading ? null : submit,

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                child: _isLoading
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isLogin ? 'Sign In' : 'Sign Up',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Switch between login and signup
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _isLogin
                      ? "Don't have an account?"
                      : 'Already have an account?',
                  style: const TextStyle(color: AppColors.grey),
                ),

                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _formKey.currentState?.reset();
                          _passwordController.clear();

                          setState(() {
                            _isLogin = !_isLogin;
                            _hidePassword = true;
                          });
                        },

                  child: Text(
                    _isLogin ? 'Sign Up' : 'Login',
                    style: const TextStyle(
                      color: AppColors.cyan,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  // Reusable input design
  InputDecoration inputDecoration(
    String label,
    IconData icon,
  ) {

    final colors = Theme.of(context).colorScheme;
    
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.cyan),
      filled: true,
      fillColor: colors.surface,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.purple,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.cyan,
          width: 1.5,
        ),
      ),
    );
  }
}
