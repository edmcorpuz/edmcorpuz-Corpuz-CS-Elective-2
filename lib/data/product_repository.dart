import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../state/shop_filter.dart';

/// Lowest and highest price in the whole catalogue (drives the slider).
class PriceBounds {
  const PriceBounds(this.min, this.max);

  final double min;
  final double max;
}

/// One page of results plus the total number of rows matching the filter.
class ProductPage {
  const ProductPage(this.items, this.total);

  final List<Product> items;
  final int total;
}

abstract interface class ProductRepository {
  Future<ProductPage> fetchPage({
    required ShopFilter filter,
    required int page,
    required int pageSize,
  });

  Future<PriceBounds?> fetchPriceBounds();

  Future<List<String>> fetchCategories();

  Future<Product> create(Product product);

  Future<Product> update(Product product);

  Future<void> delete(int id);
}

class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository(this._client);

  final SupabaseClient _client;

  static const table = 'products';

  /// Filtering, sorting and pagination all happen in Postgres:
  /// `.gte/.lte` for the price slider, `.range()` for the page window and
  /// `count(CountOption.exact)` for the total used by the page buttons.
  @override
  Future<ProductPage> fetchPage({
    required ShopFilter filter,
    required int page,
    required int pageSize,
  }) async {
    var query = _client.from(table).select();

    final search = sanitizeSearch(filter.search);
    if (search.isNotEmpty) query = query.ilike('name', '%$search%');
    if (filter.category != null) query = query.eq('category', filter.category!);
    if (filter.minPrice != null) query = query.gte('price', filter.minPrice!);
    if (filter.maxPrice != null) query = query.lte('price', filter.maxPrice!);

    final ordered = switch (filter.sort) {
      ShopSort.newest => query
          .order('created_at', ascending: false)
          .order('id', ascending: false),
      ShopSort.priceLow =>
        query.order('price', ascending: true).order('id', ascending: true),
      ShopSort.priceHigh =>
        query.order('price', ascending: false).order('id', ascending: false),
    };

    final from = page * pageSize;
    final response =
        await ordered.range(from, from + pageSize - 1).count(CountOption.exact);

    return ProductPage(
      response.data.map(Product.fromMap).toList(),
      response.count,
    );
  }

  @override
  Future<PriceBounds?> fetchPriceBounds() async {
    final results = await Future.wait([
      _client.from(table).select('price').order('price').limit(1).maybeSingle(),
      _client
          .from(table)
          .select('price')
          .order('price', ascending: false)
          .limit(1)
          .maybeSingle(),
    ]);
    final low = results[0], high = results[1];
    if (low == null || high == null) return null;
    return PriceBounds(
      (low['price'] as num).toDouble(),
      (high['price'] as num).toDouble(),
    );
  }

  @override
  Future<List<String>> fetchCategories() async {
    final rows = await _client.from(table).select('category');
    final names = {for (final r in rows) r['category'] as String}.toList()
      ..sort();
    return names;
  }

  @override
  Future<Product> create(Product product) async {
    final row = await _client
        .from(table)
        .insert(product.toWriteMap())
        .select()
        .single();
    return Product.fromMap(row);
  }

  @override
  Future<Product> update(Product product) async {
    final row = await _client
        .from(table)
        .update(product.toWriteMap())
        .eq('id', product.id!)
        .select()
        .single();
    return Product.fromMap(row);
  }

  @override
  Future<void> delete(int id) async {
    await _client.from(table).delete().eq('id', id);
  }

  /// Strips LIKE wildcards so a search for "50%" can't match everything.
  static String sanitizeSearch(String input) =>
      input.replaceAll(RegExp(r'[%_*\\]'), '').trim();
}
