import 'dart:typed_data';

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

  Future<void> addCategory(String name);

  /// Products follow automatically (the foreign key cascades the rename).
  Future<void> renameCategory(String from, String to);

  /// Fails while products still use the category.
  Future<void> deleteCategory(String name);

  /// Uploads a product photo to Supabase Storage and returns its public URL.
  Future<String> uploadImage(Uint8List bytes, {required String extension});
}

class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository(this._client);

  final SupabaseClient _client;

  static const table = 'products';

  /// Products point at categories by id; the app works with category names,
  /// so every read joins the name in and every write looks the id up.
  static const _select = '*, categories!inner(name)';
  final Map<String, int> _categoryIds = {};

  Future<int> _categoryId(String name) async {
    final cached = _categoryIds[name];
    if (cached != null) return cached;
    final row = await _client.from('categories').select('id').eq('name', name).single();
    return _categoryIds[name] = (row['id'] as num).toInt();
  }

  Future<Map<String, dynamic>> _writeMap(Product p) async =>
      {...p.toWriteMap(), 'category_id': await _categoryId(p.category)};

  /// Filtering, sorting and pagination all happen in Postgres:
  /// `.gte/.lte` for the price slider, `.range()` for the page window and
  /// `count(CountOption.exact)` for the total used by the page buttons.
  @override
  Future<ProductPage> fetchPage({
    required ShopFilter filter,
    required int page,
    required int pageSize,
  }) async {
    var query = _client.from(table).select(_select);

    final search = sanitizeSearch(filter.search);
    if (search.isNotEmpty) query = query.ilike('name', '%$search%');
    if (filter.category != null) query = query.eq('categories.name', filter.category!);
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
    // postgrest-dart's order() defaults to DESCENDING, so the cheapest-row
    // query must say ascending: true explicitly.
    final results = await Future.wait([
      _client
          .from(table)
          .select('price')
          .order('price', ascending: true)
          .limit(1)
          .maybeSingle(),
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
    final rows = await _client.from('categories').select('id, name').order('name');
    _categoryIds
      ..clear()
      ..addAll({for (final r in rows) r['name'] as String: (r['id'] as num).toInt()});
    return [for (final r in rows) r['name'] as String];
  }

  @override
  Future<Product> create(Product product) async {
    final row = await _client
        .from(table)
        .insert(await _writeMap(product))
        .select(_select)
        .single();
    return Product.fromMap(row);
  }

  @override
  Future<Product> update(Product product) async {
    final row = await _client
        .from(table)
        .update(await _writeMap(product))
        .eq('id', product.id!)
        .select(_select)
        .single();
    return Product.fromMap(row);
  }

  @override
  Future<void> delete(int id) async {
    // Row Level Security makes a blocked delete match zero rows instead of
    // failing, so ask for the deleted ids and treat "none" as an error.
    final deleted = await _client.from(table).delete().eq('id', id).select('id');
    if (deleted.isEmpty) {
      throw const PostgrestException(message: 'No product was deleted', code: 'PGRST116');
    }
  }

  @override
  Future<void> addCategory(String name) async {
    await _client.from('categories').insert({'name': name.trim()});
  }

  @override
  Future<void> renameCategory(String from, String to) async {
    final updated = await _client.from('categories').update({'name': to.trim()}).eq('name', from).select('id');
    if (updated.isEmpty) throw const PostgrestException(message: 'No category was renamed', code: 'PGRST116');
  }

  @override
  Future<void> deleteCategory(String name) async {
    final deleted = await _client.from('categories').delete().eq('name', name).select('id');
    if (deleted.isEmpty) throw const PostgrestException(message: 'No category was deleted', code: 'PGRST116');
  }

  static const imageBucket = 'product-images';

  @override
  Future<String> uploadImage(Uint8List bytes, {required String extension}) async {
    final ext = extension.toLowerCase().replaceAll('jpeg', 'jpg');
    // A new name per upload, so browsers never show a cached old photo.
    final path = 'products/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await _client.storage.from(imageBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: ext == 'jpg' ? 'image/jpeg' : 'image/$ext'),
        );
    return _client.storage.from(imageBucket).getPublicUrl(path);
  }

  /// Strips LIKE wildcards so a search for "50%" can't match everything.
  static String sanitizeSearch(String input) =>
      input.replaceAll(RegExp(r'[%_*\\]'), '').trim();
}
