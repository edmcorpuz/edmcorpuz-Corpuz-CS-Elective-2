import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';

abstract interface class OrderRepository {
  /// Places the order through the `place_order` database function. Only
  /// product ids and quantities are sent: Postgres looks up names, prices
  /// and stock itself, and saves everything or nothing.
  Future<Order> placeOrder(Map<int, int> quantities);

  /// RLS decides what comes back: a customer's own orders, or every order
  /// for an admin. Newest first.
  Future<List<Order>> fetchOrders();

  Future<void> updateStatus(int orderId, String status);
}

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Order> placeOrder(Map<int, int> quantities) async {
    final row = await _client.rpc('place_order', params: {
      'items': [
        for (final e in quantities.entries) {'product_id': e.key, 'quantity': e.value},
      ],
    });
    return Order.fromMap(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<List<Order>> fetchOrders() async {
    final rows = await _client
        .from('orders')
        .select('*, order_items(product_name, unit_price, quantity), profiles(email, full_name)')
        .order('created_at', ascending: false)
        .order('id', ascending: false);
    return rows.map(Order.fromMap).toList();
  }

  @override
  Future<void> updateStatus(int orderId, String status) async {
    final updated = await _client.from('orders').update({'status': status}).eq('id', orderId).select('id');
    if (updated.isEmpty) {
      throw const PostgrestException(message: 'No order was updated', code: 'PGRST116');
    }
  }
}
