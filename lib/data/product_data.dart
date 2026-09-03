import '../models/product.dart';

/// Static product catalog: home appliances.
///
/// imageUrl uses placehold.co, a placeholder-image service that draws
/// a solid-color box with whatever text you give it in the URL — here,
/// the appliance's own name. Real product photography isn't sourced
/// yet at this checkpoint, so a clearly-labeled placeholder stands in
/// for it instead of an unrelated stock photo.
final List<Product> products = [
  const Product(
    id: 'p1',
    name: 'Compact Refrigerator',
    price: 249.99,
    imageUrl: 'https://picsum.photos/seed/picsum/200/300',
  ),
  const Product(
    id: 'p2',
    name: 'Front-Load Washing Machine',
    price: 499.00,
    imageUrl: 'https://picsum.photos/seed/picsum/200/300',
  ),
  const Product(
    id: 'p3',
    name: 'Countertop Microwave',
    price: 89.99,
    imageUrl: 'https://picsum.photos/seed/picsum/200/300',
  ),
  const Product(
    id: 'p4',
    name: 'Split-Type Air Conditioner',
    price: 399.50,
    imageUrl: 'https://picsum.photos/seed/picsum/200/300',
  ),
  const Product(
    id: 'p5',
    name: 'Personal Blender',
    price: 34.99,
    imageUrl: 'https://picsum.photos/seed/picsum/200/300',
  ),
  const Product(
    id: 'p6',
    name: 'Electric Kettle',
    price: 24.99,
    imageUrl: 'https://picsum.photos/seed/picsum/200/300',
  ),
  const Product(
    id: 'p7',
    name: 'Cordless Vacuum Cleaner',
    price: 149.99,
    imageUrl: 'https://picsum.photos/seed/picsum/200/300',
  ),
  const Product(
    id: 'p8',
    name: '2-Slice Toaster',
    price: 29.99,
    imageUrl: 'https://picsum.photos/seed/picsum/200/300',
  ),
];
