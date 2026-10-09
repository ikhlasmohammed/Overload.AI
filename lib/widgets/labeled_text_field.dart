import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable labeled TextFormField.
///
/// Used for "Session Name" in the Schedule Workout modal, and any other
/// simple labeled text input across the app, so the label + field spacing
/// stays consistent without repeating layout code.
class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool obscureText;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.readOnly = false,
    this.obscureText = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          obscureText: obscureText,
          onTap: onTap,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }
}
