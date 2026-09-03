import 'package:go_router/go_router.dart';
import '../data/product_data.dart';
import '../screens/home_screen.dart';
import '../screens/product_detail_screen.dart';

/// Navigation 2.0 route table for the app, built with go_router.
///
/// Only two routes exist at this checkpoint:
///   '/'            -> the home grid
///   '/product/:id' -> the (currently empty) detail page
/// Cart and checkout routes aren't defined yet — they aren't part of
/// this milestone and will be added for the full submission.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      name: 'productDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final product = products.firstWhere((p) => p.id == id);
        return ProductDetailScreen(product: product);
      },
    ),
  ],
);
