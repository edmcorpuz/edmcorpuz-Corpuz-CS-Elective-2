import 'package:flutter/foundation.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';

enum PokedexState { initial, loading, success, empty, error }

/// Owns the data, request status, error, and selected Pokémon for every page.
class PokedexProvider extends ChangeNotifier {
  PokedexProvider({PokemonService? service})
    : _service = service ?? PokemonService();

  final PokemonService _service;
  List<Pokemon> _pokemon = const [];
  PokedexState _state = PokedexState.initial;
  String? _errorMessage;
  int? _selectedId;
  Future<void>? _inFlight;
  bool _disposed = false;

  List<Pokemon> get pokemon => _pokemon;
  PokedexState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == PokedexState.loading;

  Pokemon? get selectedPokemon {
    for (final item in _pokemon) {
      if (item.id == _selectedId) return item;
    }
    return null;
  }

  /// UI actions invoke this Provider method; HTTP details stay in the service.
  /// Concurrent refresh gestures share the same request.
  Future<void> fetchPokemon() {
    if (_disposed) return Future.value();
    return _inFlight ??= _loadPokemon().whenComplete(() => _inFlight = null);
  }

  Future<void> _loadPokemon() async {
    _state = PokedexState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.fetchPokemon();
      if (_disposed) return;
      _pokemon = List.unmodifiable(result);
      _state = _pokemon.isEmpty ? PokedexState.empty : PokedexState.success;
      if (selectedPokemon == null) _selectedId = null;
    } catch (error) {
      if (_disposed) return;
      _pokemon = const [];
      _selectedId = null;
      _errorMessage = error is PokemonApiException
          ? error.message
          : 'Something went wrong. Please try again.';
      _state = PokedexState.error;
    }
    notifyListeners();
  }

  void selectPokemon(int id) {
    if (_disposed || !_pokemon.any((item) => item.id == id)) return;
    _selectedId = id;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _service.dispose();
    super.dispose();
  }
}
