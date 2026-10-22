// Optional integration check. Requires internet; not part of offline unit tests.
import 'dart:io';

import 'package:unang_flutter_project/services/pokemon_service.dart';

Future<void> main() async {
  final service = PokemonService();
  try {
    final pokemon = await service.fetchPokemon();
    if (pokemon.length != PokemonService.limit ||
        pokemon.any((p) => p.types.isEmpty)) {
      throw StateError('Expected 30 Pokémon with actual type data.');
    }
    final types = pokemon.expand((p) => p.types).toSet().toList()..sort();
    stdout.writeln(
      'PASS: ${pokemon.length} live Pokémon, ${types.length} available types.',
    );
    stdout.writeln('Types: ${types.join(', ')}');
    stdout.writeln(
      'First: ${pokemon.first.displayName} (${pokemon.first.types.join('/')})',
    );
    stdout.writeln(
      'Last: ${pokemon.last.displayName} (${pokemon.last.types.join('/')})',
    );
  } finally {
    service.dispose();
  }
}
