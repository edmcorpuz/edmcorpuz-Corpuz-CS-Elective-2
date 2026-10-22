import '../models/pokemon.dart';

enum LoadStatus { initial, loading, success, error }

/// One immutable snapshot of shared application state.
class PokedexState {
  PokedexState({
    List<Pokemon> pokemon = const [],
    Set<int> favoriteIds = const {},
    Map<int, String> nicknames = const {},
    this.status = LoadStatus.initial,
    Set<String> selectedTypes = const {},
    this.errorMessage,
    this.favoritesExpanded = false,
  }) : pokemon = List.unmodifiable(pokemon),
       favoriteIds = Set.unmodifiable(favoriteIds),
       selectedTypes = Set.unmodifiable(selectedTypes),
       nicknames = Map.unmodifiable(nicknames);

  final List<Pokemon> pokemon;
  final Set<int> favoriteIds;
  final Map<int, String> nicknames;
  final LoadStatus status;
  final Set<String> selectedTypes;
  final String? errorMessage;
  final bool favoritesExpanded;

  bool get isLoading => status == LoadStatus.loading;
  List<String> get availableTypes =>
      (pokemon.expand((item) => item.types).toSet().toList()..sort());
  List<Pokemon> get filteredPokemon => List.unmodifiable(
    pokemon.where(
      // AND matching: Grass + Poison requires BOTH types. Empty means all.
      (item) => selectedTypes.every(item.types.contains),
    ),
  );
  // Favorites deliberately ignore the home-page type filter.
  List<Pokemon> get favorites =>
      List.unmodifiable(pokemon.where((item) => favoriteIds.contains(item.id)));
  Pokemon? pokemonById(int id) {
    for (final item in pokemon) {
      if (item.id == id) return item;
    }
    return null;
  }

  PokedexState copyWith({
    List<Pokemon>? pokemon,
    Set<int>? favoriteIds,
    Map<int, String>? nicknames,
    LoadStatus? status,
    Set<String>? selectedTypes,
    String? errorMessage,
    bool clearError = false,
    bool? favoritesExpanded,
  }) => PokedexState(
    pokemon: pokemon ?? this.pokemon,
    favoriteIds: favoriteIds ?? this.favoriteIds,
    nicknames: nicknames ?? this.nicknames,
    status: status ?? this.status,
    selectedTypes: selectedTypes ?? this.selectedTypes,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    favoritesExpanded: favoritesExpanded ?? this.favoritesExpanded,
  );
}
