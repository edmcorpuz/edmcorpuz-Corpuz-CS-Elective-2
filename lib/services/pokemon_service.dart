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
  PokemonService({http.Client? client}) : _client = client ?? http.Client();

  static const limit = 30;
  static final endpoint = Uri.https('pokeapi.co', '/api/v2/pokemon', {
    'limit': '$limit',
    'offset': '0',
  });
  final http.Client _client;

  /// A Future fits a one-time HTTP request returning one list, not live events.
  Future<List<Pokemon>> fetchPokemon() async {
    try {
      final response = await _client
          .get(endpoint)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw PokemonApiException(
          'PokéAPI returned HTTP ${response.statusCode}. Please try again.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['results'] is! List) {
        throw const FormatException('Missing Pokémon results.');
      }
      final results = decoded['results'] as List;
      return List.unmodifiable(
        results.take(limit).map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid Pokémon entry.');
          }
          return Pokemon.fromListJson(item);
        }),
      );
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
