import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unang_flutter_project/models/pokemon.dart';
import 'package:unang_flutter_project/providers/pokedex_provider.dart';
import 'package:unang_flutter_project/providers/pokedex_state.dart';
import 'package:unang_flutter_project/services/pokemon_service.dart';

import 'test_support.dart';

void main() {
  late FakePokemonService service;
  late ProviderContainer container;
  setUp(() {
    service = FakePokemonService();
    container = testContainer(service);
  });
  tearDown(() => container.dispose());
  PokedexController controller() => container.read(pokedexProvider.notifier);
  PokedexState state() => container.read(pokedexProvider);
  Future<void> load() => controller().fetchPokemon();

  test(
    'startup calls existing fetch and transitions initial/loading/success',
    () async {
      final seen = <LoadStatus>[];
      final subscription = container.listen(
        pokedexProvider,
        (_, value) => seen.add(value.status),
        fireImmediately: true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(seen, [
        LoadStatus.initial,
        LoadStatus.loading,
        LoadStatus.success,
      ]);
      expect(service.calls, 1);
      expect(state().pokemon.length, 4);
      subscription.close();
    },
  );

  test('coalesces concurrent calls to the same fetch method', () async {
    final pending = Completer<List<Pokemon>>();
    service.loader = () => pending.future;
    final first = load();
    final second = load();
    expect(identical(first, second), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(service.calls, 1);
    pending.complete(samplePokemon);
    await first;
    await load();
    expect(service.calls, 2);
  });

  test(
    'favorites toggle both ways and reject IDs outside the dataset',
    () async {
      await load();
      controller().toggleFavorite(1);
      expect(state().favoriteIds, {1});
      expect(state().favorites.single.name, 'bulbasaur');
      controller().toggleFavorite(10000);
      expect(state().favoriteIds, {1});
      controller().toggleFavorite(1);
      expect(state().favorites, isEmpty);
    },
  );

  test(
    'nickname add/edit/remove trims input and retains original name',
    () async {
      await load();
      controller().saveNickname(1, '  Sprout  ');
      expect(state().nicknames[1], 'Sprout');
      controller().saveNickname(1, 'Leafy');
      expect(state().nicknames[1], 'Leafy');
      expect(state().pokemonById(1)!.name, 'bulbasaur');
      controller().removeNickname(1);
      expect(state().nicknames, isEmpty);
    },
  );

  test('rejects blank/overlong nicknames and unknown IDs', () async {
    await load();
    expect(() => controller().saveNickname(1, '   '), throwsArgumentError);
    expect(() => controller().saveNickname(1, 'x' * 31), throwsArgumentError);
    controller().saveNickname(9999, 'Missing');
    expect(state().nicknames, isEmpty);
  });

  test('filters by real types, supports secondary types, and clears', () async {
    await load();
    expect(state().availableTypes, [
      'electric',
      'fire',
      'grass',
      'poison',
      'water',
    ]);
    controller().toggleType('fire');
    expect(state().filteredPokemon.single.id, 4);
    controller().toggleType('fire');
    controller().toggleType('poison');
    expect(state().filteredPokemon.single.id, 1);
    controller().toggleType('imaginary');
    expect(state().selectedTypes, {'poison'});
    controller().clearTypes();
    expect(state().filteredPokemon.length, 4);
  });

  test(
    'AND matching excludes Pokémon that have only one selected type',
    () async {
      service.loader = () async => [
        ...samplePokemon,
        Pokemon(id: 152, name: 'chikorita', imageUrl: '', types: ['grass']),
        Pokemon(id: 23, name: 'ekans', imageUrl: '', types: ['poison']),
      ];
      await load();
      controller().toggleType('grass');
      expect(state().filteredPokemon.map((p) => p.id), [1, 152]);
      controller().toggleType('poison');
      expect(state().selectedTypes, {'grass', 'poison'});
      expect(state().filteredPokemon.map((p) => p.id), [1]);
      controller().toggleType('grass');
      expect(state().filteredPokemon.map((p) => p.id), [1, 23]);
      controller().toggleType('poison');
      expect(state().selectedTypes, isEmpty);
      expect(state().filteredPokemon.length, 6);
    },
  );

  test(
    'unmatched combinations and three selected types return no results',
    () async {
      await load();
      controller().toggleType('grass');
      controller().toggleType('fire');
      expect(state().filteredPokemon, isEmpty);
      controller().toggleType('poison');
      expect(state().selectedTypes.length, 3);
      expect(state().filteredPokemon, isEmpty);
      controller().clearTypes();
      expect(state().filteredPokemon.length, 4);
    },
  );

  test(
    'a selected type can be deselected after it disappears on refresh',
    () async {
      await load();
      controller().toggleType('fire');
      service.loader = () async => [samplePokemon.first];
      await load();
      expect(state().availableTypes, isNot(contains('fire')));
      expect(state().selectedTypes, {'fire'});
      controller().toggleType('fire');
      expect(state().selectedTypes, isEmpty);
      expect(state().filteredPokemon.single.id, 1);
    },
  );

  test('filtering never removes a favorite from the panel', () async {
    await load();
    controller().toggleFavorite(7);
    controller().toggleType('fire');
    expect(state().filteredPokemon.single.id, 4);
    expect(state().favorites.single.id, 7);
    controller().toggleFavoritesPanel();
    expect(state().favoritesExpanded, isTrue);
    controller().toggleFavoritesPanel();
    expect(state().favoritesExpanded, isFalse);
  });

  test(
    'refresh retains nickname/favorite/filter/panel and concurrent changes',
    () async {
      await load();
      controller().saveNickname(1, 'Sprout');
      controller().toggleFavorite(1);
      controller().toggleType('grass');
      controller().toggleType('poison');
      controller().toggleFavoritesPanel();
      final pending = Completer<List<Pokemon>>();
      service.loader = () => pending.future;
      final refresh = load();
      controller().saveNickname(1, 'Fresh Sprout');
      controller().toggleFavorite(7);
      pending.complete(samplePokemon);
      await refresh;
      expect(state().nicknames[1], 'Fresh Sprout');
      expect(state().favoriteIds, {1, 7});
      expect(state().selectedTypes, {'grass', 'poison'});
      expect(state().favoritesExpanded, isTrue);
    },
  );

  test('initial API error is meaningful and retry recovers', () async {
    service.loader = () async => throw const PokemonApiException('Offline.');
    await load();
    expect(state().status, LoadStatus.error);
    expect(state().errorMessage, 'Offline.');
    expect(state().pokemon, isEmpty);
    service.loader = () async => samplePokemon;
    await load();
    expect(state().status, LoadStatus.success);
    expect(state().errorMessage, isNull);
  });

  test(
    'refresh error preserves the last good collection and personalizations',
    () async {
      await load();
      controller().saveNickname(1, 'Sprout');
      controller().toggleFavorite(1);
      service.loader = () async =>
          throw const PokemonApiException('Try again.');
      await load();
      expect(state().status, LoadStatus.error);
      expect(state().pokemon.length, 4);
      expect(state().nicknames[1], 'Sprout');
      expect(state().favorites.single.id, 1);
    },
  );

  test('unknown errors do not expose raw exception details', () async {
    service.loader = () async =>
        throw StateError('Internal implementation details');
    await load();
    expect(state().errorMessage, 'Something went wrong. Please try again.');
  });

  test('empty API results and no filter matches are distinct', () async {
    await load();
    controller().toggleType('fire');
    service.loader = () async => [samplePokemon.first];
    await load();
    expect(state().pokemon, isNotEmpty);
    expect(state().filteredPokemon, isEmpty);
    controller().clearTypes();
    expect(state().filteredPokemon.length, 1);
    service.loader = () async => [];
    await load();
    expect(state().status, LoadStatus.success);
    expect(state().pokemon, isEmpty);
  });

  test(
    'state is immutable and removed records do not become ghost favorites',
    () async {
      await load();
      controller().toggleFavorite(1);
      expect(() => state().pokemon.clear(), throwsUnsupportedError);
      expect(() => state().favoriteIds.add(7), throwsUnsupportedError);
      expect(() => state().selectedTypes.add('fire'), throwsUnsupportedError);
      expect(() => state().nicknames[1] = 'Mutated', throwsUnsupportedError);
      service.loader = () async => [samplePokemon[1]];
      await load();
      expect(state().favorites, isEmpty);
      expect(state().pokemonById(1), isNull);
    },
  );

  test('disposal closes service and safely ignores a late result', () async {
    final pending = Completer<List<Pokemon>>();
    service.loader = () => pending.future;
    final request = load();
    container.dispose();
    expect(service.disposed, isTrue);
    pending.complete(samplePokemon);
    await expectLater(request, completes);
  });

  test(
    'a fresh app scope starts without session-only personalizations',
    () async {
      await load();
      controller().saveNickname(1, 'Sprout');
      controller().toggleFavorite(1);
      final other = testContainer(FakePokemonService());
      await other.read(pokedexProvider.notifier).fetchPokemon();
      expect(other.read(pokedexProvider).nicknames, isEmpty);
      expect(other.read(pokedexProvider).favoriteIds, isEmpty);
      other.dispose();
    },
  );
}
