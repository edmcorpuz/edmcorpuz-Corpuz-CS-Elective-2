import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import 'pokemon_image.dart';

class PokemonCard extends StatelessWidget {
  const PokemonCard({super.key, required this.pokemon, this.onTap});
  final Pokemon pokemon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                pokemon.displayId,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              Expanded(child: PokemonImage(pokemon: pokemon)),
              const SizedBox(height: 12),
              Text(
                pokemon.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
