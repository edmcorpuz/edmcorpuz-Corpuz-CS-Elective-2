/// Represents a single product in the shop.
///
/// This is a plain, immutable data class — once a [Product] is created
/// its fields never change. That's why the widget that displays it
/// ([ProductCard]) can safely be a StatelessWidget: there's nothing
/// here for it to react to.
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
