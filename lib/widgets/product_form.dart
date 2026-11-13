import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../state/bag_controller.dart';
import '../state/shop_controller.dart';
import '../theme/app_theme.dart';
import '../three_d/shapes.dart';
import '../three_d/spinning_mesh.dart';

const kSwatches = [
  '#C8FF2E', '#FFB23F', '#FF6A3D', '#FF4F81', '#FF8FB1', '#A78BFA',
  '#6E7BFF', '#5CE1E6', '#7CF5D4', '#B5E48C', '#E7C9A9', '#F2EDE4',
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
  late final TextEditingController _category;
  late ShapeKind _shape;
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
    _category = TextEditingController(text: p?.category ?? '');
    _shape = p?.shape ?? ShapeKind.cube;
    _color = (p?.colorHex ?? kSwatches.first).toUpperCase();
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _stock, _category]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final draft = Product(
      id: widget.initial?.id,
      name: _name.text,
      description: _description.text,
      price: double.parse(_price.text.trim()),
      category: _category.text,
      stock: int.parse(_stock.text.trim()),
      shape: _shape,
      colorHex: _color,
    );
    final controller = ref.read(shopControllerProvider.notifier);
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
            child: SpinningMesh(
              key: ValueKey(_shape),
              shape: _shape,
              color: colorFromHex(_color),
              detail: MeshDetail.high,
              interactive: true,
            ),
          ),
          Positioned(
            left: 14,
            bottom: 12,
            child: Text('LIVE PREVIEW · DRAG TO ROTATE', style: monoLabel(size: 9.5)),
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
          TextFormField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Pick or type a category' : null,
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in categories)
                  ActionChip(
                    label: Text(c, style: const TextStyle(fontSize: 12)),
                    onPressed: () => setState(() => _category.text = c),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 18),
          Text('SHAPE', style: monoLabel()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in ShapeKind.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _shape == s,
                  onSelected: (_) => setState(() => _shape = s),
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
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
        ],
      ),
    );

    final actions = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Text(_editing ? 'Save changes' : 'Add product'),
        ),
      ],
    );

    final title = Text(_editing ? 'Edit object' : 'New object', style: displayStyle(30));

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

/// Turns Supabase/Postgres errors into something a person can act on.
String describeError(Object e) {
  final text = e.toString();
  if (text.contains('PGRST116')) {
    return 'Supabase saved nothing — check the row-level security policies in supabase/schema.sql.';
  }
  if (text.contains('42501') || text.contains('row-level security')) {
    return 'Blocked by row-level security. Run supabase/schema.sql in the SQL editor.';
  }
  if (text.contains('42P01') || text.contains('PGRST205')) {
    return 'The products table does not exist yet. Run supabase/schema.sql in the SQL editor.';
  }
  if (text.contains('SocketException') || text.contains('ClientException') || text.contains('Failed host lookup')) {
    return 'Can’t reach Supabase. Check your internet connection and SUPABASE_URL.';
  }
  return text.replaceFirst('Exception: ', '');
}
