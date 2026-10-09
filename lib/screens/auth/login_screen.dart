import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/labeled_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Email/password login screen, plus "Sign in with Google" and "Sign in
/// with GitHub" alternative methods, and links to Register / Forgot
/// Password.
///
/// On success, this screen does NOT navigate anywhere itself - it just
/// pops/relies on main.dart's authStateProvider listener to swap the
/// whole app over to RootScreen once FirebaseAuth reports a signed-in
/// user.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .signInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
      ref.read(bottomNavIndexProvider.notifier).setIndex(0);
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (user != null) {
        ref.read(bottomNavIndexProvider.notifier).setIndex(0);
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      // The google_sign_in plugin can throw (instead of resolving to
      // null) when the account picker is dismissed - treat that the
      // same as a cancellation rather than showing an error.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGitHub() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authServiceProvider).signInWithGitHub();
      if (user != null) {
        ref.read(bottomNavIndexProvider.notifier).setIndex(0);
      }
      // If user is null, the OAuth popup was cancelled - nothing else to
      // do; the finally block below resets the loading state regardless.
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      // Treat a thrown cancellation (e.g. popup closed by the user) the
      // same as a null result rather than surfacing it as an error.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 40),
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
                  hintText: 'Enter your password',
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: _isLoading ? 'Signing in...' : 'Login',
                  onPressed: _isLoading ? null : _loginWithEmail,
                ),
                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 24),
                SecondaryButton(
                  label: 'Continue with Google',
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  leadingIcon: const _GoogleIcon(),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Continue with GitHub',
                  onPressed: _isLoading ? null : _loginWithGitHub,
                  leadingIcon: const _GitHubIcon(),
                ),
                const SizedBox(height: 24),
                _buildRegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('assets/images/logo_icon.png', height: 90),
        const SizedBox(height: 16),
        const Text(
          'Overload.ai',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Welcome back. Let\'s lift.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: const [
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
          child: const Text(
            'Register',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// Brand icons loaded from assets/images/.
// Kept private to this file since they're only used on this screen.

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/google_logo.png', width: 20, height: 20);
  }
}

class _GitHubIcon extends StatelessWidget {
  const _GitHubIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/github_logo.png', width: 20, height: 20);
  }
}
