import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/labeled_text_field.dart';

/// Email/password registration screen.
///
/// On success, AuthService.registerWithEmail already fires off a
/// verification email - main.dart's auth listener detects the new
/// signed-in (but unverified) user and routes to VerifyEmailScreen
/// automatically, so this screen just needs to handle the form submit.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .registerWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
      // Registration succeeded - AuthGate has already swapped its body to
      // VerifyEmailScreen underneath us (authStateProvider fired the
      // moment Firebase signed the new user in). But THIS screen is still
      // on top of the navigation stack on top of it, so pop it now to
      // reveal what AuthGate is already showing.
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Start your progressive overload journey',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                LabeledTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'you@example.com',
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  hintText: 'At least 6 characters',
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  hintText: 'Re-enter your password',
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: _isLoading ? 'Creating account...' : 'Register',
                  onPressed: _isLoading ? null : _register,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
