import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../providers/active_session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import 'workout_session_screen.dart';

/// NOTE: this screen is no longer used. It used to be the "Workout" tab,
/// but that tab was removed from the bottom nav (see root_screen.dart) once
/// Home's "Start Workout" card started loading the actual scheduled
/// routine directly - having both was redundant and they could show
/// different exercises for the same day.
///
/// This file is kept around only because ExerciseListTile below is still
/// used by add_exercise_screen.dart and premium_plan_screen.dart. The
/// WorkoutScreen class itself is dead code - nothing navigates to it.
class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  // Today's planned routine - matches ActiveSessionNotifier.build()'s
  // default session, so tapping any tile here lines up with what's
  // already loaded when the session screen opens.
  static const String sessionName = 'Push Day';
  static final List<Exercise> plannedExercises = [
    ExerciseLibrary.all[0], // Bench Press
    ExerciseLibrary.all[1], // Incline Dumbbell Press
    ExerciseLibrary.all[2], // Shoulder Press
    ExerciseLibrary.all[3], // Tricep Extension
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(sessionName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: plannedExercises.length,
                itemBuilder: (context, index) {
                  final exercise = plannedExercises[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ExerciseListTile(
                      exercise: exercise,
                      onTap: () => _startSession(context, ref, index),
                      onMenuTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Exercise deleted'),
                            backgroundColor: AppColors.danger,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildProTipCard(),
            ),
          ],
        ),
      ),
    );
  }

  void _startSession(BuildContext context, WidgetRef ref, int startIndex) {
    // plannedExercises here is built in the same order as
    // ActiveSessionNotifier.build()'s exercises, so the tapped index maps
    // directly onto the session's exercise list.
    ref.read(activeSessionProvider.notifier).selectExercise(startIndex);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WorkoutSessionScreen(sessionName: sessionName),
      ),
    );
  }

  Widget _buildProTipCard() {
    return AppCard(
      color: AppColors.surfaceLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Tip',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Focus on progressive overload by increasing weight or reps each week.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// This one's still very much in use, unlike WorkoutScreen above - see the
/// note at the top of this file.
class ExerciseListTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;
  final Widget? trailing;

  const ExerciseListTile({
    super.key,
    required this.exercise,
    this.onTap,
    this.onMenuTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exercise.defaultSets} x ${exercise.defaultReps} reps',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onMenuTap != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              color: AppColors.surfaceLight,
              onSelected: (_) => onMenuTap!(),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete Exercise',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
