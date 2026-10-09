import 'package:cloud_firestore/cloud_firestore.dart';

/// One row in the User collection. The document ID is just the Firebase Auth UID - no separate
/// userId field needed since Firebase already gives us a unique ID.
///
/// Gets written once by OnboardingScreen right after signup/first login.
/// Whether this document exists at all is how AuthGate decides if
/// onboarding is done - that way it survives reinstalls and new devices,
/// instead of relying on a SharedPreferences flag that would get wiped.
class UserProfile {
  final String userId;
  final String? displayName;
  final DateTime dateOfBirth;
  final String gender; // 'Male' | 'Female'
  final double weight; // kg
  final double height; // cm
  final String goal; // 'Hypertrophy' | 'Strength' | 'Endurance'
  final bool isPremium;
  final DateTime accountCreated;

  const UserProfile({
    required this.userId,
    required this.displayName,
    required this.dateOfBirth,
    required this.gender,
    required this.weight,
    required this.height,
    required this.goal,
    this.isPremium = false,
    required this.accountCreated,
  });

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      userId: doc.id,
      displayName: data['displayName'] as String?,
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      gender: data['gender'] as String,
      weight: (data['weight'] as num).toDouble(),
      height: (data['height'] as num).toDouble(),
      goal: data['goal'] as String,
      isPremium: data['isPremium'] as bool? ?? false,
      accountCreated: (data['accountCreated'] as Timestamp).toDate(),
    );
  }

  /// No userId field here on purpose - it's already the document ID
  /// (same idea as WorkoutLog leaving out logId).
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'weight': weight,
      'height': height,
      'goal': goal,
      'isPremium': isPremium,
      'accountCreated': Timestamp.fromDate(accountCreated),
    };
  }
}
