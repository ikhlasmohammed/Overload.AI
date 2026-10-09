import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nav_provider.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'ai_coach_screen.dart';
import 'profile_screen.dart';

/// The root scaffold shown after the user is authenticated.
///
/// Holds the single BottomNavigationBar and swaps the body between the
/// 4 main tabs based on bottomNavIndexProvider. Using IndexedStack instead
/// of rebuilding screens each time keeps each tab's scroll position and
/// state intact when switching tabs.
///
/// The standalone "Workout" tab was removed - it was a static Push Day
/// list disconnected from what's actually scheduled, redundant with the
/// Home screen's "Start Workout" card (which now correctly loads whatever
/// routine is scheduled for today). workout_screen.dart itself still
/// exists (ExerciseListTile from it is reused by AddExerciseSheet and
/// PremiumPlanScreen), it's just not a tab anymore.
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  static const _screens = [
    HomeScreen(),
    CalendarScreen(),
    AiCoachScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}
