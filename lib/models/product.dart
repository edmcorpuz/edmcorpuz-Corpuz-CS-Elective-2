import 'package:flutter/painting.dart';

import '../three_d/shapes.dart';

/// A row of the `products` table in Supabase.
class Product {
  const Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.stock,
    required this.shape,
    required this.colorHex,
    this.createdAt,
  });

  final int? id;
  final String name;
  final String description;
  final double price;
  final String category;
  final int stock;
  final ShapeKind shape;
  final String colorHex;
  final DateTime? createdAt;

  Color get color => colorFromHex(colorHex);

  bool get inStock => stock > 0;

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: (map['id'] as num).toInt(),
        name: map['name'] as String,
        description: (map['description'] as String?) ?? '',
        price: (map['price'] as num).toDouble(),
        category: map['category'] as String,
        stock: (map['stock'] as num?)?.toInt() ?? 0,
        shape: ShapeKind.fromName(map['shape'] as String?),
        colorHex: (map['color'] as String?) ?? '#C8FF2E',
        createdAt: map['created_at'] == null
            ? null
            : DateTime.tryParse(map['created_at'] as String),
      );

  /// Columns sent on insert/update (id and created_at are set by Postgres).
  Map<String, dynamic> toWriteMap() => {
        'name': name.trim(),
        'description': description.trim(),
        'price': price,
        'category': category.trim(),
        'stock': stock,
        'shape': shape.name,
        'color': colorHex.toUpperCase(),
      };

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? category,
    int? stock,
    ShapeKind? shape,
    String? colorHex,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        category: category ?? this.category,
        stock: stock ?? this.stock,
        shape: shape ?? this.shape,
        colorHex: colorHex ?? this.colorHex,
        createdAt: createdAt,
      );
}

Color colorFromHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (cleaned.length != 6 || value == null) return const Color(0xFFC8FF2E);
  return Color(0xFF000000 | value);
}

/// Formats a peso amount: 18990 -> "₱18,990", 349.5 -> "₱349.50".
String formatPeso(double amount) {
  final whole = amount.truncate();
  final cents = ((amount - whole) * 100).round();
  final digits = whole.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final sign = amount < 0 ? '-' : '';
  final centsPart = cents == 0 ? '' : '.${cents.toString().padLeft(2, '0')}';
  return '$sign₱$buf$centsPart';
}
