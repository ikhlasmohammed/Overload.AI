import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable rounded card container with consistent padding and background.
///
/// Used on the Home screen ("Today's Workout", "AI Recommendation",
/// "Weekly Progress" cards), and reusable anywhere else a card-style
/// container is needed, so we don't repeat the same BoxDecoration code
/// in every screen.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Reads the current theme's card colour (see AppTheme.darkTheme(),
    // which tints this per the selected theme colour) rather than the
    // fixed AppColors.surface constant, so every AppCard across the app
    // re-tints immediately when the user picks a different theme colour
    // on the Profile screen - no per-screen changes needed.
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardTheme.color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: card,
    );
  }
}
