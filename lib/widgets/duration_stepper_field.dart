import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A -/+ stepper for picking a duration, displayed as M:SS (e.g. "1:30")
/// instead of a raw seconds count - used for the Rest Timer duration on
/// the Add Set form.
///
/// Visually matches NumberStepperField's layout so it looks native to the
/// same form, but takes a plain int + onChanged callback instead of a
/// TextEditingController: typing "1:30" into a text field is fiddly to
/// parse and validate, whereas a duration reads and edits far better as
/// tap-to-step buttons than free text.
class DurationStepperField extends StatelessWidget {
  final String label;
  final int seconds;
  final int step;
  final int min;
  final ValueChanged<int> onChanged;

  const DurationStepperField({
    super.key,
    required this.label,
    required this.seconds,
    required this.onChanged,
    this.step = 15,
    this.min = 15,
  });

  String get _formatted {
    final minutes = seconds ~/ 60;
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _adjust(int delta) {
    final next = seconds + delta;
    onChanged(next < min ? min : next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: AppColors.textPrimary),
                onPressed: () => _adjust(-step),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _formatted,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.textPrimary),
                onPressed: () => _adjust(step),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
