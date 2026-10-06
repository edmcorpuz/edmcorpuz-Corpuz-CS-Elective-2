import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unang_flutter_project/models/pokemon.dart';
import 'package:unang_flutter_project/services/pokemon_service.dart';

void main() {
  test('model parses API ID, name and artwork', () {
    final pokemon = Pokemon.fromListJson({
      'name': 'mr-mime',
      'url': 'https://pokeapi.co/api/v2/pokemon/122/',
    });
    expect(pokemon.id, 122);
    expect(pokemon.displayId, '#122');
    expect(pokemon.displayName, 'Mr Mime');
    expect(pokemon.imageUrl, endsWith('/122.png'));
  });

  test('model rejects malformed or non-positive IDs', () {
    for (final url in ['invalid', 'https://pokeapi.co/api/v2/pokemon/0/']) {
      expect(
        () => Pokemon.fromListJson({'name': 'bulbasaur', 'url': url}),
        throwsFormatException,
      );
    }
  });

  test('request uses limit 30 and enforces it on results', () async {
    final service = PokemonService(
      client: MockClient((request) async {
        expect(request.url.host, 'pokeapi.co');
        expect(request.url.queryParameters, {'limit': '30', 'offset': '0'});
        return http.Response(
          jsonEncode({
            'results': List.generate(
              35,
              (i) => {
                'name': 'pokemon-${i + 1}',
                'url': 'https://pokeapi.co/api/v2/pokemon/${i + 1}/',
              },
            ),
          }),
          200,
        );
      }),
    );
    addTearDown(service.dispose);
    final pokemon = await service.fetchPokemon();
    expect(pokemon, hasLength(30));
    expect(pokemon.last.id, 30);
    expect(() => pokemon.clear(), throwsUnsupportedError);
  });

  test('empty API results remain empty', () async {
    final service = PokemonService(
      client: MockClient((_) async => http.Response('{"results":[]}', 200)),
    );
    addTearDown(service.dispose);
    expect(await service.fetchPokemon(), isEmpty);
  });

  test('non-200 responses become readable errors', () async {
    final service = PokemonService(
      client: MockClient((_) async => http.Response('', 503)),
    );
    addTearDown(service.dispose);
    await expectLater(
      service.fetchPokemon(),
      throwsA(
        isA<PokemonApiException>().having(
          (e) => e.message,
          'message',
          contains('503'),
        ),
      ),
    );
  });

  for (final body in [
    'not-json',
    '{}',
    '{"results":[42]}',
    '{"results":[{"name":"a","url":"bad"}]}',
  ]) {
    test('rejects malformed response: $body', () async {
      final service = PokemonService(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.fetchPokemon(),
        throwsA(isA<PokemonApiException>()),
      );
    });
  }

  test('network failures become readable errors', () async {
    final service = PokemonService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    addTearDown(service.dispose);
    await expectLater(
      service.fetchPokemon(),
      throwsA(
        isA<PokemonApiException>().having(
          (e) => e.message,
          'message',
          contains('internet'),
        ),
      ),
    );
  });

  test('timeouts become readable errors', () async {
    final service = PokemonService(
      client: MockClient((_) async => throw TimeoutException('timeout')),
    );
    addTearDown(service.dispose);
    await expectLater(
      service.fetchPokemon(),
      throwsA(
        isA<PokemonApiException>().having(
          (e) => e.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });
}
