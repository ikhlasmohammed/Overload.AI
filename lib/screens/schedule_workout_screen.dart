import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_schedule.dart';
import '../providers/workout_schedule_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_modal_sheet.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/app_buttons.dart';

/// "Schedule Workout" modal, matching the wireframe: Date picker field,
/// Session Name text field, Time picker field, and Cancel / Save buttons.
///
/// Saving creates a real WorkoutSchedule document in Firestore. A "Set
/// Reminder" toggle was deliberately left out - actually notifying the user
/// ahead of a scheduled workout needs flutter_local_notifications'
/// zonedSchedule() (a different API from the Rest Timer's immediate
/// .show()), plus the timezone package and Android exact-alarm permissions,
/// which was out of scope here.

class ScheduleWorkoutSheet extends ConsumerStatefulWidget {
  final DateTime initialDate;

  const ScheduleWorkoutSheet({super.key, required this.initialDate});

  /// Opens this form inside the shared AppModalSheet shell, defaulting to
  /// whichever date is currently selected on the Calendar screen.
  static Future<void> show(BuildContext context, {DateTime? initialDate}) {
    return AppModalSheet.show(
      context: context,
      title: 'Schedule Workout',
      child: ScheduleWorkoutSheet(initialDate: initialDate ?? DateTime.now()),
    );
  }

  @override
  ConsumerState<ScheduleWorkoutSheet> createState() =>
      _ScheduleWorkoutSheetState();
}

class _ScheduleWorkoutSheetState extends ConsumerState<ScheduleWorkoutSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _sessionNameController;
  late TextEditingController _timeController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = const TimeOfDay(hour: 19, minute: 0); // 7:00 PM default
    _dateController = TextEditingController(text: _formatDate(_selectedDate));
    _sessionNameController = TextEditingController(text: 'Push Day');
    _timeController = TextEditingController(text: _formatTime(_selectedTime));
  }

  @override
  void dispose() {
    _dateController.dispose();
    _sessionNameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.day} ${_monthNames[date.month - 1].substring(0, 3)} ${date.year}';

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = _formatTime(picked);
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      // Combine the picked date with the picked time into one DateTime -
      // scheduledDate stores both, matching the Part 1 data dictionary.
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await ref
          .read(workoutScheduleServiceProvider)
          .addSchedule(
            WorkoutSchedule(
              scheduleId: '', // ignored by toMap() - Firestore assigns this
              userId: uid,
              routineName: _sessionNameController.text.trim(),
              scheduledDate: scheduledDateTime,
            ),
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_sessionNameController.text} scheduled'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _showError('Could not schedule this workout. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          LabeledTextField(
            label: 'Date',
            controller: _dateController,
            readOnly: true,
            onTap: _pickDate,
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'Session Name',
            controller: _sessionNameController,
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'Time',
            controller: _timeController,
            readOnly: true,
            onTap: _pickTime,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: _isSaving ? 'Saving...' : 'Save',
                  onPressed: _isSaving ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
