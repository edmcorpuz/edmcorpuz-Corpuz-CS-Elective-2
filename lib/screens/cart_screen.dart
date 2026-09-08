import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../state/cart_controller.dart';
import '../widgets/cart_button.dart';
import '../widgets/product_card.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
        actions: const [CartButton(), SizedBox(width: 8)],
      ),
      body: AnimatedBuilder(
        animation: cartController,
        builder: (context, child) {
          if (cartController.isEmpty) return const EmptyCartView();

          return LayoutBuilder(
            builder: (context, constraints) {
              final items = ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                itemCount: cartController.selectedProducts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => CartItemTile(
                  product: cartController.selectedProducts[index],
                ),
              );
              final summary = CartSummary(
                onCheckout: () => context.goNamed('checkout'),
              );

              if (constraints.maxWidth >= 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: items),
                    SizedBox(width: 360, child: summary),
                  ],
                );
              }

              return Column(
                children: [
                  Expanded(child: items),
                  summary,
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class EmptyCartView extends StatelessWidget {
  const EmptyCartView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 72, color: colors.primary),
            const SizedBox(height: 18),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Browse the appliances and add something useful.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.goNamed('home'),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Browse products'),
            ),
          ],
        ),
      ),
    );
  }
}

class CartItemTile extends StatelessWidget {
  final Product product;

  const CartItemTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final quantity = cartController.quantityFor(product);
    return Card(
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: ProductImage(
                product: product,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatProductPrice(product.price),
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  QuantityStepper(product: product, quantity: quantity),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Remove item',
                  onPressed: () => cartController.remove(product),
                  icon: const Icon(Icons.close_rounded),
                ),
                Text(
                  formatProductPrice(product.price * quantity),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  final Product product;
  final int quantity;

  const QuantityStepper({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicWidth(
        child: Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Decrease quantity',
              onPressed: () => cartController.decrement(product),
              icon: const Icon(Icons.remove_rounded, size: 18),
            ),
            Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800)),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Increase quantity',
              onPressed: () => cartController.add(product),
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class CartSummary extends StatelessWidget {
  final VoidCallback onCheckout;

  const CartSummary({super.key, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 16),
            SummaryRow(label: 'Items', value: '${cartController.totalItems}'),
            const SizedBox(height: 8),
            SummaryRow(
              label: 'Subtotal',
              value: formatProductPrice(cartController.subtotal),
            ),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  formatProductPrice(cartController.subtotal),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onCheckout,
                child: const Text('Proceed to checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const SummaryRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimaryContainer;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
