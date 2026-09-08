import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/product_data.dart';
import '../models/product.dart';
import '../state/theme_controller.dart';
import '../widgets/cart_button.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;
  String _query = '';
  String _selectedCategory = 'All';
  _FilterOptions _filters = const _FilterOptions();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _columnsForWidth(double width) {
    if (width >= 1100) return 4;
    if (width >= 650) return 3;
    return 2;
  }

  List<Product> get _visibleProducts {
    final query = _query.trim().toLowerCase();
    final filtered = products.where((product) {
      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesBrand =
          _filters.brand == null || product.brand == _filters.brand;
      final matchesPrice = product.price <= _filters.maxPrice;
      final matchesRating = product.rating >= _filters.minRating;
      final matchesSale = !_filters.onlyOnSale || product.discountPercent > 0;
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      return matchesCategory &&
          matchesBrand &&
          matchesPrice &&
          matchesRating &&
          matchesSale &&
          matchesSearch;
    }).toList();

    switch (_filters.sortBy) {
      case 'Price: low to high':
        filtered.sort((a, b) => a.price.compareTo(b.price));
      case 'Price: high to low':
        filtered.sort((a, b) => b.price.compareTo(a.price));
      case 'Top rated':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
      case 'Best selling':
        filtered.sort((a, b) => b.sold.compareTo(a.sold));
    }
    return filtered;
  }

  int get _activeFilterCount => [
        _filters.brand != null,
        _filters.maxPrice < _FilterOptions.maxCatalogPrice,
        _filters.minRating > 0,
        _filters.onlyOnSale,
        _filters.sortBy != 'Featured',
      ].where((active) => active).length;

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
  }

  Future<void> _openFilters() async {
    final brands = {for (final product in products) product.brand}.toList()..sort();
    final result = await showModalBottomSheet<_FilterOptions>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _FilterSheet(
        initial: _filters,
        brands: brands,
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...{for (final product in products) product.category}];
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeHub'),
        actions: [
          const ThemeToggleButton(),
          const CartButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = _columnsForWidth(constraints.maxWidth);
          final visibleProducts = _visibleProducts;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search appliances, brands, and more',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_query.isNotEmpty)
                          IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        Badge(
                          isLabelVisible: _activeFilterCount > 0,
                          label: Text('$_activeFilterCount'),
                          child: IconButton(
                            tooltip: 'Open filters',
                            onPressed: _openFilters,
                            icon: const Icon(Icons.tune_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const _PromoCarousel(compact: true),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${visibleProducts.length} products',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: category == _selectedCategory,
                      onSelected: (_) => _selectCategory(category),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    const _PulsingSaleDot(),
                    const SizedBox(width: 8),
                    Text(
                      'Flash sale',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      'Ends soon · Free delivery',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleProducts.isEmpty
                    ? _NoResults(query: _query)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: columns == 2 ? 0.72 : 0.82,
                        ),
                        itemCount: visibleProducts.length,
                        itemBuilder: (context, index) {
                          final product = visibleProducts[index];
                          return ProductCard(
                            product: product,
                            animationIndex: index,
                            onTap: () => context.pushNamed(
                              'productDetail',
                              pathParameters: {'id': product.id},
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterOptions {
  static const maxCatalogPrice = 500.0;

  final String? brand;
  final double maxPrice;
  final double minRating;
  final bool onlyOnSale;
  final String sortBy;

  const _FilterOptions({
    this.brand,
    this.maxPrice = maxCatalogPrice,
    this.minRating = 0,
    this.onlyOnSale = false,
    this.sortBy = 'Featured',
  });
}

class _FilterSheet extends StatefulWidget {
  final _FilterOptions initial;
  final List<String> brands;

  const _FilterSheet({required this.initial, required this.brands});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _brand = widget.initial.brand;
  late double _maxPrice = widget.initial.maxPrice;
  late double _minRating = widget.initial.minRating;
  late bool _onlyOnSale = widget.initial.onlyOnSale;
  late String _sortBy = widget.initial.sortBy;

  void _reset() {
    setState(() {
      _brand = null;
      _maxPrice = _FilterOptions.maxCatalogPrice;
      _minRating = 0;
      _onlyOnSale = false;
      _sortBy = 'Featured';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter products', style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                    tooltip: 'Close filters',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text('Brand', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Any brand'),
                    selected: _brand == null,
                    onSelected: (_) => setState(() => _brand = null),
                  ),
                  ...widget.brands.map(
                    (brand) => ChoiceChip(
                      label: Text(brand),
                      selected: _brand == brand,
                      onSelected: (_) => setState(() => _brand = brand),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Maximum price: ${formatProductPrice(_maxPrice)}',
                  style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: _maxPrice,
                min: 25,
                max: _FilterOptions.maxCatalogPrice,
                divisions: 19,
                label: formatProductPrice(_maxPrice),
                onChanged: (value) => setState(() => _maxPrice = value),
              ),
              Text('Minimum rating', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final rating in [0.0, 4.5, 4.7, 4.9])
                    ChoiceChip(
                      label: Text(rating == 0 ? 'Any' : '$rating+ stars'),
                      selected: _minRating == rating,
                      onSelected: (_) => setState(() => _minRating = rating),
                    ),
                ],
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('On sale only'),
                subtitle: const Text('Show products with a discount'),
                value: _onlyOnSale,
                onChanged: (value) => setState(() => _onlyOnSale = value),
              ),
              DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: const InputDecoration(labelText: 'Sort by'),
                items: const [
                  DropdownMenuItem(value: 'Featured', child: Text('Featured')),
                  DropdownMenuItem(value: 'Price: low to high', child: Text('Price: low to high')),
                  DropdownMenuItem(value: 'Price: high to low', child: Text('Price: high to low')),
                  DropdownMenuItem(value: 'Top rated', child: Text('Top rated')),
                  DropdownMenuItem(value: 'Best selling', child: Text('Best selling')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _sortBy = value);
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        _FilterOptions(
                          brand: _brand,
                          maxPrice: _maxPrice,
                          minRating: _minRating,
                          onlyOnSale: _onlyOnSale,
                          sortBy: _sortBy,
                        ),
                      ),
                      icon: Icon(Icons.check_rounded, color: colors.onPrimary),
                      label: const Text('Apply filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();
  late final AnimationController _radiateController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void dispose() {
    _radiateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, child) {
        final isDark = mode == ThemeMode.dark;
        return SizedBox(
          key: _buttonKey,
          width: 48,
          height: 48,
          child: IconButton(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: () async {
              final renderBox =
                  _buttonKey.currentContext?.findRenderObject() as RenderBox?;
              final origin = renderBox?.localToGlobal(
                renderBox.size.center(Offset.zero),
              );
              // Start the button animation immediately while the old page is
              // captured, then reveal the new theme from the same origin.
              _radiateController.forward(from: 0);
              await themeController.toggle(origin: origin);
            },
            icon: AnimatedBuilder(
            animation: _radiateController,
            builder: (context, child) {
              final progress = Curves.easeOutCubic.transform(_radiateController.value);
              final color = Theme.of(context).colorScheme.primary;
              return SizedBox(
                width: 28,
                height: 28,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    for (var ring = 0; ring < 3; ring++)
                      Transform.scale(
                        scale: 0.8 + progress * (1.1 + ring * 0.45),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(
                                alpha: ((1 - progress) * (0.28 - ring * 0.06))
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                              ),
                            ),
                          ),
                          child: const SizedBox(width: 20, height: 20),
                        ),
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      transitionBuilder: (child, animation) => RotationTransition(
                        turns: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        key: ValueKey(isDark),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      },
    );
  }
}

class _PromoCarousel extends StatefulWidget {
  final bool compact;

  const _PromoCarousel({this.compact = false});

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const promos = [
    (
      title: 'Home refresh week',
      subtitle: 'Save up to 30% on kitchen essentials',
      icon: Icons.auto_awesome_rounded,
    ),
    (
      title: 'Smart living starts here',
      subtitle: 'Better appliances, happier routines',
      icon: Icons.lightbulb_outline_rounded,
    ),
    (
      title: 'Free delivery today',
      subtitle: 'On selected HomeHub appliances',
      icon: Icons.local_shipping_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: widget.compact ? 88 : 142,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: promos.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                final promo = promos[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    widget.compact ? 4 : 8,
                    20,
                    widget.compact ? 2 : 4,
                  ),
                  child: Card(
                    color: index.isEven
                        ? colors.primaryContainer
                        : colors.tertiaryContainer,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.compact ? 16 : 22,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  promo.title,
                                  style: (widget.compact
                                          ? Theme.of(context).textTheme.titleMedium
                                          : Theme.of(context).textTheme.titleLarge)
                                      ?.copyWith(
                                        color: index.isEven
                                            ? colors.onPrimaryContainer
                                            : colors.onTertiaryContainer,
                                      ),
                                ),
                                SizedBox(height: widget.compact ? 2 : 5),
                                Text(
                                  promo.subtitle,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: index.isEven
                                        ? colors.onPrimaryContainer
                                        : colors.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: _page == index ? 0.04 : 0,
                            duration: const Duration(milliseconds: 400),
                            child: Icon(
                              promo.icon,
                              size: widget.compact ? 34 : 48,
                              color: index.isEven
                                  ? colors.onPrimaryContainer
                                  : colors.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              promos.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page == index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _page == index ? colors.primary : colors.outlineVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingSaleDot extends StatefulWidget {
  const _PulsingSaleDot();

  @override
  State<_PulsingSaleDot> createState() => _PulsingSaleDotState();
}

class _PulsingSaleDotState extends State<_PulsingSaleDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.2).animate(_controller),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          shape: BoxShape.circle,
        ),
        child: const SizedBox(width: 10, height: 10),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;

  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 52),
            const SizedBox(height: 12),
            Text(
              query.isEmpty
                  ? 'No appliances in this category yet'
                  : 'No appliances found for "$query"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text('Try another search or choose All categories.'),
          ],
        ),
      ),
    );
  }
}
