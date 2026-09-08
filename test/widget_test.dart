import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unang_flutter_project/main.dart';
import 'package:unang_flutter_project/router/app_router.dart';
import 'package:unang_flutter_project/state/cart_controller.dart';
import 'package:unang_flutter_project/state/theme_controller.dart';

void main() {
  setUp(() {
    cartController.clear();
    themeController.value = ThemeMode.light;
    appRouter.go('/');
  });

  testWidgets('shows the responsive HomeHub product grid',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('HomeHub'), findsOneWidget);
    expect(find.text('Compact Refrigerator'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byTooltip('Open cart'), findsOneWidget);
  });

  testWidgets('completes the product, cart, and checkout flow',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    appRouter.go('/product/p1');
    await tester.pumpAndSettle();
    expect(find.text('Product details'), findsOneWidget);
    expect(find.text('Add to cart'), findsOneWidget);

    await tester.tap(find.text('Add to cart'));
    await tester.pump();
    expect(cartController.totalItems, 1);
    expect(find.text('Compact Refrigerator added to your cart.'), findsOneWidget);

    // A second rapid add should replace the notification, not queue another one.
    await tester.tap(find.text('Add to cart'));
    await tester.pump();
    expect(cartController.totalItems, 2);
    expect(find.text('VIEW CART'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('VIEW CART'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart'), findsOneWidget);
    expect(find.text('Proceed to checkout'), findsOneWidget);

    await tester.tap(find.text('Proceed to checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Checkout confirmation'), findsOneWidget);
    expect(find.text('Order confirmed!'), findsOneWidget);
  });

  testWidgets('auto-dismisses the cart notification after two seconds',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    appRouter.go('/product/p1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to cart'));
    await tester.pump();
    expect(find.text('Compact Refrigerator added to your cart.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Compact Refrigerator added to your cart.'), findsNothing);
  });
}
