import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unang_flutter_project/main.dart';
import 'package:unang_flutter_project/models/pokemon.dart';
import 'package:unang_flutter_project/providers/pokedex_provider.dart';
import 'package:unang_flutter_project/screens/pokemon_detail_screen.dart';
import 'package:unang_flutter_project/services/pokemon_service.dart';
import 'package:unang_flutter_project/widgets/pokemon_card.dart';

import 'test_support.dart';

void main() {
  Future<ProviderContainer> mount(
    WidgetTester tester,
    FakePokemonService service, {
    bool settle = true,
    Size size = const Size(1000, 1100),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = testContainer(service);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PokedexApp(),
      ),
    );
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
    return container;
  }

  Finder card(int id) => find.byKey(ValueKey('open-pokemon-$id'));
  Finder heart(int id) => find.descendant(
    of: card(id),
    matching: find.byKey(ValueKey('favorite-$id')),
  );
  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows initial loading then images, original names, and real type chips',
    (tester) async {
      final pending = Completer<List<Pokemon>>();
      await mount(
        tester,
        FakePokemonService(loader: () => pending.future),
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Finding your next favorite…'), findsOneWidget);
      pending.complete(samplePokemon);
      await tester.pumpAndSettle();
      expect(find.byType(PokemonCard), findsNWidgets(4));
      expect(find.text('Bulbasaur'), findsOneWidget);
      expect(find.text('4 of 4 Pokémon'), findsOneWidget);
      expect(find.byKey(const ValueKey('type-poison')), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('initial API error has a working retry action', (tester) async {
    final service = FakePokemonService(
      loader: () async => throw const PokemonApiException('No connection.'),
    );
    await mount(tester, service);
    expect(find.text('Could not load Pokémon'), findsOneWidget);
    expect(find.text('No connection.'), findsOneWidget);
    service.loader = () async => samplePokemon;
    await tap(tester, find.text('Try again'));
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(service.calls, 2);
  });

  testWidgets('empty API response is not confused with an error', (
    tester,
  ) async {
    await mount(tester, FakePokemonService(loader: () async => []));
    expect(find.text('No Pokémon found'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'heart toggles immediately and favorites panel expands/collapses',
    (tester) async {
      final container = await mount(tester, FakePokemonService());
      await tap(tester, find.byKey(const ValueKey('toggle-favorites')));
      expect(
        find.text('No favorites yet. Tap a heart to keep a Pokémon close.'),
        findsOneWidget,
      );
      await tap(tester, heart(1));
      expect(container.read(pokedexProvider).favoriteIds, {1});
      expect(find.text('Favorites (1)'), findsOneWidget);
      expect(find.byKey(const ValueKey('favorite-entry-1')), findsOneWidget);
      final button = tester.widget<IconButton>(heart(1));
      expect(button.isSelected, isTrue);
      await tap(tester, find.byKey(const ValueKey('toggle-favorites')));
      expect(find.byKey(const ValueKey('favorites-panel')), findsNothing);
      await tap(tester, heart(1));
      expect(find.text('Favorites (0)'), findsOneWidget);
    },
  );

  testWidgets(
    'nickname can be added, edited, cancelled and removed everywhere',
    (tester) async {
      final container = await mount(tester, FakePokemonService());
      final editor = find.byKey(const ValueKey('edit-nickname-1'));
      await tap(tester, editor);
      await tester.enterText(
        find.byKey(const ValueKey('nickname-input')),
        '   ',
      );
      await tap(tester, find.text('Save nickname'));
      expect(
        find.text('Enter a nickname, or choose Remove nickname.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('nickname-input')),
        '  Sprout  ',
      );
      await tap(tester, find.text('Save nickname'));
      expect(find.text('Sprout'), findsOneWidget);
      expect(find.text('Bulbasaur'), findsOneWidget);
      await tap(tester, editor);
      await tester.enterText(
        find.byKey(const ValueKey('nickname-input')),
        'Leafy',
      );
      await tap(tester, find.text('Save nickname'));
      expect(container.read(pokedexProvider).nicknames[1], 'Leafy');
      await tap(tester, editor);
      await tester.enterText(
        find.byKey(const ValueKey('nickname-input')),
        'Not saved',
      );
      await tap(tester, find.text('Cancel'));
      expect(container.read(pokedexProvider).nicknames[1], 'Leafy');
      await tap(tester, heart(1));
      await tap(tester, find.byKey(const ValueKey('toggle-favorites')));
      expect(find.text('Leafy'), findsNWidgets(2));
      await tap(tester, find.byKey(const ValueKey('favorite-entry-1')));
      expect(find.byType(PokemonDetailScreen), findsOneWidget);
      expect(find.text('Leafy'), findsNWidgets(2));
      await tap(tester, find.byKey(const ValueKey('detail-nickname-1')));
      await tap(tester, find.text('Remove nickname'));
      expect(container.read(pokedexProvider).nicknames, isEmpty);
      expect(find.text('Leafy'), findsNothing);
      expect(find.text('Bulbasaur'), findsNWidgets(2));
      await tap(tester, find.byTooltip('Back'));
      expect(find.byType(PokemonDetailScreen), findsNothing);
      expect(find.text('Leafy'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'type filter matches actual types, clears, and does not filter favorites',
    (tester) async {
      final container = await mount(tester, FakePokemonService());
      container.read(pokedexProvider.notifier).toggleFavorite(7);
      await tap(tester, find.byKey(const ValueKey('toggle-favorites')));
      await tap(tester, find.byKey(const ValueKey('type-fire')));
      expect(find.byType(PokemonCard), findsOneWidget);
      expect(find.text('Charmander'), findsOneWidget);
      expect(card(1), findsNothing);
      expect(find.byKey(const ValueKey('favorite-entry-7')), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('type-poison')));
      expect(card(1), findsOneWidget);
      expect(card(4), findsNothing);
      await tap(tester, find.byKey(const ValueKey('type-all')));
      expect(find.byType(PokemonCard), findsNWidgets(4));
    },
  );

  testWidgets(
    'toolbar and pull-to-refresh recall fetch and preserve user state',
    (tester) async {
      final service = FakePokemonService();
      final container = await mount(tester, service);
      container.read(pokedexProvider.notifier).saveNickname(1, 'Sprout');
      container.read(pokedexProvider.notifier).toggleFavorite(1);
      await tap(tester, find.byKey(const ValueKey('refresh-pokemon')));
      expect(service.calls, 2);
      expect(container.read(pokedexProvider).nicknames[1], 'Sprout');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(service.calls, 3);
      expect(container.read(pokedexProvider).favoriteIds, {1});
    },
  );

  testWidgets('refresh failure leaves cards and favorites usable', (
    tester,
  ) async {
    final service = FakePokemonService();
    await mount(tester, service);
    await tap(tester, heart(1));
    service.loader = () async => throw const PokemonApiException('Offline.');
    await tap(tester, find.byKey(const ValueKey('refresh-pokemon')));
    expect(
      find.text('Could not refresh. Your collection is still here.'),
      findsOneWidget,
    );
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Favorites (1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty filter can clear after the loaded collection changes', (
    tester,
  ) async {
    final service = FakePokemonService();
    final container = await mount(tester, service);
    container.read(pokedexProvider.notifier).selectType('fire');
    service.loader = () async => [samplePokemon.first];
    await container.read(pokedexProvider.notifier).fetchPokemon();
    await tester.pumpAndSettle();
    expect(find.text('No Pokémon match this type'), findsOneWidget);
    await tap(tester, find.text('Clear type filter'));
    expect(find.text('Bulbasaur'), findsOneWidget);
  });

  testWidgets(
    'favorites available on details, remove immediately, back keeps route IDs',
    (tester) async {
      final container = await mount(tester, FakePokemonService());
      final controller = container.read(pokedexProvider.notifier);
      controller.toggleFavorite(1);
      controller.toggleFavorite(4);
      await tester.pumpAndSettle();
      await tap(tester, card(1));
      await tap(tester, find.byKey(const ValueKey('toggle-favorites')));
      await tap(tester, find.byKey(const ValueKey('favorite-entry-4')));
      expect(
        tester
            .widget<PokemonDetailScreen>(find.byType(PokemonDetailScreen))
            .pokemonId,
        4,
      );
      await tap(tester, find.byTooltip('Back'));
      expect(
        tester
            .widget<PokemonDetailScreen>(find.byType(PokemonDetailScreen))
            .pokemonId,
        1,
      );
      final panel = find.byKey(const ValueKey('favorites-panel'));
      await tap(
        tester,
        find.descendant(
          of: panel,
          matching: find.byKey(const ValueKey('favorite-4')),
        ),
      );
      expect(find.byKey(const ValueKey('favorite-entry-4')), findsNothing);
      expect(container.read(pokedexProvider).favoriteIds, {1});
    },
  );

  for (final size in [
    const Size(360, 800),
    const Size(640, 360),
    const Size(1280, 900),
  ]) {
    testWidgets(
      'responsive layout and scrolling at ${size.width}x${size.height}',
      (tester) async {
        final container = await mount(tester, FakePokemonService(), size: size);
        container.read(pokedexProvider.notifier).toggleFavorite(1);
        await tap(tester, find.byKey(const ValueKey('toggle-favorites')));
        await tap(tester, find.byKey(const ValueKey('favorite-entry-1')));
        await tester.drag(
          find.byType(SingleChildScrollView).last,
          const Offset(0, -600),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(PokemonDetailScreen), findsOneWidget);
      },
    );
  }

  testWidgets('200 percent text scale has no layout overflow on a phone', (
    tester,
  ) async {
    final container = await mount(
      tester,
      FakePokemonService(),
      size: const Size(360, 800),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: const PokedexApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
