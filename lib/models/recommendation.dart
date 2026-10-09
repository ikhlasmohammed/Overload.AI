/// One AI Coach recommendation for a single exercise, built from the
/// user's actual logged history.
class Recommendation {
  final String exerciseName;
  final double currentWeight;
  final int currentReps;
  final double suggestedWeight;
  final int suggestedReps;
  final double estimatedOneRepMaxKg; // worked out with Epley's formula in Dart, not by the AI
  final String reasoning; // Groq's phrasing of why - if that call fails we
  // just fall back to a plain sentence instead of showing an error

  const Recommendation({
    required this.exerciseName,
    required this.currentWeight,
    required this.currentReps,
    required this.suggestedWeight,
    required this.suggestedReps,
    required this.estimatedOneRepMaxKg,
    required this.reasoning,
  });
}
