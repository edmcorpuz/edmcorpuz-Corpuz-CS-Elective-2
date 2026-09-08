import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/cart_controller.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout confirmation')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: colors.primary,
                      child: Icon(
                        Icons.check_rounded,
                        size: 42,
                        color: colors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Order confirmed!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thank you for shopping with HomeHub. Your order is being prepared.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Order summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...cartController.selectedProducts.map(
                (product) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 52,
                    height: 52,
                    child: ProductImage(
                      product: product,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '${cartController.quantityFor(product)} × ${formatProductPrice(product.price)}',
                  ),
                  trailing: Text(
                    formatProductPrice(
                      product.price * cartController.quantityFor(product),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const Divider(height: 28),
              SummaryRow(
                label: 'Total',
                value: formatProductPrice(cartController.subtotal),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  cartController.clear();
                  context.goNamed('home');
                },
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Continue shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
