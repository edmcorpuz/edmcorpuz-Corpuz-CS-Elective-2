import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/order_repository.dart';
import '../models/order.dart';
import 'account_controller.dart';
import 'bag_controller.dart';
import 'shop_controller.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => SupabaseOrderRepository(Supabase.instance.client),
);

/// A customer's own orders, or every order for an admin (RLS decides).
final ordersProvider = AsyncNotifierProvider.autoDispose<OrdersController, List<Order>>(OrdersController.new);

class OrdersController extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() {
    // Reload for whoever is signed in now.
    ref.watch(accountProvider.select((a) => a.user?.id));
    return ref.read(orderRepositoryProvider).fetchOrders();
  }

  /// Reloads while keeping the current list on screen; errors land in [state].
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {}
  }

  /// Admin only (enforced by RLS and a column grant on `status`).
  Future<void> setStatus(int orderId, String status) async {
    await ref.read(orderRepositoryProvider).updateStatus(orderId, status);
    await refresh();
  }
}

/// Turns the cart into an order. Holds the last checkout's result so the
/// cart screen can show progress and errors.
final checkoutProvider = NotifierProvider<CheckoutController, AsyncValue<Order?>>(CheckoutController.new);

class CheckoutController extends Notifier<AsyncValue<Order?>> {
  @override
  AsyncValue<Order?> build() {
    ref.watch(accountProvider.select((a) => a.user?.id));
    return const AsyncData(null);
  }

  /// Places the order, then empties the cart and reloads stock and orders.
  /// Returns the saved order, or null if it failed (see [state] for why).
  Future<Order?> placeOrder() async {
    final lines = ref.read(bagProvider);
    if (lines.isEmpty || state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final order = await ref.read(orderRepositoryProvider).placeOrder({
        for (final l in lines.values) l.product.id!: l.quantity,
      });
      ref.read(bagProvider.notifier).clear();
      ref.invalidate(ordersProvider);
      await ref.read(shopControllerProvider.notifier).refresh();
      if (ref.mounted) state = AsyncData(order);
      return order;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      return null;
    }
  }
}
