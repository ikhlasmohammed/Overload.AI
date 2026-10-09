import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis.dart';
import '../models/exercise.dart';
import '../utils/progressive_overload.dart';
import 'recommendation_provider.dart'; // groqServiceProvider
import 'workout_log_provider.dart';

/// Lets the user manually pick which exercise the Estimated 1RM card
/// graphs. Null means "let analysisProvider just pick the most recently
/// trained one automatically."
class SelectedAnalysisExerciseNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String exerciseName) => state = exerciseName;
}

final selectedAnalysisExerciseProvider =
    NotifierProvider<SelectedAnalysisExerciseNotifier, String?>(
      SelectedAnalysisExerciseNotifier.new,
    );

/// Everything the Analysis tab needs, worked out from the signed-in
/// user's real WorkoutLog history, plus one Groq call just for the Key
/// Insights wording.
///
/// Recalculates automatically whenever the logs change (new/edited/
/// deleted set) or the user picks a different exercise for the graph.
final analysisProvider = FutureProvider<AnalysisData>((ref) async {
  final logs = await ref.watch(workoutLogsProvider.future);
  if (logs.isEmpty) return AnalysisData.empty;

  // Exercise picker options - every exercise ever logged, most recently
  // trained first (workoutLogsProvider already streams newest-first).
  final availableExercises = <String>[];
  for (final log in logs) {
    if (!availableExercises.contains(log.exerciseName)) {
      availableExercises.add(log.exerciseName);
    }
  }

  final override = ref.watch(selectedAnalysisExerciseProvider);
  final selected = (override != null && availableExercises.contains(override))
      ? override
      : availableExercises.first;

  // 1RM history for the selected exercise - one point per day trained,
  // using that day's best set (highest Epley estimate) to represent it,
  // same reasoning recommendationsProvider uses for "current" performance.
  final selectedLogs = logs.where((l) => l.exerciseName == selected);
  final bestByDay = <DateTime, double>{};
  for (final log in selectedLogs) {
    final day = DateTime(
      log.loggedAt.year,
      log.loggedAt.month,
      log.loggedAt.day,
    );
    final oneRm = estimatedOneRepMax(log.weight, log.reps);
    if (oneRm > (bestByDay[day] ?? 0)) bestByDay[day] = oneRm;
  }
  final history =
      bestByDay.entries
          .map((e) => OneRmPoint(date: e.key, oneRepMaxKg: e.value))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  final currentOneRm = history.last.oneRepMaxKg;
  final firstOneRm = history.first.oneRepMaxKg;
  final percentChange = (firstOneRm == 0 || history.length < 2)
      ? 0.0
      : ((currentOneRm - firstOneRm) / firstOneRm) * 100;

  // Weekly muscle volume - last 7 days, rolled up by muscle group.
  // muscleGroup is stored directly on WorkoutLog so
  // there's no need to look it up against ExerciseLibrary. Every group
  // shows up even at 0kg so the UI always has all 6 to display.
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  final volumeByGroup = <String, double>{
    for (final g in ExerciseLibrary.muscleGroups) g: 0,
  };
  for (final log in logs) {
    if (log.loggedAt.isBefore(weekAgo)) continue;
    final volume = log.weight * log.reps * log.sets;
    volumeByGroup[log.muscleGroup] =
        (volumeByGroup[log.muscleGroup] ?? 0) + volume;
  }

  // Key insights - the facts below are all worked out here first, never by
  // Groq (same rule progressive_overload.dart follows). Groq just phrases
  // them into sentences; if that call fails, _fallbackInsights takes over.
  final rankedGroups = volumeByGroup.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final facts = <String, dynamic>{
    'topMuscleGroup': rankedGroups.isNotEmpty ? rankedGroups.first.key : null,
    'neglectedMuscleGroup': rankedGroups.length > 1
        ? rankedGroups.last.key
        : null,
    'exercise': selected,
    'oneRmPercentChange': percentChange.toStringAsFixed(1),
  };

  List<String> insights = [];
  try {
    insights = await ref.read(groqServiceProvider).explainKeyInsights(facts);
  } catch (_) {
    // Ignored on purpose - we'd rather fall back to plain sentences than
    // show a raw error on a card that's not even the main content.
  }
  if (insights.isEmpty) {
    insights = _fallbackInsights(facts);
  }

  return AnalysisData(
    availableExercises: availableExercises,
    selectedExercise: selected,
    oneRmHistory: history,
    currentOneRepMaxKg: currentOneRm,
    percentChangeSinceFirstLog: percentChange,
    weeklyVolumeByMuscleGroup: volumeByGroup,
    keyInsights: insights,
  );
});

List<String> _fallbackInsights(Map<String, dynamic> facts) {
  final out = <String>[];
  if (facts['topMuscleGroup'] != null) {
    out.add(
      '${facts['topMuscleGroup']} had your highest training volume this week.',
    );
  }
  if (facts['neglectedMuscleGroup'] != null) {
    out.add(
      '${facts['neglectedMuscleGroup']} has seen the least volume this week - consider adding a set or two.',
    );
  }
  final change = double.tryParse(facts['oneRmPercentChange'].toString()) ?? 0;
  if (change != 0) {
    final direction = change > 0 ? 'up' : 'down';
    out.add(
      'Your estimated 1RM on ${facts['exercise']} is $direction '
      '${change.abs().toStringAsFixed(1)}% since your first log.',
    );
  }
  if (out.isEmpty) {
    out.add('Log a few more sets to start seeing weekly insights here.');
  }
  return out;
}
