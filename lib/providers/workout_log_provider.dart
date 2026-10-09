import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_log.dart';
import '../services/workout_log_service.dart';
import 'auth_provider.dart';

final workoutLogServiceProvider = Provider<WorkoutLogService>(
  (ref) => WorkoutLogService(),
);

/// Live stream of the signed-in user's WorkoutLog history, newest first.
///
/// This is where every screen reads historical workout logs from - Home's
/// Weekly Progress stats, the Workout Session screen's sets table, the AI
/// Coach Recommendations, and the Analysis tab. Emits an empty list if
/// nobody's signed in.
final workoutLogsProvider = StreamProvider<List<WorkoutLog>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <WorkoutLog>[]);
  return ref.watch(workoutLogServiceProvider).streamLogs(user.uid);
});

/// Filters the logs down to one exercise.
List<WorkoutLog> logsForExercise(List<WorkoutLog> logs, String exerciseName) {
  return logs.where((log) => log.exerciseName == exerciseName).toList();
}

/// Adds up total volume (kg) across all the logs. Used by Home's "Weekly
/// Progress" stat tile.
double totalVolume(List<WorkoutLog> logs) {
  double total = 0;
  for (final log in logs) {
    total += log.weight * log.reps * log.sets;
  }
  return total;
}

/// Breaks down the current calendar week (Mon-Sun) for Home's Weekly
/// Progress card - the chart, the "Total Volume" tile, and "Sessions"
/// tile all come from this.
///
/// "This week" means Monday through Sunday of today, not a rolling 7
/// days - so on a Tuesday, seeing "2 / 7" for Sessions is correct (only
/// Monday and Tuesday have happened, the rest of the week just has no
/// logs yet).
///
/// Uses DateTime.now().weekday (1 = Monday ... 7 = Sunday) to find this
/// week's Monday and anchor the window from there, and to tell the UI
/// which of the 7 bars is "today" so it can highlight it.
({
  Map<String, double> dailyVolume,
  int sessionsTrained,
  double volumeThisWeek,
}) weeklyProgress(List<WorkoutLog> logs) {
  final now = DateTime.now();
  final monday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));

  const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final dailyVolume = <String, double>{for (final d in dayLabels) d: 0};

  for (final log in logs) {
    final day = DateTime(
      log.loggedAt.year,
      log.loggedAt.month,
      log.loggedAt.day,
    );
    final dayIndex = day.difference(monday).inDays;
    if (dayIndex < 0 || dayIndex > 6) continue; // not in the current week
    final label = dayLabels[dayIndex];
    dailyVolume[label] = dailyVolume[label]! + (log.weight * log.reps * log.sets);
  }

  return (
    dailyVolume: dailyVolume,
    sessionsTrained: dailyVolume.values.where((v) => v > 0).length,
    volumeThisWeek: dailyVolume.values.fold<double>(0, (a, b) => a + b),
  );
}
