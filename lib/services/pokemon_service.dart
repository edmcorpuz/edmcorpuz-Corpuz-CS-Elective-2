import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

class PokemonApiException implements Exception {
  const PokemonApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PokemonService {
  PokemonService({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  static const limit = 30;
  static const batchSize = 6;
  static final endpoint = Uri.https('pokeapi.co', '/api/v2/pokemon', {
    'limit': '$limit',
    'offset': '0',
  });
  final http.Client _client;
  final Duration timeout;

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client.get(uri).timeout(timeout);
    if (response.statusCode != 200) {
      throw PokemonApiException(
        'PokéAPI returned HTTP ${response.statusCode}. Please try again.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object.');
    }
    return decoded;
  }

  /// One list request plus at most 30 detail requests, six at a time.
  /// The list endpoint does not contain types; details are necessary to filter
  /// by actual API data. Refresh intentionally reuses this same method.
  Future<List<Pokemon>> fetchPokemon() async {
    try {
      final decoded = await _getJson(endpoint);
      final raw = decoded['results'];
      if (raw is! List) throw const FormatException('Missing Pokémon results.');
      final summaries = raw.take(limit).map((entry) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Invalid Pokémon entry.');
        }
        return Pokemon.fromListJson(entry);
      }).toList();
      if (summaries.map((item) => item.id).toSet().length != summaries.length) {
        throw const FormatException('Duplicate Pokémon IDs.');
      }
      final result = <Pokemon>[];
      for (var offset = 0; offset < summaries.length; offset += batchSize) {
        final batch = summaries.skip(offset).take(batchSize);
        final details = await Future.wait(
          batch.map((summary) async {
            // Only call the known API host, not an arbitrary URL from JSON.
            final json = await _getJson(
              Uri.https('pokeapi.co', '/api/v2/pokemon/${summary.id}'),
            );
            final pokemon = Pokemon.fromDetailJson(json);
            if (pokemon.id != summary.id || pokemon.name != summary.name) {
              throw const FormatException(
                'Pokémon detail does not match list.',
              );
            }
            return pokemon;
          }),
        );
        result.addAll(details);
      }
      return List.unmodifiable(result);
    } on TimeoutException {
      throw const PokemonApiException(
        'The request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const PokemonApiException(
        'Unable to connect. Check your internet connection.',
      );
    } on FormatException {
      throw const PokemonApiException(
        'PokéAPI sent invalid data. Please try again.',
      );
    }
  }

  void dispose() => _client.close();
}
