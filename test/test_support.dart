import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unang_flutter_project/models/pokemon.dart';
import 'package:unang_flutter_project/providers/pokedex_provider.dart';
import 'package:unang_flutter_project/services/pokemon_service.dart';

final samplePokemon = <Pokemon>[
  Pokemon(
    id: 1,
    name: 'bulbasaur',
    imageUrl: 'https://example.test/1.png',
    types: ['grass', 'poison'],
    heightDecimetres: 7,
    weightHectograms: 69,
    stats: {'hp': 45, 'attack': 49},
  ),
  Pokemon(
    id: 4,
    name: 'charmander',
    imageUrl: 'https://example.test/4.png',
    types: ['fire'],
    heightDecimetres: 6,
    weightHectograms: 85,
    stats: {'hp': 39},
  ),
  Pokemon(
    id: 7,
    name: 'squirtle',
    imageUrl: 'https://example.test/7.png',
    types: ['water'],
    heightDecimetres: 5,
    weightHectograms: 90,
    stats: {'hp': 44},
  ),
  Pokemon(
    id: 25,
    name: 'pikachu',
    imageUrl: 'https://example.test/25.png',
    types: ['electric'],
    heightDecimetres: 4,
    weightHectograms: 60,
    stats: {'hp': 35},
  ),
];

class FakePokemonService extends PokemonService {
  FakePokemonService({Future<List<Pokemon>> Function()? loader})
    : loader = loader ?? (() async => samplePokemon);
  Future<List<Pokemon>> Function() loader;
  int calls = 0;
  bool disposed = false;
  @override
  Future<List<Pokemon>> fetchPokemon() {
    calls++;
    return loader();
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

// Override the actual dependency, not the UI: widget tests exercise the real
// controller, immutable state, and shared Riverpod subscription graph.
ProviderContainer testContainer(FakePokemonService service) =>
    ProviderContainer(
      overrides: [
        pokemonServiceProvider.overrideWith((ref) {
          ref.onDispose(service.dispose);
          return service;
        }),
      ],
    );
