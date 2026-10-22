import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/pokemon_service.dart';
import 'pokedex_state.dart';

final pokemonServiceProvider = Provider<PokemonService>((ref) {
  final service = PokemonService();
  ref.onDispose(service.dispose);
  return service;
});

// Kept alive for the app's ProviderScope: routes share the same favorites,
// nicknames, filter, and panel state. No legacy Provider or BLoC is used.
final pokedexProvider = NotifierProvider<PokedexController, PokedexState>(
  PokedexController.new,
);

class PokedexController extends Notifier<PokedexState> {
  Future<void>? _inFlight;

  @override
  PokedexState build() {
    // Defer the initial write until after the first widget build.
    Future.microtask(() {
      if (ref.mounted) unawaited(fetchPokemon());
    });
    return PokedexState();
  }

  /// Startup, toolbar refresh, pull-to-refresh, and retry ALL recall this
  /// existing action. Concurrent callers share a single in-flight Future.
  Future<void> fetchPokemon() {
    if (!ref.mounted) return Future.value();
    return _inFlight ??= _loadPokemon().whenComplete(() => _inFlight = null);
  }

  Future<void> _loadPokemon() async {
    state = state.copyWith(status: LoadStatus.loading, clearError: true);
    try {
      final result = await ref.read(pokemonServiceProvider).fetchPokemon();
      if (!ref.mounted) return;
      // Use the CURRENT state so edits made during a fetch are not overwritten.
      state = state.copyWith(
        pokemon: result,
        status: LoadStatus.success,
        clearError: true,
      );
    } catch (error) {
      if (!ref.mounted) return;
      // Keep the last successful list and all personalizations on refresh error.
      state = state.copyWith(
        status: LoadStatus.error,
        errorMessage: error is PokemonApiException
            ? error.message
            : 'Something went wrong. Please try again.',
      );
    }
  }

  void toggleFavorite(int id) {
    if (state.pokemonById(id) == null) return;
    final ids = {...state.favoriteIds};
    if (!ids.add(id)) ids.remove(id);
    state = state.copyWith(favoriteIds: ids);
  }

  void saveNickname(int id, String value) {
    if (state.pokemonById(id) == null) return;
    final name = value.trim();
    if (name.isEmpty || name.length > 30) {
      throw ArgumentError('Enter a nickname with 1–30 characters.');
    }
    state = state.copyWith(nicknames: {...state.nicknames, id: name});
  }

  void removeNickname(int id) {
    final names = {...state.nicknames}..remove(id);
    state = state.copyWith(nicknames: names);
  }

  void toggleType(String type) {
    final types = {...state.selectedTypes};
    // A selected type can still be removed if a refresh drops it from the API.
    if (!types.remove(type)) {
      if (!state.availableTypes.contains(type)) return;
      types.add(type);
    }
    state = state.copyWith(selectedTypes: types);
  }

  void clearTypes() {
    state = state.copyWith(selectedTypes: {});
  }

  void toggleFavoritesPanel() {
    state = state.copyWith(favoritesExpanded: !state.favoritesExpanded);
  }
}
