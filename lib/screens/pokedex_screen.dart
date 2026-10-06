import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pokedex_provider.dart';
import '../widgets/pokedex_status.dart';
import '../widgets/pokemon_grid.dart';
import 'pokemon_detail_screen.dart';

class PokedexScreen extends StatelessWidget {
  const PokedexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<PokedexProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        actions: [
          IconButton(
            tooltip: 'Refresh Pokémon',
            onPressed: appState.isLoading
                ? null
                : () => context.read<PokedexProvider>().fetchPokemon(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: switch (appState.state) {
        PokedexState.initial || PokedexState.loading => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Loading Pokémon'),
        ),
        PokedexState.error => PokedexStatus(
          title: 'Could not load Pokémon',
          message: appState.errorMessage!,
          icon: Icons.cloud_off_outlined,
          onRetry: () => context.read<PokedexProvider>().fetchPokemon(),
        ),
        PokedexState.empty => PokedexStatus(
          title: 'No Pokémon found',
          message: 'PokéAPI returned an empty list. Refresh to try again.',
          icon: Icons.catching_pokemon,
          onRetry: () => context.read<PokedexProvider>().fetchPokemon(),
        ),
        PokedexState.success => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Text(
                '${appState.pokemon.length} Pokémon · The first generation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: context.read<PokedexProvider>().fetchPokemon,
                child: PokemonGrid(
                  pokemon: appState.pokemon,
                  onSelected: (pokemon) {
                    context.read<PokedexProvider>().selectPokemon(pokemon.id);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PokemonDetailScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      },
    );
  }
}
