import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nets_state.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/nets_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../utils/workout_split.dart';
import '../widgets/app_card.dart';
import '../widgets/nets_widget.dart';
import 'workout_screen.dart' show ExerciseListTile;

/// "Buy Premium Plan" screen, reached from ProfileScreen.
///
/// Gates its own QR card on netsProvider + the signed-in user's Firestore
/// profile: if isPremium is already true (a previous purchase), or the
/// current NETS payment attempt has just settled ("complete"), the full
/// workout program is shown as unlocked. Otherwise NETSWidget drives the
/// live NETS QR payment flow (Mini-Project #10, Section G/H) for a $9.99
/// one-time purchase.
class PremiumPlanScreen extends ConsumerWidget {
  const PremiumPlanScreen({super.key});

  static const double amount = 9.99;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => _buildBody(context, ref, profile),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Could not load your profile: $e',
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, UserProfile? profile) {
    final netsStatus = ref.watch(netsProvider).status;
    final unlocked = (profile?.isPremium ?? false) || netsStatus == NETSStatus.complete;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeaderCard(unlocked),
          const SizedBox(height: 16),
          unlocked
              ? _buildUnlockedCard(context, ref, profile)
              : const NETSWidget(amount: amount),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool unlocked) {
    return AppCard(
      child: Column(
        children: [
          const Text(
            'Full Workout Program',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            unlocked ? Icons.verified : Icons.check,
            color: unlocked ? AppColors.success : AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: 12),
          const Text(
            'Custom Workout Splits tailored specifically to your height, weight and goals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedCard(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
  ) {
    final split = generateWorkoutSplit(profile?.goal ?? 'Hypertrophy');

    return Column(
      children: [
        AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                const Icon(
                  Icons.workspace_premium,
                  color: AppColors.success,
                  size: 56,
                ),
                const SizedBox(height: 12),
                const Text(
                  "You're a Premium Member!",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  split.name,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  split.setsRepsGuide,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final day in split.days) ...[
          const SizedBox(height: 16),
          _buildSplitDayCard(day),
        ],
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => _confirmCancelMembership(context, ref),
            child: const Text(
              'Cancel Membership',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmCancelMembership(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Cancel Premium?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          "You'll lose access to your Full Workout Program immediately. "
          "You can buy Premium again anytime.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Keep Premium',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _cancelMembership(context, ref);
            },
            child: const Text(
              'Cancel Membership',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelMembership(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(userProfileServiceProvider).setPremium(uid, false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Premium membership cancelled.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not cancel membership: $e')),
      );
    }
  }

  Widget _buildSplitDayCard(SplitDay day) {
    return AppCard(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (final exercise in day.exercises) ...[
            ExerciseListTile(exercise: exercise),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
