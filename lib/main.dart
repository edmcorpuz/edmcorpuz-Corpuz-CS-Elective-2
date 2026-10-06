import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/pokedex_provider.dart';
import 'screens/pokedex_screen.dart';

void main() => runApp(const PokedexApp());

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PokedexProvider()..fetchPokemon(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Pokédex',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB42335)),
          scaffoldBackgroundColor: const Color(0xFFF5F6FA),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: false),
        ),
        home: const PokedexScreen(),
      ),
    );
  }
}
