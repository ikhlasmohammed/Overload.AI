import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nav_provider.dart';

/// The app's bottom navigation bar: Home, Calendar, AI Coach, Profile.
///
/// Used once inside RootScreen (see screens/root_screen.dart). Reading and
/// writing bottomNavIndexProvider here keeps the selected-tab logic in one
/// place instead of duplicating a BottomNavigationBar on every screen.
class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => ref.read(bottomNavIndexProvider.notifier).setIndex(index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: 'Calendar'),
        BottomNavigationBarItem(
            icon: Icon(Icons.psychology), label: 'AI Coach'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
