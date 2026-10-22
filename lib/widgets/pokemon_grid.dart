import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import 'pokemon_card.dart';

/// A sliver keeps the intro, filters, and grid in one refreshable scroll view.
class PokemonGrid extends StatelessWidget {
  const PokemonGrid({
    super.key,
    required this.pokemon,
    required this.onSelected,
  });
  final List<Pokemon> pokemon;
  final ValueChanged<Pokemon> onSelected;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.crossAxisExtent;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final minimum = width >= 300 && scale <= 1.5 ? 2 : 1;
      final columns = (width / (scale > 1.5 ? 240 : 185)).floor().clamp(
        minimum,
        5,
      );
      return SliverGrid.builder(
        itemCount: pokemon.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: 306 + (scale - 1).clamp(0, 3) * 90,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemBuilder: (context, index) => PokemonCard(
          pokemon: pokemon[index],
          onTap: () => onSelected(pokemon[index]),
        ),
      );
    },
  );
}
