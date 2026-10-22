import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/pokedex_provider.dart';

Future<void> showNicknameEditor(BuildContext context, Pokemon pokemon) =>
    showDialog<void>(
      context: context,
      builder: (_) => NicknameEditor(pokemon: pokemon),
    );

class NicknameEditor extends ConsumerStatefulWidget {
  const NicknameEditor({super.key, required this.pokemon});
  final Pokemon pokemon;

  @override
  ConsumerState<NicknameEditor> createState() => _NicknameEditorState();
}

class _NicknameEditorState extends ConsumerState<NicknameEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: ref.read(pokedexProvider).nicknames[widget.pokemon.id] ?? '',
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(pokedexProvider.notifier)
        .saveNickname(widget.pokemon.id, _text.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasNickname = ref.watch(
      pokedexProvider.select(
        (state) => state.nicknames.containsKey(widget.pokemon.id),
      ),
    );
    return AlertDialog(
      scrollable: true,
      title: Text('A name for ${widget.pokemon.displayName}'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Make it personal. The original Pokémon name will always stay visible.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('nickname-input'),
                controller: _text,
                autofocus: true,
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  hintText: 'Something that feels right',
                ),
                onFieldSubmitted: (_) => _save(),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Enter a nickname, or choose Remove nickname.';
                  }
                  if (text.length > 30) return 'Use 30 characters or fewer.';
                  return null;
                },
              ),
              if (hasNickname)
                TextButton.icon(
                  key: const ValueKey('remove-nickname'),
                  onPressed: () {
                    ref
                        .read(pokedexProvider.notifier)
                        .removeNickname(widget.pokemon.id);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove nickname'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save nickname')),
      ],
    );
  }
}
