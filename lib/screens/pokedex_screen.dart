import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/pokedex_provider.dart';
import '../providers/pokedex_state.dart';
import '../widgets/pokedex_shell.dart';
import '../widgets/pokedex_status.dart';
import '../widgets/pokemon_grid.dart';
import 'pokemon_detail_screen.dart';

class PokedexScreen extends ConsumerWidget {
  const PokedexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pokedexProvider);
    final controller = ref.read(pokedexProvider.notifier);
    final visible = state.filteredPokemon;
    return PokedexShell(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: RefreshIndicator(
            onRefresh: controller.fetchPokemon,
            child: CustomScrollView(
              key: const PageStorageKey('pokedex-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FIELD NOTES / KANTO',
                                style: TextStyle(
                                  letterSpacing: 2,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF226653),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Small creatures.\nBig personalities.',
                                style: TextStyle(
                                  fontSize: 30,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Explore the first 30 Pokémon. Find your favorites,\nand give them a name of their own.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          key: const ValueKey('refresh-pokemon'),
                          tooltip: 'Refresh Pokémon',
                          onPressed: state.isLoading
                              ? null
                              : controller.fetchPokemon,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.pokemon.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BROWSE BY TYPE',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 7,
                            runSpacing: 5,
                            children: [
                              ChoiceChip(
                                key: const ValueKey('type-all'),
                                label: const Text('All types'),
                                selected: state.selectedType == null,
                                onSelected: (_) => controller.selectType(null),
                              ),
                              ...state.availableTypes.map(
                                (type) => ChoiceChip(
                                  key: ValueKey('type-$type'),
                                  label: Text(Pokemon.titleCase(type)),
                                  selected: state.selectedType == type,
                                  onSelected: (_) =>
                                      controller.selectType(type),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${visible.length} of ${state.pokemon.length} Pokémon${state.selectedType == null ? '' : ' · ${Pokemon.titleCase(state.selectedType!)}'}',
                            key: const ValueKey('result-count'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.isLoading)
                    const SliverToBoxAdapter(
                      child: LinearProgressIndicator(
                        semanticsLabel: 'Refreshing Pokémon',
                      ),
                    ),
                  if (state.errorMessage != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Card(
                          color: const Color(0xFFFFE7D9),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Could not refresh. Your collection is still here.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(state.errorMessage!),
                                TextButton(
                                  onPressed: controller.fetchPokemon,
                                  child: const Text('Try again'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (visible.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: PokemonGrid(
                        pokemon: visible,
                        onSelected: (pokemon) => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PokemonDetailScreen(pokemonId: pokemon.id),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: PokedexStatus(
                        title: 'No Pokémon match this type',
                        message:
                            'Try All types to see the complete loaded collection.',
                        icon: Icons.filter_alt_off_outlined,
                        onRetry: () => controller.selectType(null),
                        actionLabel: 'Clear type filter',
                      ),
                    ),
                ] else if (state.status == LoadStatus.initial ||
                    state.isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            semanticsLabel: 'Loading Pokémon',
                          ),
                          SizedBox(height: 20),
                          Text('Finding your next favorite…'),
                          SizedBox(height: 6),
                          Text('Fetching Pokémon and their real type data.'),
                        ],
                      ),
                    ),
                  )
                else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: PokedexStatus(
                      title: state.status == LoadStatus.error
                          ? 'Could not load Pokémon'
                          : 'No Pokémon found',
                      message:
                          state.errorMessage ??
                          'PokéAPI returned an empty list. Refresh to try again.',
                      icon: state.status == LoadStatus.error
                          ? Icons.cloud_off_outlined
                          : Icons.catching_pokemon,
                      onRetry: controller.fetchPokemon,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
