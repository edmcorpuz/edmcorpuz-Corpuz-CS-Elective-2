import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:unang_flutter_project/providers/pokedex_provider.dart';
import 'package:unang_flutter_project/screens/pokedex_screen.dart';
import 'package:unang_flutter_project/screens/pokemon_detail_screen.dart';
import 'package:unang_flutter_project/services/pokemon_service.dart';

const result =
    '{"results":[{"name":"bulbasaur","url":"https://pokeapi.co/api/v2/pokemon/1/"}]}';

void main() {
  Future<void> open(WidgetTester tester, http.Client client) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) =>
            PokedexProvider(service: PokemonService(client: client))
              ..fetchPokemon(),
        child: const MaterialApp(home: PokedexScreen()),
      ),
    );
  }

  testWidgets('shows loading, disables refresh, then shows empty state', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    await open(tester, MockClient((_) => response.future));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
    response.complete(http.Response('{"results":[]}', 200));
    await tester.pumpAndSettle();
    expect(find.text('No Pokémon found'), findsOneWidget);
  });

  testWidgets('error and retry are driven by Provider', (tester) async {
    var calls = 0;
    await open(
      tester,
      MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response('', 503)
            : http.Response('{"results":[]}', 200);
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load Pokémon'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('No Pokémon found'), findsOneWidget);
  });

  testWidgets(
    'refresh button re-fetches and card opens Provider-backed detail',
    (tester) async {
      var calls = 0;
      await open(
        tester,
        MockClient((_) async {
          calls++;
          return http.Response(result, 200);
        }),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Bulbasaur'), findsOneWidget);
      expect(find.text('#001'), findsOneWidget);
      await tester.tap(find.byTooltip('Refresh Pokémon'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      await tester.tap(find.text('Bulbasaur'));
      await tester.pumpAndSettle();
      expect(find.byType(PokemonDetailScreen), findsOneWidget);
      expect(find.text('Bulbasaur'), findsOneWidget);
      expect(find.text('#001'), findsOneWidget);
      final context = tester.element(find.byType(PokemonDetailScreen));
      expect(context.read<PokedexProvider>().selectedPokemon?.id, 1);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pull-to-refresh triggers the Provider request', (tester) async {
    var calls = 0;
    await open(
      tester,
      MockClient((_) async {
        calls++;
        return http.Response(result, 200);
      }),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(GridView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('grid scrolls to Pokémon 30 at phone width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(
      tester,
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'results': List.generate(
              30,
              (i) => {
                'name': 'pokemon-${i + 1}',
                'url': 'https://pokeapi.co/api/v2/pokemon/${i + 1}/',
              },
            ),
          }),
          200,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('#030'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('#030'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail page handles absent selection', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PokedexProvider(
          service: PokemonService(
            client: MockClient(
              (_) async => http.Response('{"results":[]}', 200),
            ),
          ),
        ),
        child: const MaterialApp(home: PokemonDetailScreen()),
      ),
    );
    expect(find.text('No Pokémon selected'), findsOneWidget);
  });
}
