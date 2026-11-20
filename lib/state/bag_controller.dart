import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import 'account_controller.dart';

class BagLine {
  const BagLine(this.product, this.quantity);

  final Product product;
  final int quantity;

  double get subtotal => product.price * quantity;
}

final bagProvider =
    NotifierProvider<BagController, Map<int, BagLine>>(BagController.new);

/// The cart, keyed by product id. Lives in app state so it survives screen
/// changes; it empties after a successful order and whenever the signed-in
/// account changes (including logout).
class BagController extends Notifier<Map<int, BagLine>> {
  @override
  Map<int, BagLine> build() {
    ref.watch(accountProvider.select((a) => a.user?.id));
    return const {};
  }

  int get count => state.values.fold(0, (sum, l) => sum + l.quantity);

  double get total => state.values.fold(0.0, (sum, l) => sum + l.subtotal);

  /// Adds one; does nothing for sold-out products or past the stock.
  void add(Product product) {
    final id = product.id;
    if (id == null) return;
    final current = state[id]?.quantity ?? 0;
    if (current >= product.stock) return;
    state = {...state, id: BagLine(product, current + 1)};
  }

  void decrement(int id) {
    final line = state[id];
    if (line == null) return;
    final next = {...state};
    if (line.quantity <= 1) {
      next.remove(id);
    } else {
      next[id] = BagLine(line.product, line.quantity - 1);
    }
    state = next;
  }

  void remove(int id) => state = {...state}..remove(id);

  void clear() => state = const {};

  /// Keeps bag lines in sync after an edit, or drops them after a delete.
  void sync(Product product, {bool deleted = false}) {
    final id = product.id;
    if (id == null || !state.containsKey(id)) return;
    if (deleted) {
      remove(id);
      return;
    }
    final qty = state[id]!.quantity.clamp(0, product.stock);
    state = qty == 0
        ? ({...state}..remove(id))
        : {...state, id: BagLine(product, qty)};
  }
}
