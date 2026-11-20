import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/product_repository.dart';
import '../models/product.dart';
import 'shop_filter.dart';

/// Products per page (the activity asks for 6–8).
const kPageSize = 8;

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => SupabaseProductRepository(Supabase.instance.client),
);

final shopControllerProvider =
    NotifierProvider<ShopController, ShopState>(ShopController.new);

class ShopState {
  const ShopState({
    this.items = const [],
    this.total = 0,
    this.page = 0,
    this.filter = const ShopFilter(),
    this.bounds,
    this.categories = const [],
    this.loading = false,
    this.loadedOnce = false,
    this.error,
  });

  final List<Product> items;

  /// Rows matching the current filter, across all pages.
  final int total;

  /// Zero-based page index.
  final int page;
  final ShopFilter filter;
  final PriceBounds? bounds;
  final List<String> categories;
  final bool loading;
  final bool loadedOnce;
  final Object? error;

  int get pageCount => math.max(1, (total / kPageSize).ceil());
  bool get hasPrevious => page > 0;
  bool get hasNext => page < pageCount - 1;
  int get firstShown => total == 0 ? 0 : page * kPageSize + 1;
  int get lastShown => math.min(total, (page + 1) * kPageSize);

  ShopState copyWith({
    List<Product>? items,
    int? total,
    int? page,
    ShopFilter? filter,
    PriceBounds? bounds,
    List<String>? categories,
    bool? loading,
    bool? loadedOnce,
    Object? error,
    bool clearError = false,
  }) =>
      ShopState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        filter: filter ?? this.filter,
        bounds: bounds ?? this.bounds,
        categories: categories ?? this.categories,
        loading: loading ?? this.loading,
        loadedOnce: loadedOnce ?? this.loadedOnce,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Owns the catalogue: every filter or page change becomes a new Supabase
/// query, and the UI only renders whatever page is in [state].
class ShopController extends Notifier<ShopState> {
  int _requestId = 0;

  ProductRepository get _repo => ref.read(productRepositoryProvider);

  @override
  ShopState build() {
    Future.microtask(refresh);
    return const ShopState(loading: true);
  }

  /// Reloads slider bounds, categories and the current page.
  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final results = await Future.wait<Object?>([
        _repo.fetchPriceBounds(),
        _repo.fetchCategories(),
      ]);
      final bounds = results[0] as PriceBounds?;
      final categories = results[1]! as List<String>;
      if (!ref.mounted) return;
      state = ShopState(
        items: state.items,
        total: state.total,
        page: state.page,
        filter: _clampFilter(state.filter, bounds),
        bounds: bounds,
        categories: categories,
        loading: true,
        loadedOnce: state.loadedOnce,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, loadedOnce: true, error: e);
      return;
    }
    await _load(state.page);
  }

  Future<void> goToPage(int page) {
    final target = page.clamp(0, state.pageCount - 1);
    if (target == state.page && state.loadedOnce) return Future.value();
    return _load(target);
  }

  Future<void> nextPage() => goToPage(state.page + 1);

  Future<void> previousPage() => goToPage(state.page - 1);

  Future<void> setSearch(String search) {
    if (search.trim() == state.filter.search.trim()) return Future.value();
    return _applyFilter(state.filter.copyWith(search: search));
  }

  Future<void> setCategory(String? category) =>
      _applyFilter(state.filter.copyWith(category: () => category));

  Future<void> setSort(ShopSort sort) =>
      _applyFilter(state.filter.copyWith(sort: sort));

  /// Pass the slider's ends; a value at the catalogue's own min/max is
  /// treated as "no limit" so newly added products aren't hidden.
  Future<void> setPriceRange(double min, double max) {
    final b = state.bounds;
    final lo = b == null || min > b.min ? min : null;
    final hi = b == null || max < b.max ? max : null;
    return _applyFilter(
      state.filter.copyWith(minPrice: () => lo, maxPrice: () => hi),
    );
  }

  Future<void> resetFilters() =>
      _applyFilter(ShopFilter(sort: state.filter.sort));

  Future<Product> create(Product product) async {
    final saved = await _repo.create(product);
    await refresh();
    return saved;
  }

  Future<Product> update(Product product) async {
    final saved = await _repo.update(product);
    await refresh();
    return saved;
  }

  Future<void> delete(Product product) async {
    await _repo.delete(product.id!);
    await refresh();
  }

  /// Uploads a product photo and returns its public URL.
  Future<String> uploadImage(Uint8List bytes, {required String extension}) =>
      _repo.uploadImage(bytes, extension: extension);

  Future<void> addCategory(String name) async {
    await _repo.addCategory(name);
    await refresh();
  }

  Future<void> renameCategory(String from, String to) async {
    await _repo.renameCategory(from, to);
    if (state.filter.category == from) state = state.copyWith(filter: state.filter.copyWith(category: () => to));
    await refresh();
  }

  Future<void> deleteCategory(String name) async {
    await _repo.deleteCategory(name);
    if (state.filter.category == name) state = state.copyWith(filter: state.filter.copyWith(category: () => null));
    await refresh();
  }

  Future<void> _applyFilter(ShopFilter filter) {
    state = state.copyWith(filter: filter);
    return _load(0);
  }

  Future<void> _load(int page) async {
    final requestId = ++_requestId;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final (result, shownPage) = await _fetchClamped(page);
      if (!ref.mounted || requestId != _requestId) return;
      state = state.copyWith(
        items: result.items,
        total: result.total,
        page: shownPage,
        loading: false,
        loadedOnce: true,
      );
    } catch (e) {
      if (!ref.mounted || requestId != _requestId) return;
      state = state.copyWith(loading: false, loadedOnce: true, error: e);
    }
  }

  /// Fetches [page]; if it no longer exists (e.g. the last item on the last
  /// page was deleted) falls back to the new last page.
  Future<(ProductPage, int)> _fetchClamped(int page) async {
    try {
      final result = await _repo.fetchPage(
        filter: state.filter,
        page: page,
        pageSize: kPageSize,
      );
      if (result.items.isNotEmpty || page == 0) return (result, page);
      return _fetchLastPage(result.total);
    } on PostgrestException catch (e) {
      // PGRST103: "Requested range not satisfiable" (offset past the end).
      if (e.code != 'PGRST103' || page == 0) rethrow;
      final first = await _repo.fetchPage(
        filter: state.filter,
        page: 0,
        pageSize: kPageSize,
      );
      return _fetchLastPage(first.total);
    }
  }

  Future<(ProductPage, int)> _fetchLastPage(int total) async {
    final last = math.max(0, (total / kPageSize).ceil() - 1);
    final result = await _repo.fetchPage(
      filter: state.filter,
      page: last,
      pageSize: kPageSize,
    );
    return (result, last);
  }

  /// Keeps an active price filter inside the catalogue's current bounds.
  ShopFilter _clampFilter(ShopFilter f, PriceBounds? b) {
    if (b == null) return f.copyWith(minPrice: () => null, maxPrice: () => null);
    double? clampOrNull(double? v) {
      if (v == null) return null;
      if (v <= b.min || v >= b.max) return null;
      return v;
    }

    return f.copyWith(
      minPrice: () => clampOrNull(f.minPrice),
      maxPrice: () => clampOrNull(f.maxPrice),
    );
  }
}
