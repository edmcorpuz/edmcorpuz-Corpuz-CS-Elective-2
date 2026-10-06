/// The three values displayed by the Pokédex.
class Pokemon {
  const Pokemon({required this.id, required this.name, required this.imageUrl});

  final int id;
  final String name;
  final String imageUrl;

  String get displayName => name
      .split('-')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');

  String get displayId => '#${id.toString().padLeft(3, '0')}';

  factory Pokemon.fromListJson(Map<String, dynamic> json) {
    final name = json['name'];
    final url = json['url'];
    if (name is! String || name.isEmpty || url is! String) {
      throw const FormatException('Invalid Pokémon data.');
    }
    final match = RegExp(r'/pokemon/(\d+)/?$').firstMatch(Uri.parse(url).path);
    final id = match == null ? null : int.tryParse(match.group(1)!);
    if (id == null || id <= 0) {
      throw const FormatException('Invalid Pokémon ID.');
    }
    return Pokemon(
      id: id,
      name: name,
      imageUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/'
          'sprites/pokemon/other/official-artwork/$id.png',
    );
  }
}
