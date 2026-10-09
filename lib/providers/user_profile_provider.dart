import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import 'auth_provider.dart';

final userProfileServiceProvider = Provider<UserProfileService>(
  (ref) => UserProfileService(),
);

/// Live stream of the signed-in user's profile document - same idea as
/// workoutLogsProvider being the source of truth for logs.
///
/// PremiumPlanScreen checks profile.isPremium here to decide whether to
/// show the NETS QR payment flow or the already-unlocked content. Emits
/// null while signed out, or before the profile doc exists yet.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(userProfileServiceProvider).streamProfile(user.uid);
});
