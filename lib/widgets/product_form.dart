import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException, PostgrestException;

import '../models/product.dart';
import '../state/bag_controller.dart';
import '../state/shop_controller.dart';
import '../theme/app_theme.dart';
import '../three_d/appliance_view.dart';
import '../three_d/appliances.dart';

/// Appliance finishes: white, silver, graphite, then retro colors.
const kSwatches = [
  '#F2F2F2', '#C9CDD3', '#4A4F5A', '#3A3D45', '#A8E6CF', '#9AD1FF',
  '#5CE1E6', '#C3B1E1', '#FF8A65', '#E5484D', '#FFE08A', '#F3E6C8', '#C8FF2E',
];

/// Opens the create/edit form (dialog on wide screens, sheet on phones).
/// Returns the saved product, or null if cancelled.
Future<Product?> showProductForm(BuildContext context, {Product? initial}) {
  final wide = MediaQuery.sizeOf(context).width >= 720;
  final form = ProductForm(initial: initial);
  if (wide) {
    return showDialog<Product>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720), child: form),
      ),
    );
  }
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => form,
  );
}

class ProductForm extends ConsumerStatefulWidget {
  const ProductForm({super.key, this.initial});

  final Product? initial;

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  String? _category;
  String? _imageUrl;
  Uint8List? _pickedBytes;
  String _pickedExt = 'jpg';
  late ApplianceKind _kind;
  late String _color;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p == null ? '' : _plain(p.price));
    _stock = TextEditingController(text: p == null ? '10' : '${p.stock}');
    _category = p?.category ?? ApplianceKind.fridge.category;
    _imageUrl = p?.imageUrl;
    _kind = p?.kind ?? ApplianceKind.fridge;
    _color = (p?.colorHex ?? kSwatches.first).toUpperCase();
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      setState(() {
        _pickedBytes = bytes;
        _pickedExt = name.contains('.') ? name.split('.').last : 'jpg';
      });
    } catch (e) {
      setState(() => _error = 'Couldn’t open that photo: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final controller = ref.read(shopControllerProvider.notifier);
    if (_pickedBytes != null) {
      try {
        _imageUrl = await controller.uploadImage(_pickedBytes!, extension: _pickedExt);
        _pickedBytes = null;
      } catch (e) {
        if (mounted) {
          setState(() {
            _saving = false;
            _error = 'Photo upload failed: ${describeError(e)}';
          });
        }
        return;
      }
    }
    final draft = Product(
      id: widget.initial?.id,
      name: _name.text,
      description: _description.text,
      price: double.parse(_price.text.trim()),
      category: _category!,
      stock: int.parse(_stock.text.trim()),
      kind: _kind,
      colorHex: _color,
      imageUrl: _imageUrl,
    );
    try {
      final saved = _editing ? await controller.update(draft) : await controller.create(draft);
      ref.read(bagProvider.notifier).sync(saved);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = describeError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(shopControllerProvider.select((s) => s.categories));
    final category = categories.contains(_category) ? _category : null;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    final preview = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          colors: [Color.lerp(AppColors.surfaceHigh, colorFromHex(_color), 0.2)!, AppColors.bg],
        ),
        border: Border.all(color: AppColors.line),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ApplianceView(
              key: ValueKey(_kind),
              kind: _kind,
              color: colorFromHex(_color),
              detail: MeshDetail.high,
              interactive: true,
              activateOnHover: true,
            ),
          ),
          Positioned(
            left: 14,
            bottom: 12,
            child: Text('LIVE PREVIEW · HOVER OR DRAG', style: monoLabel(size: 9.5)),
          ),
        ],
      ),
    );

    final fields = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            maxLength: 80,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Give it a name' : null,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(labelText: 'Price', prefixText: '₱ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null) return 'Enter a price';
                    if (n < 0) return 'Must be ≥ 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stock,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => int.tryParse(v?.trim() ?? '') == null ? 'Whole number' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [for (final c in categories) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: (c) => setState(() => _category = c),
            validator: (c) => c == null ? 'Pick a category (add new ones under Categories)' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 18),
          Text('APPLIANCE TYPE (3D MODEL)', style: monoLabel()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in ApplianceKind.values)
                ChoiceChip(
                  label: Text(k.label),
                  selected: _kind == k,
                  onSelected: (_) => setState(() {
                    // Keep the category in step with the type unless the
                    // admin picked a different one.
                    if ((_category == null || _category == _kind.category) && categories.contains(k.category)) {
                      _category = k.category;
                    }
                    _kind = k;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('COLOR', style: monoLabel()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final hex in kSwatches) _swatch(hex)],
          ),
          const SizedBox(height: 18),
          Text('PHOTO', style: monoLabel()),
          const SizedBox(height: 8),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: _pickedBytes != null
                      ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                      : _imageUrl != null
                          ? Image.network(_imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const _PhotoPlaceholder())
                          : const _PhotoPlaceholder(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickPhoto,
                      icon: const Icon(Icons.photo_outlined, size: 18),
                      label: Text(_pickedBytes != null || _imageUrl != null ? 'Change photo' : 'Upload photo'),
                    ),
                    if (_pickedBytes != null || _imageUrl != null)
                      TextButton(
                        onPressed: _saving ? null : () => setState(() {
                          _pickedBytes = null;
                          _imageUrl = null;
                        }),
                        child: const Text('Remove'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: AppColors.danger)),
          ],
        ],
      ),
    );

    final actions = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: AppColors.muted)),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent))
              : Text(_editing ? 'Save changes' : 'Add product'),
        ),
      ],
    );

    final title = Text(_editing ? 'Edit product' : 'New product', style: displayStyle(30));

    if (wide) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 280, child: preview),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  const SizedBox(height: 18),
                  Expanded(child: SingleChildScrollView(child: fields)),
                  const SizedBox(height: 16),
                  actions,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            title,
            const SizedBox(height: 16),
            SizedBox(height: 200, child: preview),
            const SizedBox(height: 20),
            fields,
            const SizedBox(height: 20),
            actions,
          ],
        ),
      ),
    );
  }

  Widget _swatch(String hex) {
    final selected = _color == hex.toUpperCase();
    return Semantics(
      button: true,
      selected: selected,
      label: 'Color $hex',
      child: GestureDetector(
        onTap: () => setState(() => _color = hex.toUpperCase()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colorFromHex(hex),
            shape: BoxShape.circle,
            border: Border.all(color: selected ? AppColors.text : Colors.transparent, width: 2.5),
            boxShadow: selected ? [BoxShadow(color: colorFromHex(hex).withValues(alpha: 0.5), blurRadius: 12)] : null,
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.surfaceHigh,
        child: Center(child: Icon(Icons.image_outlined, color: AppColors.muted)),
      );
}

/// Turns Supabase/Postgres errors into something a person can act on.
String describeError(Object e) {
  if (e is AuthException) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) return 'Wrong email or password.';
    if (message.contains('already registered') || message.contains('already been registered')) {
      return 'That email already has an account. Log in instead.';
    }
    if (message.contains('provider is not enabled') || message.contains('unsupported provider')) {
      return 'Google sign-in isn’t switched on yet. Enable the Google provider in Supabase → Authentication → Sign In / Providers.';
    }
    if (message.contains('signups not allowed') || message.contains('signup is disabled')) {
      return 'New accounts are turned off for this store. Turn on “Allow new users to sign up” in Supabase.';
    }
    if (message.contains('access_denied') || message.contains('denied')) {
      return 'Google sign-in was cancelled.';
    }
    // Google approved the sign-in but Supabase couldn't finish it (usually a wrong client secret).
    if (message.contains('unable to exchange external code')) {
      return 'Google sign-in couldn’t be completed. Try again, or log in with email. If it keeps happening, the store’s Google setup needs fixing.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirm your email first: open the link we sent you, then log in.';
    }
    return e.message;
  }
  if (e is PostgrestException) {
    switch (e.code) {
      // Raised by place_order() with a message written for customers.
      case 'P0001' || 'P0002' || '22023':
        return e.message;
      case '23503':
        return 'That category still has products. Move or delete them first.';
      case '23505':
        return 'That name is already taken.';
      case '42501':
        return e.message.contains('permission denied') || e.message.contains('row-level security')
            ? 'Your account isn’t allowed to do that.'
            : e.message;
      case 'PGRST116':
        return 'Nothing was changed. Your account may not be allowed to do that, or it was already removed.';
      case '42P01' || 'PGRST205' || 'PGRST202':
        return 'Part of the database is missing. Run supabase/schema.sql in the SQL editor.';
    }
    return e.message;
  }
  final text = e.toString();
  if (text.contains('row-level security') || text.contains('Unauthorized') || text.contains('403')) {
    return 'Your account isn’t allowed to do that.';
  }
  if (text.contains('SocketException') || text.contains('ClientException') || text.contains('Failed host lookup')) {
    return 'Can’t reach Supabase. Check your internet connection.';
  }
  return text.replaceFirst('Exception: ', '');
}
