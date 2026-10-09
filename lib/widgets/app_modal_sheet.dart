import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable bottom-sheet shell used by all modal forms in the app
/// (Add Set, Add Exercise, Schedule Workout).
///
/// Handles the consistent look: rounded top corners, drag handle, title
/// row with a close (X) button, and scrollable content area. This means
/// each modal screen only needs to supply its own form fields as [child].
///
/// Call via [AppModalSheet.show] instead of showModalBottomSheet directly,
/// so every modal in the app behaves consistently.
class AppModalSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const AppModalSheet({super.key, required this.title, required this.child});

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppModalSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the sheet above the keyboard when text fields are focused.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
