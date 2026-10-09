import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which tab is currently selected in the bottom nav bar.
///
/// It's just a single int, so a plain Notifier is all this needs - didn't
/// see the point in anything fancier.
class BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndexNotifier, int>(
  BottomNavIndexNotifier.new,
);
