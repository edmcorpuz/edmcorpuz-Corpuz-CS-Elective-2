import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unang_flutter_project/screens/pokedex_screen.dart';
import 'package:unang_flutter_project/services/pokemon_service.dart';
import 'package:unang_flutter_project/widgets/pokemon_card.dart';

void main() {
  Future<void> open(WidgetTester tester, PokemonService service) async {
    addTearDown(service.dispose);
    await tester.pumpWidget(MaterialApp(home: PokedexScreen(service: service)));
  }

  testWidgets('shows loading while a request is pending, then empty', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    await open(
      tester,
      PokemonService(client: MockClient((_) => response.future)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(http.Response('{"results":[]}', 200));
    await tester.pumpAndSettle();
    expect(find.text('No Pokémon found'), findsOneWidget);
  });

  testWidgets('shows an error and retry sends another request', (tester) async {
    var calls = 0;
    await open(
      tester,
      PokemonService(
        client: MockClient((_) async {
          calls++;
          return calls == 1
              ? http.Response('', 503)
              : http.Response('{"results":[]}', 200);
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load Pokémon'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('No Pokémon found'), findsOneWidget);
  });

  testWidgets('shows a scrollable grid with name, ID, and no detail action', (
    tester,
  ) async {
    await open(
      tester,
      PokemonService(
        client: MockClient(
          (_) async => http.Response(
            '{"results":[{"name":"bulbasaur","url":"https://pokeapi.co/api/v2/pokemon/1/"}]}',
            200,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('#001'), findsOneWidget);
    expect(tester.widget<PokemonCard>(find.byType(PokemonCard)).onTap, isNull);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
