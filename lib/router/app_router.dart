import 'package:go_router/go_router.dart';

import '../data/product_data.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/home_screen.dart';
import '../screens/product_detail_screen.dart';
import '../state/cart_controller.dart';

/// Navigation 2.0 route table for the complete shop flow.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: cartController,
  redirect: (context, state) {
    // Checkout is protected so it can only be reached with at least one item.
    if (state.uri.path == '/checkout' && cartController.isEmpty) {
      return '/cart';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      name: 'productDetail',
      builder: (context, state) => ProductDetailScreen(
        product: productById(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/cart',
      name: 'cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      name: 'checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
  ],
);
