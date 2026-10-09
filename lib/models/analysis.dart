/// One dot on the 1RM history graph - the best estimated 1RM for one
/// exercise on a given day. "Best" = highest Epley estimate out of that
/// day's sets, since later sets in a session are usually weaker from
/// fatigue (same idea used in recommendationsProvider).
class OneRmPoint {
  final DateTime date;
  final double oneRepMaxKg;

  const OneRmPoint({required this.date, required this.oneRepMaxKg});
}

/// Holds everything the Analysis tab needs. Built from real WorkoutLog
/// history plus one AI call just for the Key Insights wording - all the
/// actual numbers are worked out in plain Dart first, Groq only phrases
/// the sentences around them.
class AnalysisData {
  // Every exercise the user has ever logged, most recent first - feeds the
  // exercise picker on the Estimated 1RM card.
  final List<String> availableExercises;

  // Only null if the user hasn't logged anything yet.
  final String? selectedExercise;

  // 1RM history for whichever exercise is selected, oldest first.
  final List<OneRmPoint> oneRmHistory;

  final double currentOneRepMaxKg;

  // How much the estimated 1RM has changed vs the very first log for this
  // exercise. Stays 0 if there's only one data point to compare.
  final double percentChangeSinceFirstLog;

  // kg volume (weight x reps x sets) per muscle group over the last 7 days.
  // Every muscle group shows up here even if it's 0 this week, so the chart
  // doesn't just skip bars.
  final Map<String, double> weeklyVolumeByMuscleGroup;

  final List<String> keyInsights;

  const AnalysisData({
    required this.availableExercises,
    required this.selectedExercise,
    required this.oneRmHistory,
    required this.currentOneRepMaxKg,
    required this.percentChangeSinceFirstLog,
    required this.weeklyVolumeByMuscleGroup,
    required this.keyInsights,
  });

  static const empty = AnalysisData(
    availableExercises: [],
    selectedExercise: null,
    oneRmHistory: [],
    currentOneRepMaxKg: 0,
    percentChangeSinceFirstLog: 0,
    weeklyVolumeByMuscleGroup: {},
    keyInsights: [],
  );
}
