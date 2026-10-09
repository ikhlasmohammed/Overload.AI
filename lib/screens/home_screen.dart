import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../models/workout_log.dart';
import '../models/recommendation.dart';
import '../models/workout_schedule.dart';
import '../providers/active_session_provider.dart';
import '../providers/workout_schedule_provider.dart';
import '../providers/workout_log_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_buttons.dart';
import 'workout_session_screen.dart';

/// Home screen - the app's main dashboard shown after login.

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(workoutScheduleProvider);
    final upcomingList = upcoming(schedulesAsync.value ?? const []);
    final todayWorkout = upcomingList.isNotEmpty ? upcomingList.first : null;
    final logsAsync = ref.watch(workoutLogsProvider);
    final progress = weeklyProgress(logsAsync.value ?? const []);
    final user = ref.watch(authStateProvider).value;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.email?.split('@').first ?? 'Athlete';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref, displayName),
              const SizedBox(height: 20),
              _buildTodaysWorkoutCard(context, ref, todayWorkout),
              const SizedBox(height: 16),
              _buildAiRecommendationCard(
                context,
                ref,
                logsAsync.value ?? const [],
                ref.watch(recommendationsProvider),
              ),
              const SizedBox(height: 16),
              _buildWeeklyProgressCard(progress),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Header row: logo, greeting ----
  Widget _buildHeader(BuildContext context, WidgetRef ref, String displayName) {
    return Row(
      children: [
        Image.asset('assets/images/logo_icon.png', height: 32),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good Morning,',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            Text(
              displayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Today's Workout card ----
  Widget _buildTodaysWorkoutCard(
    BuildContext context,
    WidgetRef ref,
    dynamic todayWorkout,
  ) {
    final routineName = todayWorkout?.routineName ?? 'Rest Day';
    final muscleGroups = muscleGroupsForRoutine(routineName);
    // Only used by this card's own "Start Workout" button, so it actually
    // loads what it visibly claims to (e.g. "Pull Day" exercises) instead
    // of always opening onto WorkoutScreen's static default session.
    // WorkoutScreen's own tab is untouched - still the fixed Push Day list.
    final exercises = todayWorkout == null
        ? const <Exercise>[]
        : routineMuscleGroups(
            routineName,
          ).expand(ExerciseLibrary.byMuscleGroup).toList();
    final canStart = todayWorkout != null && exercises.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Workout",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.accessibility_new,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routineName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      muscleGroups,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Start Workout',
            trailingIcon: Icons.arrow_forward,
            onPressed: !canStart
                ? null
                : () {
                    ref
                        .read(activeSessionProvider.notifier)
                        .startSession(
                          sessionName: routineName,
                          exercises: exercises,
                        );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            WorkoutSessionScreen(sessionName: routineName),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  // ---- AI Recommendation card ----
  Widget _buildAiRecommendationCard(
    BuildContext context,
    WidgetRef ref,
    List<WorkoutLog> logs,
    AsyncValue<List<Recommendation>> recsAsync,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Recommendation',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          recsAsync.when(
            data: (recs) {
              if (recs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Log your first set to get a recommendation.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              // Prefer the exercise trained most recently (logs are newest
              // first), falling back to the first available recommendation.
              final mostRecentExercise = logs.isNotEmpty
                  ? logs.first.exerciseName
                  : null;
              final rec = recs.firstWhere(
                (r) => r.exerciseName == mostRecentExercise,
                orElse: () => recs.first,
              );
              final weightLabel = rec.suggestedWeight % 1 == 0
                  ? rec.suggestedWeight.toInt().toString()
                  : rec.suggestedWeight.toString();

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Increase ${rec.exerciseName} to',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        Text(
                          '$weightLabel kg x ${rec.suggestedReps} reps',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'For your next session',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology_alt,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 56,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "Couldn't load your recommendation right now.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'View Full Plan',
            onPressed: () {
              // Navigates to the AI Coach tab via the bottom nav provider.
              // Index 2: Home(0), Calendar(1), AI Coach(2), Profile(3) -
              // shifted down since the Workout tab was removed.
              ref.read(bottomNavIndexProvider.notifier).setIndex(2);
            },
          ),
        ],
      ),
    );
  }

  // ---- Weekly Progress card with bar chart ----
  Widget _buildWeeklyProgressCard(
    ({
      Map<String, double> dailyVolume,
      int sessionsTrained,
      double volumeThisWeek,
    }) progress,
  ) {
    final dailyVolume = progress.dailyVolume;
    // Chart scales to whichever day was heaviest this week (with a little
    // headroom), instead of a fixed 200kg ceiling that didn't mean anything.
    final maxDayVolume = dailyVolume.values.fold<double>(
      0,
      (max, v) => v > max ? v : max,
    );
    final chartMax = maxDayVolume == 0 ? 1.0 : maxDayVolume * 1.15;
    // DateTime.now().weekday is 1 (Mon) ... 7 (Sun), so subtracting 1 lines
    // it up with dailyVolume's Mon-first key order for highlighting today.
    final todayIndex = DateTime.now().weekday - 1;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Progress',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  icon: Icons.fitness_center,
                  value: '${progress.volumeThisWeek.toStringAsFixed(0)} kg',
                  label: 'Total Volume',
                ),
              ),
              Expanded(
                child: _statTile(
                  icon: Icons.calendar_today,
                  value: '${progress.sessionsTrained} / 7',
                  label: 'Sessions',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyVolume.entries.toList().asMap().entries.map((
                indexed,
              ) {
                final dayIndex = indexed.key;
                final entry = indexed.value;
                final isToday = dayIndex == todayIndex;
                final barHeight = (entry.value / chartMax) * 110;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        entry.value > 0 ? '${entry.value.round()}' : '0',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: barHeight < 4 ? 4 : barHeight,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.success
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: isToday
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
