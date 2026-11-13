import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../state/bag_controller.dart';
import '../state/shop_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/bag_sheet.dart';
import '../widgets/filter_panel.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/product_form.dart';
import '../widgets/shop_hero.dart';
import 'product_detail_screen.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _scroll = ScrollController();
  final _resultsKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    await ref.read(shopControllerProvider.notifier).goToPage(page);
    final ctx = _resultsKey.currentContext;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: FilterPanel(),
      ),
    );
  }

  void _addToBag(Product p) {
    ref.read(bagProvider.notifier).add(p);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${p.name} added to bag'),
        action: SnackBarAction(label: 'VIEW', textColor: AppColors.accent, onPressed: () => showBag(context)),
      ));
  }

  Future<void> _openProduct(Product p) async {
    final message = await Navigator.of(context).push<String>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, _, _) => ProductDetailScreen(product: p),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _createProduct() async {
    final saved = await showProductForm(context);
    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${saved.name} added to the catalogue')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopControllerProvider);
    final bagCount = ref.watch(bagProvider.select((b) => b.values.fold(0, (s, l) => s + l.quantity)));
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1100;

    final content = RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => ref.read(shopControllerProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ShopHero(
              total: state.total,
              filtered: state.filter.isActive,
              priceLabel: priceRangeLabel(state.bounds?.min, state.bounds?.max),
            ),
          ),
          SliverToBoxAdapter(child: _resultsHeader(state, wide)),
          ..._body(state),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
              child: Text(
                'FACET STUDIO STORE — CS ELECTIVE 2 · SUPABASE × FLUTTER',
                textAlign: TextAlign.center,
                style: monoLabel(size: 10),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FACET', style: displayStyle(26).copyWith(letterSpacing: -0.5)),
            const SizedBox(width: 6),
            Container(width: 9, height: 9, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
          ],
        ),
        actions: [
          if (!wide)
            IconButton(
              tooltip: 'Filters',
              onPressed: _openFilters,
              icon: Badge(
                isLabelVisible: state.filter.isActive,
                backgroundColor: AppColors.accent,
                smallSize: 8,
                child: const Icon(Icons.tune_rounded),
              ),
            ),
          IconButton(
            tooltip: 'Bag',
            onPressed: () => showBag(context),
            icon: Badge.count(
              count: bagCount,
              isLabelVisible: bagCount > 0,
              backgroundColor: AppColors.accent,
              textColor: Colors.black,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: width < 480
                ? IconButton.filled(tooltip: 'New object', onPressed: _createProduct, icon: const Icon(Icons.add_rounded))
                : FilledButton.icon(
                    onPressed: _createProduct,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New object'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                  ),
          ),
        ],
      ),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 310,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: const FilterPanel(),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  Widget _resultsHeader(ShopState state, bool wide) {
    return Padding(
      key: _resultsKey,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('THE CATALOGUE', style: monoLabel(color: AppColors.text)),
              const Spacer(),
              if (state.total > 0)
                Text(
                  '${state.firstShown}–${state.lastShown} of ${state.total} · page ${state.page + 1}/${state.pageCount}',
                  style: monoLabel(size: 10.5),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 2,
              child: state.loading
                  ? const LinearProgressIndicator(color: AppColors.accent, backgroundColor: AppColors.line)
                  : const ColoredBox(color: AppColors.line),
            ),
          ),
          if (state.error != null && state.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(describeError(state.error!), style: const TextStyle(color: AppColors.danger)),
            ),
        ],
      ),
    );
  }

  List<Widget> _body(ShopState state) {
    if (!state.loadedOnce) {
      return const [
        SliverToBoxAdapter(
          child: SizedBox(height: 320, child: Center(child: CircularProgressIndicator(color: AppColors.accent))),
        ),
      ];
    }
    if (state.items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _Message(
            title: state.error != null ? 'Couldn’t load the catalogue' : 'Nothing in that range',
            body: state.error != null
                ? describeError(state.error!)
                : state.filter.isActive
                    ? 'No objects match these filters. Widen the price range or reset the filters.'
                    : 'The products table is empty. Run supabase/seed.sql, or add your first object.',
            actionLabel: state.error != null ? 'Try again' : (state.filter.isActive ? 'Reset filters' : 'New object'),
            onAction: state.error != null
                ? () => ref.read(shopControllerProvider.notifier).refresh()
                : state.filter.isActive
                    ? () => ref.read(shopControllerProvider.notifier).resetFilters()
                    : _createProduct,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.crossAxisExtent;
            final columns = w >= 1000 ? 4 : (w >= 700 ? 3 : 2);
            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: w < 500 ? 0.72 : 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: state.items.length,
                (context, i) {
                  final p = state.items[i];
                  return AnimatedOpacity(
                    key: ValueKey(p.id),
                    opacity: state.loading ? 0.4 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: ProductCard(
                      product: p,
                      onOpen: () => _openProduct(p),
                      onAddToBag: () => _addToBag(p),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 28),
          child: PaginationBar(
            page: state.page,
            pageCount: state.pageCount,
            enabled: !state.loading,
            onPage: _goToPage,
          ),
        ),
      ),
    ];
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body, required this.actionLabel, required this.onAction});

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: displayStyle(30)),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.5)),
          ),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
