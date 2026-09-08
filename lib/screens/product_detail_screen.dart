import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../state/cart_controller.dart';
import '../widgets/cart_button.dart';
import '../widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Timer? _notificationTimer;

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _addToCart(BuildContext context) {
    final product = widget.product;
    cartController.add(product);

    final messenger = ScaffoldMessenger.of(context);
    // Remove the old notification immediately before showing the new one.
    // This prevents a second tap from leaving a SnackBar in the queue.
    _notificationTimer?.cancel();
    messenger.removeCurrentSnackBar();
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text('${product.name} added to your cart.'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () {
            _notificationTimer?.cancel();
            context.goNamed('cart');
            messenger.removeCurrentSnackBar();
            messenger.clearSnackBars();
          },
        ),
      ),
    );

    // Remove it directly after two seconds. `removeCurrentSnackBar` is
    // immediate and reliable even when the SnackBar has an action button.
    _notificationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) messenger.removeCurrentSnackBar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: const [CartButton(), SizedBox(width: 8)],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final image = Hero(
            tag: product.id,
            child: ProductImage(
              product: product,
              borderRadius: BorderRadius.circular(28),
              height: isWide ? 440 : 300,
            ),
          );
          final information = Padding(
            padding: EdgeInsets.fromLTRB(isWide ? 32 : 4, 4, 4, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(label: Text(product.category)),
                const SizedBox(height: 14),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  formatProductPrice(product.price),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 20),
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _addToCart(context),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('Add to cart'),
                  ),
                ),
              ],
            ),
          );

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 32 : 20),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: image),
                      Expanded(child: information),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [image, const SizedBox(height: 28), information],
                  ),
          );
        },
      ),
    );
  }
}
