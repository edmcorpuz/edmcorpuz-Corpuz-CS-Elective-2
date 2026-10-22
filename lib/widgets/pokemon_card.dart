import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/pokedex_provider.dart';
import 'favorite_button.dart';
import 'nickname_editor.dart';
import 'pokemon_image.dart';
import 'type_badge.dart';

class PokemonCard extends ConsumerWidget {
  const PokemonCard({super.key, required this.pokemon, this.onTap});
  final Pokemon pokemon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(
      pokedexProvider.select((state) => state.nicknames[pokemon.id]),
    );
    final tint = typeColor(pokemon.types.firstOrNull ?? 'normal');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('open-pokemon-${pokemon.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    pokemon.displayId,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF66756D),
                    ),
                  ),
                  const Spacer(),
                  FavoriteButton(pokemon: pokemon),
                ],
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [tint, Colors.white],
                      radius: 0.72,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: PokemonImage(pokemon: pokemon),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pokemon.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nickname ?? 'Make it yours',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: nickname == null
                            ? const Color(0xFF66756D)
                            : const Color(0xFF226653),
                      ),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('edit-nickname-${pokemon.id}'),
                    tooltip: 'Edit nickname for ${pokemon.displayName}',
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    onPressed: () => showNicknameEditor(context, pokemon),
                  ),
                ],
              ),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: pokemon.types.map(TypeBadge.new).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
