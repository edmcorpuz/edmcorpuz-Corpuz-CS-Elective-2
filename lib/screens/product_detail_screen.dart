import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../state/admin_controller.dart';
import '../state/bag_controller.dart';
import '../state/shop_controller.dart';
import '../theme/app_theme.dart';
import '../three_d/appliance_view.dart';
import '../three_d/appliances.dart';
import '../widgets/product_form.dart';

/// Full-bleed 3D stage + details. Pops with a message after a delete.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late Product _product = widget.product;
  bool _deleting = false;
  bool _demoOn = false;

  Future<void> _edit() async {
    final saved = await showProductForm(context, initial: _product);
    if (saved != null && mounted) {
      setState(() => _product = saved);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved to Supabase')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_product.name}?'),
        content: const Text('This removes the product from the Supabase table. It can’t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(shopControllerProvider.notifier).delete(_product);
      ref.read(bagProvider.notifier).sync(_product, deleted: true);
      if (mounted) Navigator.of(context).pop('${_product.name} deleted');
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    final inBag = ref.watch(bagProvider.select((b) => b[p.id]?.quantity ?? 0));
    final isAdmin = ref.watch(adminProvider.select((a) => a.isAdmin));

    final stage = Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.15),
                radius: 0.85,
                colors: [p.color.withValues(alpha: 0.28), AppColors.bg],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Hero(
            tag: 'product-model-${p.id}',
            child: ApplianceView(
              kind: p.kind,
              color: p.color,
              detail: MeshDetail.high,
              interactive: true,
              activateOnHover: true,
              active: _demoOn,
              zoom: 1.0,
              speed: 0.25,
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 22,
          child: Row(
            children: [
              const Icon(Icons.threesixty_rounded, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Text('HOVER OR DRAG · ${p.kind.label.toUpperCase()}', style: monoLabel(size: 10)),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 12,
          child: FilledButton.tonalIcon(
            onPressed: () => setState(() => _demoOn = !_demoOn),
            style: FilledButton.styleFrom(
              backgroundColor: _demoOn ? AppColors.accent : AppColors.surfaceHigh,
              foregroundColor: _demoOn ? Colors.black : AppColors.text,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: Icon(_demoOn ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 18),
            label: Text(_demoOn ? 'Stop' : p.kind.action),
          ),
        ),
      ],
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(p.category.toUpperCase(), style: monoLabel(color: AppColors.accent)),
        const SizedBox(height: 12),
        Text(p.name, style: displayStyle(44)),
        const SizedBox(height: 14),
        Text(formatPeso(p.price), style: displayStyle(28, color: AppColors.muted)),
        const SizedBox(height: 22),
        if (p.description.isNotEmpty)
          Text(p.description, style: const TextStyle(color: AppColors.muted, fontSize: 15, height: 1.6)),
        const SizedBox(height: 26),
        _SpecRow(label: 'TYPE', value: p.kind.label),
        _SpecRow(
          label: 'FINISH',
          value: p.colorHex.toUpperCase(),
          leading: Container(width: 12, height: 12, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
        ),
        _SpecRow(label: 'IN STOCK', value: p.stock == 0 ? 'Sold out' : '${p.stock} pcs'),
        _SpecRow(label: 'SKU', value: 'FCT-${p.kind.dbName.toUpperCase()}-${(p.id ?? 0).toString().padLeft(4, '0')}'),
        const SizedBox(height: 26),
        FilledButton.icon(
          onPressed: p.inStock && inBag < p.stock ? () => ref.read(bagProvider.notifier).add(p) : null,
          icon: const Icon(Icons.shopping_bag_outlined, size: 18),
          label: Text(inBag > 0 ? 'Add another ($inBag in bag)' : 'Add to bag'),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleting ? null : _edit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleting ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  icon: _deleting
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to shop',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: stage),
                SizedBox(
                  width: 460,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 96, 40, 40),
                    child: details,
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(height: constraints.maxHeight * 0.5 + 40, child: stage),
              Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), child: details),
            ],
          );
        },
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value, this.leading});

  final String label;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: monoLabel(size: 10))),
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
