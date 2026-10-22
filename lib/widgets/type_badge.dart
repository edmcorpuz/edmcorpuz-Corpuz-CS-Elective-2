import 'package:flutter/material.dart';

import '../models/pokemon.dart';

// These are presentation colors, NOT a Pokémon-to-type mapping.
Color typeColor(String type) => switch (type) {
  'grass' || 'bug' => const Color(0xFFDCEBD0),
  'fire' => const Color(0xFFFFE0D0),
  'water' || 'ice' => const Color(0xFFD6EAF6),
  'electric' => const Color(0xFFFFEDB2),
  'poison' || 'ghost' => const Color(0xFFE8DDF1),
  'ground' || 'rock' => const Color(0xFFEBDCC7),
  'flying' || 'dragon' => const Color(0xFFE1E5F5),
  'fairy' || 'psychic' => const Color(0xFFF5DFEB),
  _ => const Color(0xFFE8EAE3),
};

class TypeBadge extends StatelessWidget {
  const TypeBadge(this.type, {super.key});
  final String type;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: typeColor(type),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      Pokemon.titleCase(type),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF30443D),
      ),
    ),
  );
}
