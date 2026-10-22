import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unang_flutter_project/models/pokemon.dart';
import 'package:unang_flutter_project/services/pokemon_service.dart';

Map<String, dynamic> detail(int id, {List<String> types = const ['fire']}) => {
  'id': id,
  'name': 'pokemon-$id',
  'height': 7,
  'weight': 69,
  'types': [
    for (var i = 0; i < types.length; i++)
      {
        'slot': i + 1,
        'type': {'name': types[i]},
      },
  ],
  'stats': [
    {
      'base_stat': 45,
      'stat': {'name': 'hp'},
    },
  ],
};
Map<String, dynamic> list(int count) => {
  'results': List.generate(
    count,
    (i) => {
      'name': 'pokemon-${i + 1}',
      'url': 'https://pokeapi.co/api/v2/pokemon/${i + 1}/',
    },
  ),
};

void main() {
  PokemonService service(
    Future<http.Response> Function(http.Request) handler, {
    Duration? timeout,
  }) {
    final value = PokemonService(
      client: MockClient(handler),
      timeout: timeout ?? const Duration(seconds: 15),
    );
    addTearDown(value.dispose);
    return value;
  }

  test(
    'preserves existing endpoint and caps list at 30, with real detail types',
    () async {
      final urls = <Uri>[];
      final api = service((request) async {
        urls.add(request.url);
        if (request.url == PokemonService.endpoint) {
          return http.Response(jsonEncode(list(35)), 200);
        }
        return http.Response(
          jsonEncode(
            detail(
              int.parse(request.url.pathSegments.last),
              types: ['water', 'flying'],
            ),
          ),
          200,
        );
      });
      final result = await api.fetchPokemon();
      expect(result.length, 30);
      expect(urls.length, 31);
      expect(
        urls.first.toString(),
        'https://pokeapi.co/api/v2/pokemon?limit=30&offset=0',
      );
      expect(result.first.types, [
        'water',
        'flying',
      ]); // Not inferred from ID 1.
      expect(result.last.id, 30);
      expect(result.first.heightMetres, 0.7);
      expect(result.first.weightKilograms, 6.9);
      expect(result.first.stats['hp'], 45);
      expect(result.first.imageUrl, contains('official-artwork/1.png'));
      expect(() => result.clear(), throwsUnsupportedError);
      expect(() => result.first.types.clear(), throwsUnsupportedError);
    },
  );

  test(
    'detail request concurrency never exceeds six and order stays stable',
    () async {
      var active = 0, maximum = 0;
      final api = service((request) async {
        if (request.url == PokemonService.endpoint) {
          return http.Response(jsonEncode(list(14)), 200);
        }
        active++;
        if (active > maximum) maximum = active;
        final id = int.parse(request.url.pathSegments.last);
        await Future<void>.delayed(Duration(milliseconds: 15 - id));
        active--;
        return http.Response(jsonEncode(detail(id)), 200);
      });
      final result = await api.fetchPokemon();
      expect(maximum, 6);
      expect(result.map((p) => p.id), List.generate(14, (i) => i + 1));
    },
  );

  test('empty list returns empty and sends no detail requests', () async {
    var calls = 0;
    final api = service((_) async {
      calls++;
      return http.Response('{"results":[]}', 200);
    });
    expect(await api.fetchPokemon(), isEmpty);
    expect(calls, 1);
  });

  test('HTTP errors are readable', () async {
    final api = service((_) async => http.Response('Unavailable', 503));
    await expectLater(
      api.fetchPokemon(),
      throwsA(
        isA<PokemonApiException>().having(
          (e) => e.message,
          'message',
          contains('503'),
        ),
      ),
    );
  });

  test('detail HTTP errors fail the list rather than invent types', () async {
    final api = service(
      (r) async => r.url == PokemonService.endpoint
          ? http.Response(jsonEncode(list(1)), 200)
          : http.Response('Not found', 404),
    );
    await expectLater(
      api.fetchPokemon(),
      throwsA(
        isA<PokemonApiException>().having(
          (e) => e.message,
          'message',
          contains('404'),
        ),
      ),
    );
  });

  test('network error has connection guidance', () async {
    final api = service(
      (_) async => throw http.ClientException('Connection refused'),
    );
    await expectLater(
      api.fetchPokemon(),
      throwsA(
        isA<PokemonApiException>().having(
          (e) => e.message,
          'message',
          contains('internet connection'),
        ),
      ),
    );
  });

  test('timeout has retry guidance', () async {
    final api = service((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return http.Response('{"results":[]}', 200);
    }, timeout: const Duration(milliseconds: 1));
    await expectLater(
      api.fetchPokemon(),
      throwsA(
        isA<PokemonApiException>().having(
          (e) => e.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });

  for (final body in [
    'not-json',
    '[]',
    '{}',
    '{"results":[null]}',
    '{"results":[{"name":"bad","url":"bad"}]}',
  ]) {
    test('malformed list rejected: $body', () async {
      final api = service((_) async => http.Response(body, 200));
      await expectLater(
        api.fetchPokemon(),
        throwsA(isA<PokemonApiException>()),
      );
    });
  }

  test(
    'missing types, mismatched IDs, and malformed stats are rejected',
    () async {
      for (final broken in [
        {...detail(1), 'types': []},
        {
          ...detail(1),
          'types': [
            {'type': {}},
          ],
        },
        detail(2),
        {
          ...detail(1),
          'stats': [
            {
              'base_stat': 'bad',
              'stat': {'name': 'hp'},
            },
          ],
        },
        {...detail(1), 'height': -1},
      ]) {
        final api = service(
          (r) async => http.Response(
            jsonEncode(r.url == PokemonService.endpoint ? list(1) : broken),
            200,
          ),
        );
        await expectLater(
          api.fetchPokemon(),
          throwsA(isA<PokemonApiException>()),
        );
      }
    },
  );

  test('duplicate IDs are rejected', () async {
    final entries = list(1)['results'] as List;
    final api = service(
      (_) async => http.Response(
        jsonEncode({
          'results': [...entries, ...entries],
        }),
        200,
      ),
    );
    await expectLater(api.fetchPokemon(), throwsA(isA<PokemonApiException>()));
  });

  test('model preserves formatting and validates list IDs', () {
    final pokemon = Pokemon.fromListJson({
      'name': 'mr-mime',
      'url': 'https://pokeapi.co/api/v2/pokemon/122/',
    });
    expect(pokemon.displayName, 'Mr Mime');
    expect(pokemon.displayId, '#122');
    expect(
      () => Pokemon.fromListJson({'name': 'invalid', 'url': '/pokemon/0/'}),
      throwsFormatException,
    );
    expect(
      () => Pokemon.fromListJson({'name': '', 'url': '/pokemon/1/'}),
      throwsFormatException,
    );
  });
}
