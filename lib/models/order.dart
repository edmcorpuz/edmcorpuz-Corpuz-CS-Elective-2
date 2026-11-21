/// One saved line of an order. Name and price are a snapshot taken at
/// checkout, so past orders stay accurate after edits or deletes.
class OrderItem {
  const OrderItem({required this.productName, required this.unitPrice, required this.quantity});

  final String productName;
  final double unitPrice;
  final int quantity;

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productName: map['product_name'] as String,
        unitPrice: (map['unit_price'] as num).toDouble(),
        quantity: (map['quantity'] as num).toInt(),
      );
}

/// A row of `orders`, with its items and (for admins) who placed it.
class Order {
  const Order({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    this.items = const [],
    this.customerEmail,
    this.customerName,
  });

  static const statuses = ['pending', 'done', 'shipped', 'cancelled'];

  final int id;
  final String status;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;
  final String? customerEmail;
  final String? customerName;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  factory Order.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    final name = [profile?['firstname'], profile?['lastname']].whereType<String>().join(' ').trim();
    return Order(
      id: (map['id'] as num).toInt(),
      status: map['status'] as String,
      total: (map['total'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      items: [
        for (final i in (map['order_items'] as List?) ?? const []) OrderItem.fromMap(i as Map<String, dynamic>),
      ],
      customerEmail: profile?['email'] as String?,
      customerName: name.isEmpty ? null : name,
    );
  }
}
