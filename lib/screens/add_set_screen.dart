import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_log.dart';
import '../providers/active_session_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_log_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_modal_sheet.dart';
import '../widgets/duration_stepper_field.dart';
import '../widgets/number_stepper_field.dart';
import '../widgets/app_buttons.dart';

/// "Add Set" modal form, matching the wireframe: SET / WEIGHT (kg) / REPS
/// stepper fields, a "Save Set" button, and a "Cancel" link.
///
/// Handles both CREATE (existingLog is null) and UPDATE (existingLog is the
/// log being edited) against Firestore via workoutLogServiceProvider.
class AddSetSheet extends ConsumerStatefulWidget {
  final WorkoutLog? existingLog;
  final int setNumber;

  const AddSetSheet({
    super.key,
    required this.setNumber,
    this.existingLog,
  });

  /// [todaysSetsForExercise] is this exercise's already-logged sets for
  /// today, used only to work out the next set number - it comes from the
  /// real workoutLogsProvider stream, filtered by the caller.
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required List<WorkoutLog> todaysSetsForExercise,
    WorkoutLog? existingLog,
  }) {
    int setNumber = todaysSetsForExercise.length + 1;
    if (existingLog != null) {
      final index = todaysSetsForExercise.indexWhere(
        (l) => l.logId == existingLog.logId,
      );
      if (index != -1) setNumber = index + 1;
    }

    return AppModalSheet.show(
      context: context,
      title: existingLog == null ? 'Add Set' : 'Edit Set',
      child: AddSetSheet(setNumber: setNumber, existingLog: existingLog),
    );
  }

  @override
  ConsumerState<AddSetSheet> createState() => _AddSetSheetState();
}

class _AddSetSheetState extends ConsumerState<AddSetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _setController;
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late int _restSeconds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingLog;
    _setController = TextEditingController(text: '${widget.setNumber}');
    _weightController = TextEditingController(
      text: '${existing?.weight ?? 60}',
    );
    _repsController = TextEditingController(text: '${existing?.reps ?? 5}');
    // Defaults to whatever rest duration was last used this session, so the
    // user isn't forced to re-pick it before every single set.
    _restSeconds = ref.read(activeSessionProvider).restDurationSeconds;
  }

  @override
  void dispose() {
    _setController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return; // guarded by AuthGate, but keeps this safe

    final currentExercise = ref.read(activeSessionProvider).currentExercise.exercise;
    final weight = double.parse(_weightController.text);
    final reps = int.parse(_repsController.text);
    final sets = int.parse(_setController.text);
    final existing = widget.existingLog;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(workoutLogServiceProvider);
      if (existing == null) {
        await service.addLog(
          WorkoutLog(
            logId: '', // ignored by addLog - Firestore assigns the real ID
            userId: uid,
            exerciseName: currentExercise.name,
            muscleGroup: currentExercise.muscleGroup,
            weight: weight,
            reps: reps,
            sets: sets,
            loggedAt: DateTime.now(),
          ),
        );
        // Reactive trigger, matching the Part 1 proposal: only a genuinely
        // new set starts a rest period - editing a past set shouldn't.
        ref
            .read(activeSessionProvider.notifier)
            .showRestTimer(durationSeconds: _restSeconds);
      } else {
        await service.updateLog(
          existing.copyWith(weight: weight, reps: reps, sets: sets),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing != null ? 'Set updated' : 'Set saved'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save set: $e'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          NumberStepperField(
            label: 'SET',
            controller: _setController,
            step: 1,
            min: 1,
          ),
          const SizedBox(height: 16),
          NumberStepperField(
            label: 'WEIGHT (kg)',
            controller: _weightController,
            step: 2.5,
            min: 0,
            isDecimal: true,
          ),
          const SizedBox(height: 16),
          NumberStepperField(
            label: 'REPS',
            controller: _repsController,
            step: 1,
            min: 0,
          ),
          if (widget.existingLog == null) ...[
            const SizedBox(height: 16),
            DurationStepperField(
              label: 'REST',
              seconds: _restSeconds,
              step: 15,
              min: 15,
              onChanged: (value) => setState(() => _restSeconds = value),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: _isSaving ? 'Saving...' : 'Save Set',
            onPressed: _isSaving ? null : _save,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
