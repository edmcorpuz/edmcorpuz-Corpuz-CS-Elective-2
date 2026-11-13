import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unang_flutter_project/data/product_repository.dart';
import 'package:unang_flutter_project/models/product.dart';
import 'package:unang_flutter_project/state/shop_controller.dart';
import 'package:unang_flutter_project/state/shop_filter.dart';
import 'package:unang_flutter_project/three_d/shapes.dart';

/// In-memory stand-in for Supabase that applies the same filter/range rules.
class FakeRepository implements ProductRepository {
  FakeRepository(int count)
      : rows = [
          for (var i = 1; i <= count; i++)
            Product(
              id: i,
              name: 'Object $i',
              description: '',
              price: i * 100.0,
              category: i.isEven ? 'Even' : 'Odd',
              stock: 5,
              shape: ShapeKind.cube,
              colorHex: '#C8FF2E',
            ),
        ];

  final List<Product> rows;
  final List<int> requestedPages = [];

  @override
  Future<ProductPage> fetchPage({required ShopFilter filter, required int page, required int pageSize}) async {
    requestedPages.add(page);
    var matches = rows.where((p) {
      if (filter.category != null && p.category != filter.category) return false;
      if (filter.minPrice != null && p.price < filter.minPrice!) return false;
      if (filter.maxPrice != null && p.price > filter.maxPrice!) return false;
      final q = filter.search.trim().toLowerCase();
      return q.isEmpty || p.name.toLowerCase().contains(q);
    }).toList();
    if (filter.sort == ShopSort.priceHigh) matches = matches.reversed.toList();
    final from = page * pageSize;
    final items = from >= matches.length ? <Product>[] : matches.sublist(from, (from + pageSize).clamp(0, matches.length));
    return ProductPage(items, matches.length);
  }

  @override
  Future<PriceBounds?> fetchPriceBounds() async =>
      rows.isEmpty ? null : PriceBounds(rows.first.price, rows.last.price);

  @override
  Future<List<String>> fetchCategories() async => {for (final p in rows) p.category}.toList()..sort();

  @override
  Future<Product> create(Product product) async {
    final saved = product.copyWith(id: rows.length + 1);
    rows.add(saved);
    return saved;
  }

  @override
  Future<Product> update(Product product) async => product;

  @override
  Future<void> delete(int id) async => rows.removeWhere((p) => p.id == id);
}

Future<ProviderContainer> _start(FakeRepository repo) async {
  final container = ProviderContainer(overrides: [productRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(container.dispose);
  container.read(shopControllerProvider);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  test('first page shows $kPageSize of 20 products', () async {
    final c = await _start(FakeRepository(20));
    final s = c.read(shopControllerProvider);
    expect(s.items.length, kPageSize);
    expect(s.total, 20);
    expect(s.pageCount, 3);
    expect(s.firstShown, 1);
    expect(s.lastShown, 8);
  });

  test('next page loads rows 9-16 and last page holds the remainder', () async {
    final c = await _start(FakeRepository(20));
    final controller = c.read(shopControllerProvider.notifier);
    await controller.nextPage();
    expect(c.read(shopControllerProvider).items.first.name, 'Object 9');
    await controller.goToPage(2);
    final s = c.read(shopControllerProvider);
    expect(s.items.length, 4);
    expect(s.hasNext, isFalse);
  });

  test('price range filters the list and resets to page 1', () async {
    final c = await _start(FakeRepository(20));
    final controller = c.read(shopControllerProvider.notifier);
    await controller.goToPage(1);
    await controller.setPriceRange(500, 900);
    final s = c.read(shopControllerProvider);
    expect(s.page, 0);
    expect(s.items.map((p) => p.price), [500, 600, 700, 800, 900]);
    expect(s.filter.minPrice, 500);
    expect(s.filter.maxPrice, 900);
  });

  test('slider at the catalogue bounds means no price limit', () async {
    final c = await _start(FakeRepository(20));
    await c.read(shopControllerProvider.notifier).setPriceRange(0, 5000);
    final f = c.read(shopControllerProvider).filter;
    expect(f.minPrice, isNull);
    expect(f.maxPrice, isNull);
    expect(f.isActive, isFalse);
  });

  test('deleting the only item on the last page steps back a page', () async {
    final repo = FakeRepository(17);
    final c = await _start(repo);
    final controller = c.read(shopControllerProvider.notifier);
    await controller.goToPage(2);
    expect(c.read(shopControllerProvider).items.single.id, 17);
    await controller.delete(repo.rows.last);
    final s = c.read(shopControllerProvider);
    expect(s.page, 1);
    expect(s.total, 16);
    expect(s.items.length, kPageSize);
  });

  test('category + search combine', () async {
    final c = await _start(FakeRepository(20));
    final controller = c.read(shopControllerProvider.notifier);
    await controller.setCategory('Even');
    await controller.setSearch('Object 1');
    final names = c.read(shopControllerProvider).items.map((p) => p.name);
    expect(names, ['Object 10', 'Object 12', 'Object 14', 'Object 16', 'Object 18']);
  });

  test('formatPeso groups thousands', () {
    expect(formatPeso(18990), '₱18,990');
    expect(formatPeso(249), '₱249');
    expect(formatPeso(1234567.5), '₱1,234,567.50');
  });

  test('search input is stripped of LIKE wildcards', () {
    expect(SupabaseProductRepository.sanitizeSearch(' 50%_off* '), '50off');
  });
}
