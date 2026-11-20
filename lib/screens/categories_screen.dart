import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/shop_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/product_form.dart' show describeError;

/// Admin only: add, rename and delete categories. Renaming moves its
/// products along (the database cascades it); a category still in use
/// can't be deleted.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _run(BuildContext context, Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopControllerProvider);
    final controller = ref.read(shopControllerProvider.notifier);
    final categories = state.categories;

    return Scaffold(
      appBar: AppBar(title: Text('Categories', style: displayStyle(24))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await _askName(context, title: 'New category');
          if (name != null && context.mounted) {
            await _run(context, () => controller.addCategory(name), '$name added');
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add category'),
      ),
      body: !state.loadedOnce
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : categories.isEmpty
              ? Center(
                  child: Text(
                    state.error != null ? describeError(state.error!) : 'No categories yet. Add the first one.',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, i) {
                        final name = categories[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Rename $name',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () async {
                                  final to = await _askName(context, title: 'Rename category', initial: name);
                                  if (to != null && to != name && context.mounted) {
                                    await _run(context, () => controller.renameCategory(name, to), 'Renamed to $to');
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Delete $name',
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                onPressed: () async {
                                  final ok = await confirmDelete(context, name, 'This removes the category. Categories that still have products can’t be deleted.');
                                  if (ok && context.mounted) {
                                    await _run(context, () => controller.deleteCategory(name), '$name deleted');
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}

Future<String?> _askName(BuildContext context, {required String title, String initial = ''}) {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
          onFieldSubmitted: (_) {
            if (formKey.currentState!.validate()) Navigator.pop(context, controller.text.trim());
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(context, controller.text.trim());
          },
          child: const Text('Save'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}
