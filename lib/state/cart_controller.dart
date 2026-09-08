import 'package:flutter/foundation.dart';

import '../data/product_data.dart';
import '../models/product.dart';

/// Shared cart state. Widgets listen to this notifier so totals and badges
/// update immediately after a quantity button is pressed.
class CartController extends ChangeNotifier {
  final Map<String, int> _quantities = {};

  bool get isEmpty => _quantities.isEmpty;
  int get totalItems => _quantities.values.fold(0, (sum, value) => sum + value);

  double get subtotal => _quantities.entries.fold(0, (sum, entry) {
        return sum + productById(entry.key).price * entry.value;
      });

  List<Product> get selectedProducts => _quantities.keys.map(productById).toList();

  int quantityFor(Product product) => _quantities[product.id] ?? 0;

  void add(Product product) {
    _quantities.update(product.id, (quantity) => quantity + 1, ifAbsent: () => 1);
    notifyListeners();
  }

  void decrement(Product product) {
    final quantity = quantityFor(product);
    if (quantity <= 1) {
      _quantities.remove(product.id);
    } else {
      _quantities[product.id] = quantity - 1;
    }
    notifyListeners();
  }

  void remove(Product product) {
    _quantities.remove(product.id);
    notifyListeners();
  }

  void clear() {
    _quantities.clear();
    notifyListeners();
  }
}

final cartController = CartController();
