import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'screens/auth_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/shop_screen.dart';
import 'state/account_controller.dart';
import 'state/shop_controller.dart';
import 'state/theme_controller.dart';
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

class FacetApp extends ConsumerWidget {
  const FacetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themeProvider);
    AppColors.current = palette;
    return MaterialApp(
      // A new key per theme rebuilds every screen with the new palette.
      key: ValueKey(palette.brightness),
      title: 'FACET: 3D Appliance Store',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(palette),
      home: Env.isConfigured ? const AuthGate() : const SetupScreen(),
    );
  }
}

/// Signed out: the login / sign-up screen. Signed in: the shop, once the
/// account's role is known (admins and customers get different screens).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A different account means a fresh catalogue (and cart, see BagController).
    ref.listen(accountProvider.select((a) => a.user?.id), (_, _) => ref.invalidate(shopControllerProvider));
    final account = ref.watch(accountProvider);
    if (!account.signedIn) return const AuthScreen();
    if (!account.roleLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const ShopScreen();
  }
}
