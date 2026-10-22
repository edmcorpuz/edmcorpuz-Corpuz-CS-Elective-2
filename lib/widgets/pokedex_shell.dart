import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pokedex_provider.dart';
import '../screens/pokemon_detail_screen.dart';
import 'favorite_button.dart';
import 'pokemon_image.dart';

/// Both pages use this shell, so favorites are never a home-only feature.
class PokedexShell extends ConsumerWidget {
  const PokedexShell({super.key, required this.body, this.currentPokemonId});
  final Widget body;
  final int? currentPokemonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pokedexProvider);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final compact = MediaQuery.sizeOf(context).width < 520 && scale > 1.25;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56 + (scale - 1).clamp(0, 3) * 16,
        title: const Text(
          'Pokédex',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: compact
                ? IconButton(
                    key: const ValueKey('toggle-favorites'),
                    tooltip:
                        '${state.favoritesExpanded ? 'Collapse' : 'Expand'} favorites (${state.favorites.length})',
                    onPressed: ref
                        .read(pokedexProvider.notifier)
                        .toggleFavoritesPanel,
                    icon: Badge.count(
                      count: state.favorites.length,
                      isLabelVisible: state.favorites.isNotEmpty,
                      child: Icon(
                        state.favoritesExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.favorite_outline,
                      ),
                    ),
                  )
                : Tooltip(
                    message: state.favoritesExpanded
                        ? 'Collapse favorites'
                        : 'Expand favorites',
                    child: TextButton.icon(
                      key: const ValueKey('toggle-favorites'),
                      onPressed: ref
                          .read(pokedexProvider.notifier)
                          .toggleFavoritesPanel,
                      icon: Icon(
                        state.favoritesExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.favorite_outline,
                      ),
                      label: Text('Favorites (${state.favorites.length})'),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: state.favoritesExpanded
                  ? _FavoritesPanel(currentPokemonId: currentPokemonId)
                  : const SizedBox(width: double.infinity),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _FavoritesPanel extends ConsumerWidget {
  const _FavoritesPanel({this.currentPokemonId});
  final int? currentPokemonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pokedexProvider);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Container(
      key: const ValueKey('favorites-panel'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF0E6),
        border: Border(bottom: BorderSide(color: Color(0xFFD7E1D3))),
      ),
      child: state.favorites.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No favorites yet. Tap a heart to keep a Pokémon close.',
                textAlign: TextAlign.center,
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'YOUR FAVORITES · independent of the type filter',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 84 + (scale - 1).clamp(0, 3) * 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.favorites.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final pokemon = state.favorites[index];
                        final nickname = state.nicknames[pokemon.id];
                        return SizedBox(
                          width: 260 + (scale - 1).clamp(0, 3) * 60,
                          child: Card(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey('favorite-entry-${pokemon.id}'),
                              onTap: () {
                                if (currentPokemonId == pokemon.id) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PokemonDetailScreen(
                                      pokemonId: pokemon.id,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 52,
                                      height: 60,
                                      child: PokemonImage(pokemon: pokemon),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pokemon.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            nickname ?? pokemon.displayId,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FavoriteButton(pokemon: pokemon),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
