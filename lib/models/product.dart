import 'package:flutter/material.dart';

/// Immutable catalog data used by the stateless product cards and details page.
class Product {
  final String id;
  final String name;
  final String category;
  final String brand;
  final double price;
  final String description;
  final String imageUrl;
  final IconData fallbackIcon;
  final double rating;
  final int sold;
  final int discountPercent;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    this.brand = 'HomeHub Select',
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.fallbackIcon,
    this.rating = 4.8,
    this.sold = 0,
    this.discountPercent = 0,
  });
}
