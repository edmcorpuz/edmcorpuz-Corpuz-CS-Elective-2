import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../state/bag_controller.dart';
import '../state/orders_controller.dart';
import '../theme/app_theme.dart';
import '../three_d/appliance_view.dart';
import '../widgets/product_form.dart' show describeError;
import 'order_confirmation_screen.dart';

/// The customer's cart: change quantities, remove lines, see the running
/// total, and check out. Quantities can't go past the stock on hand.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final order = await ref.read(checkoutProvider.notifier).placeOrder();
    if (order != null && context.mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => OrderConfirmationScreen(order: order)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(bagProvider).values.toList();
    final bag = ref.read(bagProvider.notifier);
    final checkout = ref.watch(checkoutProvider);
    final count = lines.fold(0, (sum, l) => sum + l.quantity);
    final total = lines.fold(0.0, (sum, l) => sum + l.subtotal);

    return Scaffold(
      appBar: AppBar(title: Text('Your cart', style: displayStyle(24))),
      body: lines.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.muted),
                    const SizedBox(height: 16),
                    Text('Your cart is empty', style: displayStyle(26)),
                    const SizedBox(height: 8),
                    const Text('Tap “Add to cart” on an appliance to start.', style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 20),
                    OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to the shop')),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: lines.length,
                        separatorBuilder: (_, _) => const Divider(height: 24),
                        itemBuilder: (context, i) => _CartLine(line: lines[i], bag: bag),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text('$count ${count == 1 ? 'ITEM' : 'ITEMS'} · TOTAL', style: monoLabel()),
                              const Spacer(),
                              Text(formatPeso(total), style: displayStyle(28)),
                            ],
                          ),
                          if (checkout.hasError) ...[
                            const SizedBox(height: 12),
                            Text(describeError(checkout.error!), style: const TextStyle(color: AppColors.danger)),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: checkout.isLoading ? null : () => _checkout(context, ref),
                            child: checkout.isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Text('Checkout'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.line, required this.bag});

  final BagLine line;
  final BagController bag;

  @override
  Widget build(BuildContext context) {
    final p = line.product;
    final atStock = line.quantity >= p.stock;
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(14)),
          child: ApplianceView(kind: p.kind, color: p.color, showShadow: false, zoom: 1.05),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${formatPeso(p.price)} each', style: const TextStyle(color: AppColors.muted)),
              if (atStock)
                Text('Only ${p.stock} in stock', style: monoLabel(size: 9.5, color: AppColors.accent)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'One less',
          onPressed: () => bag.decrement(p.id!),
          icon: const Icon(Icons.remove_rounded, size: 18),
        ),
        SizedBox(
          width: 28,
          child: Text('${line.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        IconButton(
          tooltip: atStock ? 'No more in stock' : 'One more',
          onPressed: atStock ? null : () => bag.add(p),
          icon: const Icon(Icons.add_rounded, size: 18),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 92,
          child: Text(formatPeso(line.subtotal), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        IconButton(
          tooltip: 'Remove from cart',
          onPressed: () => bag.remove(p.id!),
          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.muted),
        ),
      ],
    );
  }
}
