import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const MyApp());
}

// ============================================================
// 1. APP ROOT
// ============================================================
// MaterialApp.router (instead of plain MaterialApp) is what turns on
// Navigation 2.0 — it hands navigation control over to `appRouter`
// below instead of using Navigator.push/pop directly.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HomeHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: appRouter,
    );
  }
}

// ============================================================
// 2. DESIGN THEME
// ============================================================
// One ThemeData, defined once, used everywhere. No screen below sets
// its own colors directly — they all pull from Theme.of(context)
// or from a themed widget (like AppBar or ElevatedButton), which
// reads its style from here automatically.
class AppTheme {
  static const Color _seed = Color(0xFF2E5AAC); // HomeHub brand blue

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seed);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        bodyMedium: TextStyle(fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 3. PRODUCT DATA (Home Appliances)
// ============================================================
// A plain data class. Nothing about a Product ever changes after
// it's created, which is why every widget below that displays one
// is a StatelessWidget.
class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });
}

final List<Product> products = [
  const Product(
    id: 'p1',
    name: 'Compact Refrigerator',
    price: 249.99,
    imageUrl: 'https://picsum.photos/seed/hh-fridge/600/600',
  ),
  const Product(
    id: 'p2',
    name: 'Front-Load Washing Machine',
    price: 499.00,
    imageUrl: 'https://picsum.photos/seed/hh-washer/600/600',
  ),
  const Product(
    id: 'p3',
    name: 'Countertop Microwave',
    price: 89.99,
    imageUrl: 'https://picsum.photos/seed/hh-microwave/600/600',
  ),
  const Product(
    id: 'p4',
    name: 'Split-Type Air Conditioner',
    price: 399.50,
    imageUrl: 'https://picsum.photos/seed/hh-aircon/600/600',
  ),
  const Product(
    id: 'p5',
    name: 'Personal Blender',
    price: 34.99,
    imageUrl: 'https://picsum.photos/seed/hh-blender/600/600',
  ),
  const Product(
    id: 'p6',
    name: 'Electric Kettle',
    price: 24.99,
    imageUrl: 'https://picsum.photos/seed/hh-kettle/600/600',
  ),
  const Product(
    id: 'p7',
    name: 'Cordless Vacuum Cleaner',
    price: 149.99,
    imageUrl: 'https://picsum.photos/seed/hh-vacuum/600/600',
  ),
  const Product(
    id: 'p8',
    name: '2-Slice Toaster',
    price: 29.99,
    imageUrl: 'https://picsum.photos/seed/hh-toaster/600/600',
  ),
];

// ============================================================
// 4. ROUTING (Navigation 2.0 with go_router)
// ============================================================
// Two routes only, for this checkpoint:
//   '/'            -> the home grid
//   '/product/:id' -> the (currently empty) detail page
// go_router reads the `:id` out of the URL/path and we use it to look
// up the matching Product before building the detail screen.
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

// ============================================================
// 5. HOME SCREEN (product grid)
// ============================================================
// StatelessWidget: nothing on this screen changes after it's built —
// tapping a product just navigates away, it doesn't change anything
// on this screen itself.
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
                // against the routes list above.
                onTap: () => context.push('/product/${product.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// 6. PRODUCT CARD (one grid tile)
// ============================================================
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(product.imageUrl, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 7. PRODUCT DETAIL SCREEN — intentionally EMPTY for now
// ============================================================
// This satisfies "routing to an empty details page": tapping a
// product correctly navigates here and this screen receives the
// right Product, but its body is just a placeholder. The real
// content (image, price, description, Add to Cart) gets filled in
// for the full submission.
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