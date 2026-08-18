import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(const MyApp());

class Fruit {
  final String name;
  final Color color;
  final IconData icon;

  const Fruit({required this.name, required this.color, required this.icon});
}

const List<Fruit> fruits = [
  Fruit(name: 'apple', color: Colors.red, icon: Icons.apple),
  Fruit(name: 'banana', color: Colors.yellow, icon: Icons.emoji_food_beverage),
  Fruit(name: 'grape', color: Colors.purple, icon: Icons.grain),
  Fruit(name: 'orange', color: Colors.orange, icon: Icons.circle),
  Fruit(name: 'cherry', color: Colors.pink, icon: Icons.favorite),
];

Fruit fruitByName(String name) =>
    fruits.firstWhere((f) => f.name == name, orElse: () => fruits.first);


final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'fruitList',
      builder: (context, state) => const FruitListPage(),
      routes: [
        GoRoute(
          path: 'fruit/:name',
          name: 'fruitDetail',
          builder: (context, state) {
            final name = state.pathParameters['name']!;
            return FruitDetailPage(fruit: fruitByName(name));
          },
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'go_router Fruit Demo',
      routerConfig: _router,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
    );
  }
}


class FruitListPage extends StatelessWidget {
  const FruitListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fruits')),
      body: ListView.builder(
        itemCount: fruits.length,
        itemBuilder: (context, index) {
          final fruit = fruits[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: fruit.color.withValues(alpha: 0.2),
              child: Icon(fruit.icon, color: fruit.color),
            ),
            title: Text(fruit.name[0].toUpperCase() + fruit.name.substring(1)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate using the named route so the URL becomes "/fruit/<name>".
              context.goNamed('fruitDetail', pathParameters: {'name': fruit.name});
            },
          );
        },
      ),
    );
  }
}


class FruitDetailPage extends StatelessWidget {
  final Fruit fruit;
  const FruitDetailPage({super.key, required this.fruit});

  @override
  Widget build(BuildContext context) {
    final label = fruit.name[0].toUpperCase() + fruit.name.substring(1);

    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "Illustration" — a big colored icon standing in for artwork.
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: fruit.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(fruit.icon, size: 96, color: fruit.color),
            ),
            const SizedBox(height: 24),
            Text(label, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('This page lives at /fruit/:name'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to fruit list'),
            ),
          ],
        ),
      ),
    );
  }
}