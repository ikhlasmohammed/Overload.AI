import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// One shared AuthService instance - screens read auth through this
/// instead of each making their own.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Live stream of whoever's signed in (null if nobody is).
///
/// main.dart watches this to decide between the login flow and
/// RootScreen - basically the single source of truth for "is someone
/// logged in right now" everywhere in the app.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
