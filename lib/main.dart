import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'services/user_profile_service.dart';
import 'services/notification_service.dart';

import 'screens/root_screen.dart';
import 'theme/app_theme.dart';

/// Checks whether the given UID has a real User profile document in
/// Firestore - i.e. whether onboarding has genuinely been completed for
/// this account, not just on this specific device install. Replaces the
/// old SharedPreferences-only flag, which was wiped by reinstalls/app-data
/// clears even though the account and its WorkoutLog history were fine.
final onboardingCompleteProvider = FutureProvider.family<bool, String>((
  ref,
  uid,
) async {
  return UserProfileService().profileExists(uid);
});

/// App entry point.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();

  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    await FirebaseAuth.instance.authStateChanges().first;
  }

  runApp(const ProviderScope(child: OverloadApp()));
}

class OverloadApp extends ConsumerWidget {
  const OverloadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(themeColorProvider);

    return MaterialApp(
      title: 'Overload.ai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(accent),
      home: const AuthGate(),
    );
  }
}

/// Decides which screen to show based on the live Firebase auth state.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        // ── Gate 1: not signed in ──────────────────────────────────────
        if (user == null) return const LoginScreen();

        // ── Gate 2: email not verified (email/password accounts only) ──
        final isEmailPasswordAccount = user.providerData.any(
          (p) => p.providerId == 'password',
        );
        final needsVerification = isEmailPasswordAccount && !user.emailVerified;
        if (needsVerification) return const VerifyEmailScreen();

        // ── Gate 3: onboarding not yet completed ───────────────────────

        final onboardingAsync = ref.watch(onboardingCompleteProvider(user.uid));

        return onboardingAsync.when(
          data: (done) =>
              done ? const RootScreen() : OnboardingScreen(uid: user.uid),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => OnboardingScreen(uid: user.uid),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text(
            'Something went wrong: $error',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
    );
  }
}
