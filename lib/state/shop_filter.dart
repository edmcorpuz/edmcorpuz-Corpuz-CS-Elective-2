import 'package:flutter/foundation.dart';

enum ShopSort {
  newest('Newest'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low');

  const ShopSort(this.label);

  final String label;
}

/// Everything the customer can narrow the catalogue by. A null price bound
/// means "no limit on that side".
@immutable
class ShopFilter {
  const ShopFilter({
    this.search = '',
    this.category,
    this.minPrice,
    this.maxPrice,
    this.sort = ShopSort.newest,
  });

  final String search;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final ShopSort sort;

  bool get isActive =>
      search.trim().isNotEmpty ||
      category != null ||
      minPrice != null ||
      maxPrice != null;

  ShopFilter copyWith({
    String? search,
    ValueGetter<String?>? category,
    ValueGetter<double?>? minPrice,
    ValueGetter<double?>? maxPrice,
    ShopSort? sort,
  }) =>
      ShopFilter(
        search: search ?? this.search,
        category: category != null ? category() : this.category,
        minPrice: minPrice != null ? minPrice() : this.minPrice,
        maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
        sort: sort ?? this.sort,
      );
}
