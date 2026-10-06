import 'package:flutter/material.dart';

import '../models/pokemon.dart';

class PokemonImage extends StatelessWidget {
  const PokemonImage({super.key, required this.pokemon});
  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      pokemon.imageUrl,
      fit: BoxFit.contain,
      semanticLabel: pokemon.displayName,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Colors.blueGrey,
        ),
      ),
    );
  }
}
