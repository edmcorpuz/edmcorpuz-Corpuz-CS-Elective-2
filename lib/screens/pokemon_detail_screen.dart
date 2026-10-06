import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pokedex_provider.dart';
import '../widgets/pokedex_status.dart';
import '../widgets/pokemon_image.dart';

/// Reads the selection from Provider, not a route argument or local copy.
class PokemonDetailScreen extends StatelessWidget {
  const PokemonDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pokemon = context.watch<PokedexProvider>().selectedPokemon;
    return Scaffold(
      appBar: AppBar(title: const Text('Pokémon details')),
      body: pokemon == null
          ? const PokedexStatus(
              title: 'No Pokémon selected',
              message: 'Go back to the Pokédex and choose a Pokémon.',
              icon: Icons.catching_pokemon,
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pokemon.displayId,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 260,
                            width: double.infinity,
                            child: PokemonImage(pokemon: pokemon),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            pokemon.displayName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
