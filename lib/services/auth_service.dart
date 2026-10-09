import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps every Firebase Auth call the app needs, so screens never touch
/// FirebaseAuth.instance directly.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '265159237074-kmirrf6u3530fkco51e8i658iho1pnbq.apps.googleusercontent.com',
  );

  /// Stream of auth state changes (signed in / signed out) AND in-place
  /// updates to the current user (e.g. emailVerified flipping to true
  /// after reload()). main.dart's AuthGate depends on reacting to that
  /// second case - authStateChanges() alone only fires on sign-in/out,
  /// so it would never notice a verified-email update without this.
  Stream<User?> get authStateChanges => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------
  // Email / Password
  // ---------------------------------------------------------------------

  Future<User?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Send the verification email right away, so the "Email
      // Verification" account-management feature kicks in immediately.
      await credential.user?.sendEmailVerification();
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  // Email verification (account management feature #1)

  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('No signed-in user.');
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Change password (account management feature #2)

  /// Updates the current user's password. Firebase requires a "recent"
  /// sign-in for security-sensitive actions like this, so the current
  /// password is used to re-authenticate first.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw AuthException('No signed-in user.');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  // Google Sign-In (auth method #1 not covered in class)

  Future<User?> signInWithGoogle() async {
    try {
      // Start sign-in flow (matches the lab's signInWithGoogle() pattern).
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled login

      // Get authentication details.
      final googleAuth = await googleUser.authentication;

      // Create Firebase credential.
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential.
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  // GitHub Sign-In (auth method #2)

  /// Signs in with GitHub via Firebase's generic OAuthProvider flow.
  /// Requires GitHub to be enabled as a Sign-in method in the Firebase
  /// Console (Authentication > Sign-in method), with a GitHub OAuth App
  /// client ID/secret configured there.
  Future<User?> signInWithGitHub() async {
    try {
      final githubProvider = GithubAuthProvider();

      if (kIsWeb) {
        final userCredential = await _auth.signInWithPopup(githubProvider);
        return userCredential.user;
      }

      final userCredential = await _auth.signInWithProvider(githubProvider);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  // Sign out

  Future<void> signOut() async {
    // Sign out of Google too, otherwise the account picker won't show
    // next time - it'd silently re-use the cached Google session.
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  // Error message mapping

  String _messageFor(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method. Sign in with that provider instead.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please sign in again before retrying this action.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }
}

/// Exception carrying a message that's already safe to show directly to
/// the user (see AuthService._messageFor above).
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
