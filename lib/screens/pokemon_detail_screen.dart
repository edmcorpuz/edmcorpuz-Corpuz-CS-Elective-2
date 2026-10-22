import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pokedex_provider.dart';
import '../widgets/favorite_button.dart';
import '../widgets/nickname_editor.dart';
import '../widgets/pokedex_shell.dart';
import '../widgets/pokedex_status.dart';
import '../widgets/pokemon_image.dart';
import '../widgets/type_badge.dart';

/// Only an ID is route data; all displayed data is resolved from Riverpod.
/// This also keeps back navigation correct after opening another favorite.
class PokemonDetailScreen extends ConsumerWidget {
  const PokemonDetailScreen({super.key, required this.pokemonId});
  final int pokemonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pokedexProvider);
    final pokemon = state.pokemonById(pokemonId);
    if (pokemon == null) {
      return PokedexShell(
        currentPokemonId: pokemonId,
        body: const PokedexStatus(
          title: 'This Pokémon is not in the collection',
          message: 'Go back and refresh the Pokédex to load it again.',
          icon: Icons.catching_pokemon,
        ),
      );
    }
    final nickname = state.nicknames[pokemon.id];
    final art = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: typeColor(pokemon.types.firstOrNull ?? 'normal'),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'KANTO / ${pokemon.displayId}',
                style: const TextStyle(
                  letterSpacing: 2,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              FavoriteButton(pokemon: pokemon),
            ],
          ),
          SizedBox(
            height: 230,
            width: double.infinity,
            child: PokemonImage(pokemon: pokemon),
          ),
        ],
      ),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'A CLOSER LOOK',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          pokemon.displayName,
          style: const TextStyle(
            fontSize: 36,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pokemon.types.map(TypeBadge.new).toList(),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E7DD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR NICKNAME',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nickname ?? 'A new friend needs a name.',
                style: TextStyle(
                  fontSize: nickname == null ? 15 : 22,
                  fontWeight: nickname == null
                      ? FontWeight.normal
                      : FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                key: ValueKey('detail-nickname-${pokemon.id}'),
                onPressed: () => showNicknameEditor(context, pokemon),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(
                  nickname == null ? 'Give a nickname' : 'Edit nickname',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 32,
          runSpacing: 16,
          children: [
            _Measurement(
              label: 'HEIGHT',
              value: '${pokemon.heightMetres.toStringAsFixed(1)} m',
            ),
            _Measurement(
              label: 'WEIGHT',
              value: '${pokemon.weightKilograms.toStringAsFixed(1)} kg',
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'BASE STATS',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...pokemon.stats.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _statName(entry.key),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: (entry.value / 255).clamp(0, 1),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: const Color(0xFFE2E7DD),
                  semanticsLabel: '${_statName(entry.key)}: ${entry.value}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Live species data from PokéAPI. Nicknames and favorites stay with you during this app session.',
          style: TextStyle(fontSize: 12, color: Color(0xFF66756D), height: 1.5),
        ),
      ],
    );
    return PokedexShell(
      currentPokemonId: pokemon.id,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 720
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: art),
                        const SizedBox(width: 40),
                        Expanded(child: info),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [art, const SizedBox(height: 28), info],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

String _statName(String value) => switch (value) {
  'hp' => 'HP',
  'attack' => 'Attack',
  'defense' => 'Defense',
  'special-attack' => 'Sp. attack',
  'special-defense' => 'Sp. defense',
  'speed' => 'Speed',
  _ => value,
};

class _Measurement extends StatelessWidget {
  const _Measurement({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
