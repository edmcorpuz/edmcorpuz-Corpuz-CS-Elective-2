import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unang_flutter_project/providers/pokedex_provider.dart';
import 'package:unang_flutter_project/services/pokemon_service.dart';

const result =
    '{"results":[{"name":"bulbasaur","url":"https://pokeapi.co/api/v2/pokemon/1/"}]}';

void main() {
  PokedexProvider create(http.Client client) {
    final provider = PokedexProvider(service: PokemonService(client: client));
    addTearDown(provider.dispose);
    return provider;
  }

  test('notifies loading then success, stores immutable data', () async {
    final provider = create(
      MockClient((_) async => http.Response(result, 200)),
    );
    final states = <PokedexState>[];
    provider.addListener(() => states.add(provider.state));
    expect(provider.state, PokedexState.initial);
    await provider.fetchPokemon();
    expect(states, [PokedexState.loading, PokedexState.success]);
    expect(provider.pokemon.single.name, 'bulbasaur');
    expect(() => provider.pokemon.clear(), throwsUnsupportedError);
    expect(provider.errorMessage, isNull);
  });

  test('refresh shares pending requests and updates app state', () async {
    var calls = 0;
    final response = Completer<http.Response>();
    final provider = create(
      MockClient((_) {
        calls++;
        return calls == 1
            ? response.future
            : Future.value(http.Response('{"results":[]}', 200));
      }),
    );
    final first = provider.fetchPokemon();
    final duplicate = provider.fetchPokemon();
    expect(identical(first, duplicate), isTrue);
    expect(provider.isLoading, isTrue);
    response.complete(http.Response(result, 200));
    await first;
    expect(calls, 1);
    await provider.fetchPokemon();
    expect(calls, 2);
    expect(provider.state, PokedexState.empty);
    expect(provider.pokemon, isEmpty);
  });

  test('error is stored and cleared on retry', () async {
    var calls = 0;
    final provider = create(
      MockClient(
        (_) async =>
            ++calls == 1 ? http.Response('', 503) : http.Response(result, 200),
      ),
    );
    await provider.fetchPokemon();
    expect(provider.state, PokedexState.error);
    expect(provider.errorMessage, contains('503'));
    await provider.fetchPokemon();
    expect(provider.state, PokedexState.success);
    expect(provider.errorMessage, isNull);
  });

  test(
    'selection comes from app state and survives successful refresh',
    () async {
      final provider = create(
        MockClient((_) async => http.Response(result, 200)),
      );
      await provider.fetchPokemon();
      provider.selectPokemon(999);
      expect(provider.selectedPokemon, isNull);
      provider.selectPokemon(1);
      expect(provider.selectedPokemon, same(provider.pokemon.single));
      await provider.fetchPokemon();
      expect(provider.selectedPokemon, same(provider.pokemon.single));
    },
  );

  test('selection clears if refreshed results no longer contain it', () async {
    var calls = 0;
    final provider = create(
      MockClient(
        (_) async =>
            http.Response(++calls == 1 ? result : '{"results":[]}', 200),
      ),
    );
    await provider.fetchPokemon();
    provider.selectPokemon(1);
    await provider.fetchPokemon();
    expect(provider.selectedPokemon, isNull);
  });

  test('in-flight completion never notifies after disposal', () async {
    final response = Completer<http.Response>();
    final provider = PokedexProvider(
      service: PokemonService(client: MockClient((_) => response.future)),
    );
    var notifications = 0;
    provider.addListener(() => notifications++);
    final pending = provider.fetchPokemon();
    expect(notifications, 1);
    provider.dispose();
    response.complete(http.Response(result, 200));
    await pending;
    expect(notifications, 1);
    await provider.fetchPokemon();
    expect(notifications, 1);
  });
}
