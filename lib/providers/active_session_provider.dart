import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import 'notification_provider.dart';

/// Default rest time - used the first time before the user picks their own,
/// and as the starting value on the Add Set form's stepper. Just a
/// starting point now, not a hard limit (see restDurationSeconds below).
const int kDefaultRestDurationSeconds = 45;

/// One exercise inside the active session. This only tracks which exercise
/// is currently active - the logged sets themselves come straight from
/// workoutLogsProvider (filtered to this exercise + today), so there's
/// only one place the actual set data lives.
class SessionExercise {
  final Exercise exercise;

  SessionExercise({required this.exercise});
}

/// The state of whatever workout session is currently active.
class ActiveSessionState {
  final String sessionName; // e.g. "Push Day"
  final List<SessionExercise> exercises;
  final int currentExerciseIndex;
  final int restSecondsRemaining; // real, ticking countdown
  final int restDurationSeconds; // user-chosen total, picked on Add Set form
  final bool isResting;

  const ActiveSessionState({
    required this.sessionName,
    required this.exercises,
    this.currentExerciseIndex = 0,
    this.restSecondsRemaining = kDefaultRestDurationSeconds,
    this.restDurationSeconds = kDefaultRestDurationSeconds,
    this.isResting = false,
  });

  SessionExercise get currentExercise => exercises[currentExerciseIndex];

  ActiveSessionState copyWith({
    int? currentExerciseIndex,
    bool? isResting,
    int? restSecondsRemaining,
    int? restDurationSeconds,
  }) {
    return ActiveSessionState(
      sessionName: sessionName,
      exercises: exercises, // list itself only changes via withExerciseAdded()
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
      isResting: isResting ?? this.isResting,
    );
  }

  /// Returns a copy with [exercise] tacked on to the session and made the
  /// current one. Kept separate from copyWith() (which never touches
  /// `exercises`) so nothing else is affected - only AddExerciseSheet's
  /// confirm button calls this.
  ActiveSessionState withExerciseAdded(Exercise exercise) {
    final updated = [...exercises, SessionExercise(exercise: exercise)];
    return ActiveSessionState(
      sessionName: sessionName,
      exercises: updated,
      currentExerciseIndex: updated.length - 1,
      restSecondsRemaining: restSecondsRemaining,
      restDurationSeconds: restDurationSeconds,
      isResting: isResting,
    );
  }
}

class ActiveSessionNotifier extends Notifier<ActiveSessionState> {
  Timer? _restTimer;

  @override
  ActiveSessionState build() {
    // Cancel any running countdown if this provider ever gets disposed
    // (e.g. a hot restart), so it doesn't keep ticking against state that
    // no longer exists.
    ref.onDispose(() => _restTimer?.cancel());

    return ActiveSessionState(
      sessionName: 'Push Day',
      exercises: [
        SessionExercise(exercise: ExerciseLibrary.all[0]), // Bench Press
        SessionExercise(exercise: ExerciseLibrary.all[1]), // Incline DB
        SessionExercise(exercise: ExerciseLibrary.all[2]), // Shoulder Press
        SessionExercise(exercise: ExerciseLibrary.all[3]), // Tricep Ext
      ],
    );
  }

  /// Switches which exercise the session is currently on. Used by
  /// WorkoutScreen when you tap an exercise tile (jumps to that one right
  /// before opening the session), and by WorkoutSessionScreen's
  /// Previous/Next buttons so you can move through the session without
  /// backing out to the tab.
  void selectExercise(int index) {
    state = state.copyWith(currentExerciseIndex: index);
  }

  /// Swaps out the whole session for [sessionName] and [exercises]. Only
  /// HomeScreen's "Start Workout" card uses this, so that button actually
  /// loads whatever routine it's showing (e.g. "Pull Day") instead of
  /// opening onto the default session from build(). WorkoutScreen's own
  /// tiles still just use selectExercise() against that default session -
  /// this doesn't touch that.
  void startSession({
    required String sessionName,
    required List<Exercise> exercises,
  }) {
    _restTimer?.cancel();
    state = ActiveSessionState(
      sessionName: sessionName,
      exercises: exercises.map((e) => SessionExercise(exercise: e)).toList(),
      currentExerciseIndex: 0,
      restSecondsRemaining: kDefaultRestDurationSeconds,
      restDurationSeconds: kDefaultRestDurationSeconds,
      isResting: false,
    );
  }

  /// Adds [exercise] to the live session and switches to it. Called from
  /// AddExerciseSheet's "Add Exercise" button.
  void addExercise(Exercise exercise) {
    state = state.withExerciseAdded(exercise);
  }

  /// Kicks off the rest countdown right after a set gets saved to
  /// Firestore (see AddSetSheet._save()) - this is the "reactive event
  /// after saving a set" bit from the Part 1 proposal. [durationSeconds]
  /// is whatever the user picked on the Add Set form's REST stepper, and
  /// gets remembered here so the next set defaults to the same value
  /// instead of resetting back to 45 every time. Ticks down once a
  /// second; hits zero and it fires a notification
  void showRestTimer({required int durationSeconds}) {
    _restTimer?.cancel();
    state = state.copyWith(
      isResting: true,
      restDurationSeconds: durationSeconds,
      restSecondsRemaining: durationSeconds,
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.restSecondsRemaining - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(isResting: false, restSecondsRemaining: 0);
        ref.read(notificationServiceProvider).showRestOverNotification();
      } else {
        state = state.copyWith(restSecondsRemaining: remaining);
      }
    });
  }

  /// Lets the user cut the rest timer short - wired to both the timer
  /// card's close (x) icon and the "Skip Rest" button.
  void skipRest() {
    _restTimer?.cancel();
    state = state.copyWith(isResting: false);
  }
}

final activeSessionProvider =
    NotifierProvider<ActiveSessionNotifier, ActiveSessionState>(
      ActiveSessionNotifier.new,
    );
