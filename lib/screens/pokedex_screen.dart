import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokedex_status.dart';
import '../widgets/pokemon_grid.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key, this.service});
  final PokemonService? service;

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  late final PokemonService _service;
  late Future<List<Pokemon>> _pokemon;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? PokemonService();
    _pokemon = _service.fetchPokemon();
  }

  void _retry() {
    setState(() {
      _pokemon = _service.fetchPokemon();
    });
  }

  @override
  void dispose() {
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex')),
      body: FutureBuilder<List<Pokemon>>(
        future: _pokemon,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading Pokémon',
              ),
            );
          }
          if (snapshot.hasError) {
            return PokedexStatus(
              title: 'Could not load Pokémon',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_outlined,
              onRetry: _retry,
            );
          }
          final pokemon = snapshot.data ?? const <Pokemon>[];
          if (pokemon.isEmpty) {
            return PokedexStatus(
              title: 'No Pokémon found',
              message: 'PokéAPI returned an empty list.',
              icon: Icons.catching_pokemon,
              onRetry: _retry,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Text(
                  '${pokemon.length} Pokémon · The first generation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(child: PokemonGrid(pokemon: pokemon)),
            ],
          );
        },
      ),
    );
  }
}
