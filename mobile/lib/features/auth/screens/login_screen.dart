import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // Unfocus text fields
      _emailFocusNode.unfocus();
      _passwordFocusNode.unfocus();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authProvider.errorMessage ?? 'Login failed',
                    style: PremiumAppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: PremiumAppTheme.emergency,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumAppTheme.background,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // App Logo/Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: PremiumAppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: PremiumAppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      'Welcome Back',
                      style: PremiumAppTheme.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      style: PremiumAppTheme.bodyLarge.copyWith(
                        color: PremiumAppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!_isValidEmail(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Forgot Password (optional)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Forgot password feature coming soon',
                                style: PremiumAppTheme.bodyMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: PremiumAppTheme.labelMedium.copyWith(
                            color: PremiumAppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Login Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumAppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Sign In',
                                style: PremiumAppTheme.labelLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: PremiumAppTheme.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: PremiumAppTheme.bodySmall.copyWith(
                              color: PremiumAppTheme.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: PremiumAppTheme.border)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: PremiumAppTheme.bodyMedium.copyWith(
                            color: PremiumAppTheme.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.register);
                          },
                          child: Text(
                            'Sign Up',
                            style: PremiumAppTheme.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: PremiumAppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

