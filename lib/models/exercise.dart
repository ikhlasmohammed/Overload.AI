/// One exercise definition shown in the workout/exercise lists, e.g.
/// "Bench Press" or "Incline Dumbbell Press".
class Exercise {
  final String name;
  final String muscleGroup; // Chest, Back, Shoulders, Arms, Legs, Core
  final String defaultSets;
  final String defaultReps;
  final String imagePath;

  const Exercise({
    required this.name,
    required this.muscleGroup,
    required this.defaultSets,
    required this.defaultReps,
    this.imagePath = '',
  });
}

/// Small static library of exercises used throughout the app.
class ExerciseLibrary {
  // The 6 muscle groups used everywhere a set gets logged (matches
  // WorkoutLog.muscleGroup). analysisProvider uses this list to roll up
  // weekly volume per group, so groups with 0 sets still show up as 0
  // instead of just disappearing from the chart.
  static const List<String> muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Legs',
    'Arms',
    'Core',
  ];

  static const List<Exercise> all = [
    Exercise(
      name: 'Bench Press',
      muscleGroup: 'Chest',
      defaultSets: '2',
      defaultReps: '10',
    ),
    Exercise(
      name: 'Incline Dumbbell Press',
      muscleGroup: 'Chest',
      defaultSets: '2',
      defaultReps: '10',
    ),
    Exercise(
      name: 'Shoulder Press',
      muscleGroup: 'Shoulders',
      defaultSets: '2',
      defaultReps: '10',
    ),
    Exercise(
      name: 'Tricep Extension',
      muscleGroup: 'Arms',
      defaultSets: '2',
      defaultReps: '10',
    ),
    Exercise(
      name: 'Lat Pulldown',
      muscleGroup: 'Back',
      defaultSets: '3',
      defaultReps: '10',
    ),
    Exercise(
      name: 'Barbell Row',
      muscleGroup: 'Back',
      defaultSets: '3',
      defaultReps: '8',
    ),
    Exercise(
      name: 'Bicep Curl',
      muscleGroup: 'Arms',
      defaultSets: '3',
      defaultReps: '12',
    ),
    Exercise(
      name: 'Squat',
      muscleGroup: 'Legs',
      defaultSets: '3',
      defaultReps: '8',
    ),
    Exercise(
      name: 'Leg Press',
      muscleGroup: 'Legs',
      defaultSets: '3',
      defaultReps: '10',
    ),
    Exercise(
      name: 'Plank',
      muscleGroup: 'Core',
      defaultSets: '3',
      defaultReps: '45s',
    ),
  ];

  static List<Exercise> byMuscleGroup(String group) {
    if (group == 'All') return all;
    return all.where((e) => e.muscleGroup == group).toList();
  }
}
