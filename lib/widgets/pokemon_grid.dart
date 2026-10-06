import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import 'pokemon_card.dart';

class PokemonGrid extends StatelessWidget {
  const PokemonGrid({super.key, required this.pokemon, this.onSelected});
  final List<Pokemon> pokemon;
  final ValueChanged<Pokemon>? onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 220).floor().clamp(2, 5);
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        return GridView.builder(
          key: const PageStorageKey('pokemon-grid'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 220 + (textScale - 1).clamp(0, 3) * 60,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: pokemon.length,
          itemBuilder: (context, index) => PokemonCard(
            pokemon: pokemon[index],
            onTap: onSelected == null
                ? null
                : () => onSelected!(pokemon[index]),
          ),
        );
      },
    );
  }
}
