import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'state/theme_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/theme_reveal.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, themeMode, child) {
        return MaterialApp.router(
          title: 'HomeHub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: appRouter,
          builder: (context, child) {
            final revealColor = themeMode == ThemeMode.dark
                ? AppTheme.dark.colorScheme.primary
                : AppTheme.light.colorScheme.primary;
            final targetTheme = themeMode == ThemeMode.dark
                ? AppTheme.dark
                : AppTheme.light;
            return AnimatedTheme(
              data: targetTheme,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              child: ThemeRevealOverlay(
                key: ValueKey(themeController.transitionId),
                origin: themeController.revealOrigin,
                oldImage: themeController.previousImage,
                revealColor: revealColor,
                child: RepaintBoundary(
                  key: themeController.contentKey,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
