import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The 5 accent colours you can pick from on the Profile screen's "Theme
/// Colour" swatches. Index 0 is the original blue and also what you get
/// by default if nothing's been saved yet.
const List<Color> kThemeColorOptions = [
  Color(0xFF3D5CFF), // Blue (default)
  Color(0xFF2ECC71), // Green
  Color(0xFFE74C3C), // Red
  Color(0xFFF39C12), // Orange
  Color(0xFF9B59B6), // Purple
];

const _prefsKey = 'theme_accent_color';

/// Holds whichever accent colour the user picked and saves it to
/// SharedPreferences so it's still there after an app restart.
/// AppTheme.darkTheme() takes this as a parameter and uses it for
/// ColorScheme.primary/secondary, button backgrounds, focused input
/// borders, and the bottom nav bar's selected colour - see
/// theme/app_theme.dart.
///
/// Worth noting: this only changes theme-driven colours (buttons, focus
/// states, nav selection). Screens that hardcode AppColors.primary
/// directly on an Icon/Text instead of reading it from Theme.of(context)
/// keep the original blue - going through and fixing all 60+ of those
/// spots across 18 files felt like overkill for this.
class ThemeColorNotifier extends Notifier<Color> {
  @override
  Color build() {
    _loadSaved();
    return kThemeColorOptions.first;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_prefsKey);
    if (stored != null) {
      state = Color(stored);
    }
  }

  Future<void> setColor(Color color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, color.toARGB32());
  }
}

final themeColorProvider = NotifierProvider<ThemeColorNotifier, Color>(
  ThemeColorNotifier.new,
);
