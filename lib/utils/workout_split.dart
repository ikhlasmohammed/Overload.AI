import '../models/exercise.dart';

/// Extra exercises shown only inside the Premium workout program.
/// Deliberately kept out of ExerciseLibrary.all so they never appear in the
/// regular Add Exercise picker or Analysis tab - Premium is meant to feel
/// like it unlocks new content, not just repackage the free exercise list.
const List<Exercise> _premiumExercises = [
  Exercise(
    name: 'Push-Up',
    muscleGroup: 'Chest',
    defaultSets: '3',
    defaultReps: '15',
  ),
  Exercise(
    name: 'Cable Chest Fly',
    muscleGroup: 'Chest',
    defaultSets: '3',
    defaultReps: '12',
  ),
  Exercise(
    name: 'Pull-Up',
    muscleGroup: 'Back',
    defaultSets: '3',
    defaultReps: '8',
  ),
  Exercise(
    name: 'Seated Cable Row',
    muscleGroup: 'Back',
    defaultSets: '3',
    defaultReps: '10',
  ),
  Exercise(
    name: 'Lateral Raise',
    muscleGroup: 'Shoulders',
    defaultSets: '3',
    defaultReps: '12',
  ),
  Exercise(
    name: 'Front Raise',
    muscleGroup: 'Shoulders',
    defaultSets: '3',
    defaultReps: '12',
  ),
  Exercise(
    name: 'Hammer Curl',
    muscleGroup: 'Arms',
    defaultSets: '3',
    defaultReps: '10',
  ),
  Exercise(
    name: 'Skull Crusher',
    muscleGroup: 'Arms',
    defaultSets: '3',
    defaultReps: '10',
  ),
  Exercise(
    name: 'Romanian Deadlift',
    muscleGroup: 'Legs',
    defaultSets: '3',
    defaultReps: '8',
  ),
  Exercise(
    name: 'Walking Lunge',
    muscleGroup: 'Legs',
    defaultSets: '3',
    defaultReps: '12',
  ),
  Exercise(
    name: 'Calf Raise',
    muscleGroup: 'Legs',
    defaultSets: '3',
    defaultReps: '15',
  ),
  Exercise(
    name: 'Russian Twist',
    muscleGroup: 'Core',
    defaultSets: '3',
    defaultReps: '20',
  ),
  Exercise(
    name: 'Hanging Leg Raise',
    muscleGroup: 'Core',
    defaultSets: '3',
    defaultReps: '12',
  ),
];

/// The free-catalogue exercises for [group] (ExerciseLibrary) plus the
/// Premium-only ones for that same group.
List<Exercise> _exercisesForGroup(String group) => [
  ...ExerciseLibrary.byMuscleGroup(group),
  ..._premiumExercises.where((e) => e.muscleGroup == group),
];

/// One training day within a generated split - a label plus the muscle
/// groups trained that day. Exercises are resolved live (catalogue +
/// Premium-only) so the split always reflects the current exercise list
/// rather than a frozen copy.
class SplitDay {
  final String label;
  final List<String> muscleGroups;

  const SplitDay({required this.label, required this.muscleGroups});

  List<Exercise> get exercises =>
      muscleGroups.expand(_exercisesForGroup).toList();
}

/// A full weekly workout split - the "Full Workout Program" content
/// unlocked by PremiumPlanScreen once UserProfile.isPremium is true.
class WorkoutSplit {
  final String name;
  final String setsRepsGuide;
  final List<SplitDay> days;

  const WorkoutSplit({
    required this.name,
    required this.setsRepsGuide,
    required this.days,
  });
}

/// Deterministic rule-based split chosen from [goal]
/// ('Hypertrophy' | 'Strength' | 'Endurance', see UserProfile.goal). No AI
/// call - this is the "Custom Workout Splits tailored to your height,
/// weight and goals" promised on PremiumPlanScreen, kept as a simple
/// lookup rather than a second AI feature layered on top of the
/// Progressive Overload Architect.
WorkoutSplit generateWorkoutSplit(String goal) {
  switch (goal) {
    case 'Strength':
      return const WorkoutSplit(
        name: 'Full Body Strength (3-Day)',
        setsRepsGuide:
            'Aim for 4-5 sets x 4-6 reps, with longer rests between sets.',
        days: [
          SplitDay(
            label: 'Day 1 - Full Body A',
            muscleGroups: ['Chest', 'Back', 'Legs'],
          ),
          SplitDay(
            label: 'Day 2 - Full Body B',
            muscleGroups: ['Shoulders', 'Arms', 'Core'],
          ),
          SplitDay(
            label: 'Day 3 - Full Body C',
            muscleGroups: ['Legs', 'Chest', 'Back'],
          ),
        ],
      );

    case 'Endurance':
      return const WorkoutSplit(
        name: 'Full Body Endurance Circuit (3-Day)',
        setsRepsGuide:
            'Aim for 2-3 sets x 15-20 reps, with short rests between sets.',
        days: [
          SplitDay(
            label: 'Day 1 - Circuit A',
            muscleGroups: ['Chest', 'Legs', 'Core'],
          ),
          SplitDay(
            label: 'Day 2 - Circuit B',
            muscleGroups: ['Back', 'Shoulders', 'Core'],
          ),
          SplitDay(
            label: 'Day 3 - Circuit C',
            muscleGroups: ['Arms', 'Legs', 'Core'],
          ),
        ],
      );

    case 'Hypertrophy':
    default:
      return const WorkoutSplit(
        name: 'Push / Pull / Legs (Hypertrophy)',
        setsRepsGuide:
            'Aim for 3-4 sets x 8-12 reps, with moderate rests between sets.',
        days: [
          SplitDay(
            label: 'Day 1 - Push',
            muscleGroups: ['Chest', 'Shoulders', 'Arms'],
          ),
          SplitDay(label: 'Day 2 - Pull', muscleGroups: ['Back', 'Arms']),
          SplitDay(
            label: 'Day 3 - Legs & Core',
            muscleGroups: ['Legs', 'Core'],
          ),
        ],
      );
  }
}
