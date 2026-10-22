import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/pokedex_provider.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.pokemon});
  final Pokemon pokemon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite = ref.watch(
      pokedexProvider.select((state) => state.favoriteIds.contains(pokemon.id)),
    );
    return IconButton(
      key: ValueKey('favorite-${pokemon.id}'),
      tooltip:
          '${favorite ? 'Remove' : 'Add'} ${pokemon.displayName} ${favorite ? 'from' : 'to'} favorites',
      isSelected: favorite,
      selectedIcon: const Icon(Icons.favorite, color: Color(0xFFB7445A)),
      icon: const Icon(Icons.favorite_border, color: Color(0xFF66756D)),
      onPressed: () =>
          ref.read(pokedexProvider.notifier).toggleFavorite(pokemon.id),
    );
  }
}
