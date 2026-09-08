import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/cart_controller.dart';

class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cartController,
      builder: (context, child) {
        final count = cartController.totalItems;
        return IconButton(
          tooltip: 'Open cart',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            context.goNamed('cart');
          },
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
        );
      },
    );
  }
}
