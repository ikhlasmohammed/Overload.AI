import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable numeric input with a label and -/+ stepper buttons.
///
/// The "Add Set" wireframe has three fields (Set, Weight, Reps) that all
/// look and behave identically - a label, a value, and minus/plus buttons.
/// Rather than writing that layout three times, this single widget is
/// reused for all three, just with different labels/step sizes/controllers.
class NumberStepperField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final double step;
  final double min;
  final bool isDecimal;

  const NumberStepperField({
    super.key,
    required this.label,
    required this.controller,
    this.step = 1,
    this.min = 0,
    this.isDecimal = false,
  });

  double get _currentValue => double.tryParse(controller.text) ?? 0;

  void _setValue(double value) {
    if (value < min) value = min;
    controller.text = isDecimal
        ? value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')
        : value.toInt().toString();
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
                onPressed: () => _setValue(_currentValue - step),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType:
                      TextInputType.numberWithOptions(decimal: isDecimal),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed < min) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.textPrimary),
                onPressed: () => _setValue(_currentValue + step),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
