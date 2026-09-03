import 'package:flutter/material.dart';
import '../models/product.dart';

/// Product detail screen — intentionally EMPTY for now.
///
/// This satisfies "routing to an empty details page": tapping a
/// product correctly navigates here and this screen receives the
/// right Product (proven by the AppBar title), but its body is just
/// a placeholder. The real content (image, price, description, Add
/// to Cart button) is filled in for the full submission.
class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: const Center(
        child: Text(
          'Product details coming soon.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
