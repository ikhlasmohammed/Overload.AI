import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_buttons.dart';

/// Shown when a user is signed in but hasn't clicked the verification
/// link yet - the "mandatory security gate" described in the proposal,
/// blocking access to log history (i.e. the rest of the app) until
/// verified.
///
/// Polls [checkEmailVerified] every 3 seconds so the screen advances on
/// its own the moment the user taps the link in their email, without
/// needing a manual "I've verified, let me in" button.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _pollTimer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Silent background check - no loading spinner, no SnackBar. Calling
  /// reload() here updates FirebaseAuth's cached user; since AuthService
  /// now exposes userChanges() (not just authStateChanges()), that
  /// update is enough on its own to make main.dart's AuthGate re-run and
  /// move on to Onboarding/Home automatically once verified.
  Future<void> _poll() async {
    await ref.read(authServiceProvider).checkEmailVerified();
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authServiceProvider).resendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email resent.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.read(authServiceProvider).currentUser?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread,
                color: AppColors.primary,
                size: 56,
              ),
              const SizedBox(height: 20),
              const Text(
                'Verify your email',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to $email. '
                'Click it to activate your account - this screen will '
                'update automatically once you do.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Waiting for verification...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SecondaryButton(
                label: _isResending ? 'Resending...' : 'Resend Email',
                onPressed: _isResending ? null : _resendEmail,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                child: const Text(
                  'Sign out',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
