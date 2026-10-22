/// Immutable API data. User nicknames and favorites belong to Riverpod state,
/// not to a second mutable copy of this model.
class Pokemon {
  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    List<String> types = const [],
    this.heightDecimetres = 0,
    this.weightHectograms = 0,
    Map<String, int> stats = const {},
  }) : types = List.unmodifiable(types),
       stats = Map.unmodifiable(stats);

  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final int heightDecimetres;
  final int weightHectograms;
  final Map<String, int> stats;

  String get displayName => name.split('-').map(titleCase).join(' ');
  String get displayId => '#${id.toString().padLeft(3, '0')}';
  double get heightMetres => heightDecimetres / 10;
  double get weightKilograms => weightHectograms / 10;

  static String titleCase(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  static String artworkUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/'
      'sprites/pokemon/other/official-artwork/$id.png';

  /// Preserves the original activity's list endpoint and ID parsing.
  factory Pokemon.fromListJson(Map<String, dynamic> json) {
    final name = json['name'];
    final url = json['url'];
    if (name is! String || name.isEmpty || url is! String) {
      throw const FormatException('Invalid Pokémon list entry.');
    }
    final match = RegExp(r'/pokemon/(\d+)/?$').firstMatch(Uri.parse(url).path);
    final id = match == null ? null : int.tryParse(match.group(1)!);
    if (id == null || id <= 0) {
      throw const FormatException('Invalid Pokémon ID.');
    }
    return Pokemon(id: id, name: name, imageUrl: artworkUrl(id));
  }

  /// Types come from the API's detail response, never from a hardcoded ID map.
  factory Pokemon.fromDetailJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final rawTypes = json['types'];
    final height = json['height'];
    final weight = json['weight'];
    if (id is! int ||
        id <= 0 ||
        name is! String ||
        name.isEmpty ||
        rawTypes is! List ||
        rawTypes.isEmpty ||
        height is! int ||
        height < 0 ||
        weight is! int ||
        weight < 0) {
      throw const FormatException('Invalid Pokémon details.');
    }
    final types = <String>[];
    for (final entry in rawTypes) {
      if (entry is! Map<String, dynamic> || entry['type'] is! Map) {
        throw const FormatException('Invalid Pokémon type.');
      }
      final type = entry['type']['name'];
      if (type is! String || type.isEmpty) {
        throw const FormatException('Missing Pokémon type name.');
      }
      if (!types.contains(type)) types.add(type);
    }
    final stats = <String, int>{};
    final rawStats = json['stats'];
    if (rawStats is! List) {
      throw const FormatException('Missing Pokémon stats.');
    }
    for (final entry in rawStats) {
      if (entry is! Map<String, dynamic> ||
          entry['stat'] is! Map ||
          entry['stat']['name'] is! String ||
          entry['base_stat'] is! int ||
          (entry['base_stat'] as int) < 0) {
        throw const FormatException('Invalid Pokémon stat.');
      }
      stats[entry['stat']['name'] as String] = entry['base_stat'] as int;
    }
    return Pokemon(
      id: id,
      name: name,
      imageUrl: artworkUrl(id),
      types: types,
      heightDecimetres: height,
      weightHectograms: weight,
      stats: stats,
    );
  }
}
