import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_log.dart';
import '../providers/active_session_provider.dart';
import '../providers/workout_log_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import 'add_set_screen.dart';
import 'add_exercise_screen.dart';

/// Today's already-logged sets for one exercise, oldest first (Set 1 at the
/// top, newest at the bottom). This is deliberately the reverse of
/// workoutLogsProvider's own newest-first order (which exists so Home/
/// Recommendations can cheaply find "the most recent log").
List<WorkoutLog> _todaysSetsFor(List<WorkoutLog> logs, String exerciseName) {
  final now = DateTime.now();
  final todaysLogs = logs
      .where(
        (log) =>
            log.exerciseName == exerciseName &&
            log.loggedAt.year == now.year &&
            log.loggedAt.month == now.month &&
            log.loggedAt.day == now.day,
      )
      .toList();
  todaysLogs.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  return todaysLogs;
}

/// The live "Push Day Session" screen.
/// All state (sets, timer) lives in activeSessionProvider so this screen
/// is just a "view" of that shared state - the same pattern as the other
/// screens, keeping logic out of the widget tree.
class WorkoutSessionScreen extends ConsumerWidget {
  final String sessionName;

  const WorkoutSessionScreen({super.key, required this.sessionName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    final current = session.currentExercise;
    final logsAsync = ref.watch(workoutLogsProvider);
    final todaysSets = _todaysSetsFor(
      logsAsync.value ?? const [],
      current.exercise.name,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentExerciseHeader(context, ref, session),
                    const SizedBox(height: 12),
                    if (logsAsync.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (logsAsync.hasError)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Could not load sets: ${logsAsync.error}',
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        ),
                      )
                    else
                      _buildSetsTable(context, ref, todaysSets),
                    const SizedBox(height: 16),
                    _buildAddActionsRow(context, ref, todaysSets),
                    const SizedBox(height: 24),
                    if (session.isResting) _buildRestTimer(context, ref, session),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Header: back arrow, session name, End button ----
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              '$sessionName Session',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          DangerButton(
            label: 'End',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ---- Current exercise image + name + overflow menu, plus Previous/Next
  // controls so the user can move through today's exercises without
  // leaving this screen (there's no other way to reach exercise 2+ once
  // you're inside a session - see WorkoutScreen for how the list itself
  // is derived from today's schedule).
  Widget _buildCurrentExerciseHeader(
    BuildContext context,
    WidgetRef ref,
    ActiveSessionState session,
  ) {
    final index = session.currentExerciseIndex;
    final total = session.exercises.length;

    void goTo(int newIndex) =>
        ref.read(activeSessionProvider.notifier).selectExercise(newIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                session.currentExercise.exercise.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
              ),
              color: AppColors.surfaceLight,
              onSelected: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exercise deleted'),
                    backgroundColor: AppColors.danger,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete Exercise',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (total > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.textPrimary,
                ),
                onPressed: index > 0 ? () => goTo(index - 1) : null,
              ),
              Text(
                'Exercise ${index + 1} of $total',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textPrimary,
                ),
                onPressed: index < total - 1 ? () => goTo(index + 1) : null,
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ---- SET / WEIGHT / REPS table ----
  Widget _buildSetsTable(
    BuildContext context,
    WidgetRef ref,
    List<WorkoutLog> loggedSets,
  ) {
    if (loggedSets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No sets logged yet. Tap "Add Set" to begin.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          // Same horizontal padding as the _SetRow container below (10),
          // otherwise the columns drift out of alignment.
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  'SET',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'WEIGHT',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'REPS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              // Fixed-width spacer matching the fixed-width icon area in
              // _SetRow exactly (see iconAreaWidth), instead of guessing
              // at the rendered width of two IconButtons.
              SizedBox(width: _SetRow.iconAreaWidth),
            ],
          ),
        ),
        ...List.generate(loggedSets.length, (index) {
          final log = loggedSets[index];
          return _SetRow(
            setNumber: index + 1,
            weight: log.weight,
            reps: log.reps,
            onEdit: () => AddSetSheet.show(
              context,
              ref,
              todaysSetsForExercise: loggedSets,
              existingLog: log,
            ),

            onDelete: () => _deleteSet(context, ref, log),
          );
        }),
      ],
    );
  }

  // ---- "+ Add Set" / "+ Add Exercise" row ----
  Widget _buildAddActionsRow(
    BuildContext context,
    WidgetRef ref,
    List<WorkoutLog> todaysSets,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () => AddSetSheet.show(
            context,
            ref,
            todaysSetsForExercise: todaysSets,
          ),
          icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
          label: const Text(
            'Add Set',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
        TextButton.icon(
          onPressed: () => AddExerciseSheet.show(context, ref),
          icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
          label: const Text(
            'Add Exercise',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  // ---- Circular rest timer ----
  // Only rendered while session.isResting is true (see caller) - the
  // countdown itself lives in activeSessionProvider so this is a pure view.
  Widget _buildRestTimer(
    BuildContext context,
    WidgetRef ref,
    ActiveSessionState session,
  ) {
    final remaining = session.restSecondsRemaining;
    final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (remaining % 60).toString().padLeft(2, '0');
    final restLabel = '$minutes:$seconds';
    final progress = session.restDurationSeconds == 0
        ? 0.0
        : remaining / session.restDurationSeconds;

    void dismiss() => ref.read(activeSessionProvider.notifier).skipRest();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              const Text(
                'REST TIMER',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: dismiss,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _RestTimerPainter(progress: progress),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      restLabel,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Rest Remaining',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SecondaryButton(label: 'Skip Rest', onPressed: dismiss),
        ],
      ),
    );
  }

  Future<void> _deleteSet(
    BuildContext context,
    WidgetRef ref,
    WorkoutLog log,
  ) async {
    try {
      await ref.read(workoutLogServiceProvider).deleteLog(log.logId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set deleted'),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete set: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

/// One row in the sets table: set number, weight, reps, edit + delete icons.
/// Pulled out as its own widget since it's rendered in a loop (reuse).
class _SetRow extends StatelessWidget {
  final int setNumber;
  final double weight;
  final int reps;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SetRow({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.onEdit,
    required this.onDelete,
  });

  static const double iconAreaWidth = 80;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '$setNumber',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1)} kg',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$reps',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: iconAreaWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                    onPressed: onEdit,
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.delete,
                      color: AppColors.danger,
                      size: 18,
                    ),
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the circular progress ring for the rest timer.
class _RestTimerPainter extends CustomPainter {
  final double progress;

  _RestTimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final backgroundPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RestTimerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
