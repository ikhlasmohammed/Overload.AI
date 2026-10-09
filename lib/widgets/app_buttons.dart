import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable primary action button (blue, full-width, rounded).
///
/// Used for "Start Workout", "Save Set", "Add Exercise", "Save" (schedule),
/// etc. so every primary button across the app looks and behaves the same
/// way without copy-pasting ElevatedButton.styleFrom() everywhere.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final Color? color;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: color != null
          ? ElevatedButton.styleFrom(backgroundColor: color)
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (trailingIcon != null) ...[
            const SizedBox(width: 6),
            Icon(trailingIcon, size: 18),
          ],
        ],
      ),
    );
  }
}

/// Reusable secondary/outline button (e.g. "Cancel", "Skip Rest").
///
/// Pass [leadingIcon] to show a small image/icon on the left — used by
/// the login screen's "Continue with Google / GitHub" buttons.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  /// Optional widget shown to the left of the label (e.g. a brand icon).
  final Widget? leadingIcon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[leadingIcon!, const SizedBox(width: 10)],
          Text(label),
        ],
      ),
    );
  }
}

/// Reusable destructive button (e.g. "End" session).
class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const DangerButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.danger,
        minimumSize: const Size(70, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}
