import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'screens/setup_screen.dart';
import 'screens/shop_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.isConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseKey,
    );
  }
  runApp(const ProviderScope(child: FacetApp()));
}

class FacetApp extends StatelessWidget {
  const FacetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FACET — 3D Object Store',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Env.isConfigured ? const ShopScreen() : const SetupScreen(),
    );
  }
}
