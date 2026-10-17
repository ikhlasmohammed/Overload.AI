// Deterministic math for the "Progressive Overload Architect" feature.
//
// Deliberately contains ZERO calls to Groq. The 1RM estimate and the next
// session's target weight/reps are always computed here in plain Dart, so
// they're guaranteed correct even if the AI call fails or is rate-limited.
// Groq's only job (see GroqService) is to phrase a sentence explaining a
// number this file already decided.

/// Epley formula: estimated 1-rep max from a single logged set.
/// 1RM = weight x (1 + reps / 30)
double estimatedOneRepMax(double weight, int reps) {
  if (reps <= 1) return weight;
  return weight * (1 + reps / 30);
}

/// One suggested next-session target, plus the plain-English reason a
/// fallback sentence (or the AI prompt) can use.
class ProgressionSuggestion {
  final double suggestedWeight;
  final int suggestedReps;
  final String triggerReason;

  const ProgressionSuggestion({
    required this.suggestedWeight,
    required this.suggestedReps,
    required this.triggerReason,
  });
}

// Tunable rule constants - kept together so the logic below reads as plain
// English and the rule can be explained in one sentence for Q&A.
const int _upperRepThreshold = 10; // "top of the rep range"
const int _repDropOnWeightIncrease = 3;
const int _minReps = 6;
const double _weightIncrementKg = 2.5;

/// The core progressive-overload rule (matches the Part 1 proposal example:
/// 60kg x 12 reps -> 62.5kg x 9 reps).
///
/// - If the last session hit the top of the rep range, bump the weight up
///   and drop reps back down (more weight, fewer reps - same stimulus).
/// - Otherwise, keep the weight and add one rep (building toward that
///   threshold before the next weight increase).
ProgressionSuggestion suggestNext(double lastWeight, int lastReps) {
  if (lastReps >= _upperRepThreshold) {
    final newReps = (lastReps - _repDropOnWeightIncrease).clamp(
      _minReps,
      lastReps,
    );
    return ProgressionSuggestion(
      suggestedWeight: lastWeight + _weightIncrementKg,
      suggestedReps: newReps,
      triggerReason:
          'you hit the top of your rep range last session, so weight goes up and reps reset lower',
    );
  }

  return ProgressionSuggestion(
    suggestedWeight: lastWeight,
    suggestedReps: lastReps + 1,
    triggerReason:
        'you are still building reps at this weight, so aim for one more rep this session',
  );
}
