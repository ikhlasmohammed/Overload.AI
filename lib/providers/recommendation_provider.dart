import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recommendation.dart';
import '../models/workout_log.dart';
import '../services/groq_service.dart';
import '../utils/progressive_overload.dart';
import 'workout_log_provider.dart';

final groqServiceProvider = Provider<GroqService>((ref) => GroqService());

/// One Recommendation per exercise the user has actually logged, built
/// from their real Firestore history.
///
/// Recalculates whenever workoutLogsProvider gets new data (a set added,
/// edited, or deleted) - thanks to Riverpod's FutureProvider caching it
/// won't refire on every screen visit, only when the logs actually change.
final recommendationsProvider = FutureProvider<List<Recommendation>>((
  ref,
) async {
  final logs = await ref.watch(workoutLogsProvider.future);
  if (logs.isEmpty) return [];

  // Within one session you usually log several sets of the same exercise,
  // and reps naturally drop off as you get tired (11, then 10, then 8).
  // Just grabbing "whatever was logged last" would mistake that fatigue
  // dip for your real performance. So instead: find the most recent day
  // each exercise was trained, then use the BEST set from that day
  // (highest estimated 1RM) as the baseline to build next session's
  // suggestion from.
  final logsByExercise = <String, List<WorkoutLog>>{};
  for (final log in logs) {
    logsByExercise.putIfAbsent(log.exerciseName, () => []).add(log);
  }

  final latestByExercise = <String, WorkoutLog>{};
  for (final entry in logsByExercise.entries) {
    final exerciseLogs = entry.value;
    final mostRecentDay = exerciseLogs
        .map(
          (log) =>
              DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day),
        )
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final sameDayLogs = exerciseLogs.where((log) {
      final day = DateTime(
        log.loggedAt.year,
        log.loggedAt.month,
        log.loggedAt.day,
      );
      return day == mostRecentDay;
    });

    latestByExercise[entry.key] = sameDayLogs.reduce(
      (best, current) =>
          estimatedOneRepMax(current.weight, current.reps) >
              estimatedOneRepMax(best.weight, best.reps)
          ? current
          : best,
    );
  }

  // The actual weight/reps numbers get worked out here in Dart, never by Groq.
  final suggestions = <String, ProgressionSuggestion>{
    for (final entry in latestByExercise.entries)
      entry.key: suggestNext(entry.value.weight, entry.value.reps),
  };

  // One batched Groq call for the reasoning text behind every exercise at
  // once. If this fails, the numbers above aren't affected at all - only
  // the wording falls back to a plain sentence.
  Map<String, String> reasoningByExercise = {};
  try {
    reasoningByExercise = await ref
        .read(groqServiceProvider)
        .explainRecommendations([
          for (final entry in latestByExercise.entries)
            {
              'exercise': entry.key,
              'currentWeight': entry.value.weight,
              'currentReps': entry.value.reps,
              'suggestedWeight': suggestions[entry.key]!.suggestedWeight,
              'suggestedReps': suggestions[entry.key]!.suggestedReps,
              'trigger': suggestions[entry.key]!.triggerReason,
            },
        ]);
  } catch (_) {
    // Ignored on purpose - falls back to the plain sentence below instead
    // of showing a raw error across the whole tab.
  }

  return [
    for (final entry in latestByExercise.entries)
      Recommendation(
        exerciseName: entry.key,
        currentWeight: entry.value.weight,
        currentReps: entry.value.reps,
        suggestedWeight: suggestions[entry.key]!.suggestedWeight,
        suggestedReps: suggestions[entry.key]!.suggestedReps,
        estimatedOneRepMaxKg: estimatedOneRepMax(
          entry.value.weight,
          entry.value.reps,
        ),
        reasoning:
            reasoningByExercise[entry.key] ??
            'Based on your last session, ${suggestions[entry.key]!.triggerReason}.',
      ),
  ];
});
