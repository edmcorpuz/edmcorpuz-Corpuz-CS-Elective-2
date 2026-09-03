import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/product_data.dart';
import '../widgets/product_card.dart';

/// The product grid — the app's home screen.
///
/// StatelessWidget: nothing on this screen changes after it's built.
/// There's no cart badge or theme toggle yet at this checkpoint, so
/// there's nothing here that needs to react to outside changes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 2 columns on phone-width screens, 3+ on tablet-width screens.
  // LayoutBuilder tells us how much horizontal space we actually have.
  int _columnsForWidth(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HomeHub')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = _columnsForWidth(constraints.maxWidth);
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                // Navigation 2.0: push a path, go_router matches it
                // against the routes list in app_router.dart.
                onTap: () => context.push('/product/${product.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
