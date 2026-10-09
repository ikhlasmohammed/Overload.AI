import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Wraps every Firestore call the app needs for the User collection, so no
/// screen or provider ever calls FirebaseFirestore.instance directly.
/// Mirrors the WorkoutLogService pattern.
class UserProfileService {
  final CollectionReference<Map<String, dynamic>> _users = FirebaseFirestore
      .instance
      .collection('User');

  /// Whether a profile document already exists for this UID. This is the
  /// real "has this account finished onboarding" check - it lives in
  /// Firestore, so it's true regardless of which device or install asks.
  Future<bool> profileExists(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists;
  }

  /// CREATE/UPDATE - the document ID is the UID itself (see UserProfile),
  /// so this is always a single targeted write, never a query.
  Future<void> saveProfile(UserProfile profile) {
    return _users.doc(profile.userId).set(profile.toMap());
  }

  /// Live stream of one user's profile document - the single source of
  /// truth for "is this account Premium", same StreamProvider-backed
  /// pattern as WorkoutLogService.streamLogs(). Emits null if the document
  /// doesn't exist (shouldn't happen post-onboarding, but AuthGate can race
  /// this on first sign-in).
  Stream<UserProfile?> streamProfile(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromDoc(doc) : null);
  }

  Future<void> setPremium(String uid, bool value) {
    return _users.doc(uid).update({'isPremium': value});
  }
}
