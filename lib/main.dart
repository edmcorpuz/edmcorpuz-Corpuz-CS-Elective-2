import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

/// Root widget of the app.
///
/// This checkpoint doesn't need any app-wide state yet (no cart, no
/// theme toggle), so this stays a plain StatelessWidget wrapping
/// MaterialApp.router — the entry point for Navigation 2.0.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HomeHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: appRouter,
    );
  }
}
