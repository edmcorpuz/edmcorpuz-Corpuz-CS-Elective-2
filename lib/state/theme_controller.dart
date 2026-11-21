import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';

/// Light or dark. Starts from the device setting.
// shortcut: the choice isn't saved between visits; add shared_preferences if
// people ask for it to stick.
final themeProvider = NotifierProvider<ThemeController, AppPalette>(ThemeController.new);

class ThemeController extends Notifier<AppPalette> {
  @override
  AppPalette build() =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light;

  void toggle() => state = state.brightness == Brightness.dark ? AppPalette.light : AppPalette.dark;
}
