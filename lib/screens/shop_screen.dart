import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../state/account_controller.dart';
import '../state/bag_controller.dart';
import '../state/shop_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/account_avatar.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/facet_logo.dart';
import '../widgets/filter_panel.dart';
import '../widgets/filter_sidebar.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/product_form.dart';
import '../widgets/shop_hero.dart';
import '../widgets/theme_toggle.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'orders_screen.dart';
import 'product_detail_screen.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _scroll = ScrollController();
  final _resultsKey = GlobalKey();
  bool _panelOpen = true;

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
        content: Text('${p.name} added to cart'),
        // Action snackbars stay up by default; this one would cover Checkout.
        persist: false,
        action: SnackBarAction(label: 'VIEW CART', onPressed: () => _open(const CartScreen())),
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

  Future<void> _editProduct(Product p) async {
    final saved = await showProductForm(context, initial: p);
    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${saved.name} saved')));
    }
  }

  Future<void> _deleteProduct(Product p) async {
    final ok = await confirmDelete(
      context,
      p.name,
      'This removes the product from the catalogue. Past orders keep their own copy of its name and price.',
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(shopControllerProvider.notifier).delete(p);
      messenger.showSnackBar(SnackBar(content: Text('${p.name} deleted')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
    }
  }

  void _open(Widget screen) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _signOut() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountProvider.notifier).signOut();
      messenger.showSnackBar(const SnackBar(content: Text('Signed out')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
    }
  }

  Widget _accountActions(AccountState account, int cartCount) {
    final user = account.user!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (account.isAdmin) ...[
          IconButton(
            tooltip: 'Categories',
            onPressed: () => _open(const CategoriesScreen()),
            icon: const Icon(Icons.category_outlined),
          ),
          IconButton(
            tooltip: 'All orders',
            onPressed: () => _open(const OrdersScreen()),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ] else ...[
          IconButton(
            tooltip: 'My orders',
            onPressed: () => _open(const OrdersScreen()),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: 'Cart',
            onPressed: () => _open(const CartScreen()),
            icon: Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              backgroundColor: AppColors.accent,
              textColor: AppColors.onAccent,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ],
        const SizedBox(width: 6),
        PopupMenuButton<void>(
          tooltip: 'Your account',
          icon: AccountAvatar(user: user, admin: account.isAdmin),
          itemBuilder: (_) => [
            PopupMenuItem<void>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.isAdmin ? 'ADMIN · VIA ${user.providerLabel.toUpperCase()}' : 'SIGNED IN VIA ${user.providerLabel.toUpperCase()}',
                    style: monoLabel(size: 9.5, color: account.isAdmin ? AppColors.accent : AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(user.displayName, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                  if (user.email != null && user.email != user.displayName)
                    Text(user.email!, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<void>(
              onTap: _signOut,
              child: const Row(
                children: [Icon(Icons.logout_rounded, size: 18), SizedBox(width: 10), Text('Sign out')],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopControllerProvider);
    final account = ref.watch(accountProvider);
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
          ..._body(state, isAdmin: account.isAdmin),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
              child: Text(
                'FACET HOME APPLIANCES · CS ELECTIVE 2 · SUPABASE × FLUTTER',
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
        // Phones: the mark alone, so the wordmark doesn't collide with the actions.
        title: FacetLogo(size: 28, showWordmark: width >= 520),
        actions: [
          const ThemeToggle(),
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _accountActions(account, bagCount),
          ),
        ],
      ),
      floatingActionButton: account.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _createProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            )
          : null,
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilterSidebar(
                  open: _panelOpen,
                  onToggle: () => setState(() => _panelOpen = !_panelOpen),
                ),
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
                  ? LinearProgressIndicator(color: AppColors.accent, backgroundColor: AppColors.line)
                  : ColoredBox(color: AppColors.line),
            ),
          ),
          if (state.error != null && state.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(describeError(state.error!), style: TextStyle(color: AppColors.danger)),
            ),
        ],
      ),
    );
  }

  List<Widget> _body(ShopState state, {required bool isAdmin}) {
    if (!state.loadedOnce) {
      return [
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
                    ? 'No appliances match these filters. Widen the price range or reset the filters.'
                    : isAdmin
                        ? 'The products table is empty. Run supabase/seed.sql, or add your first appliance.'
                        : 'The catalogue is empty right now. Check back soon.',
            actionLabel: state.error != null
                ? 'Try again'
                : state.filter.isActive
                    ? 'Reset filters'
                    : (isAdmin ? 'New appliance' : 'Refresh'),
            onAction: state.error != null
                ? () => ref.read(shopControllerProvider.notifier).refresh()
                : state.filter.isActive
                    ? () => ref.read(shopControllerProvider.notifier).resetFilters()
                    : isAdmin
                        ? _createProduct
                        : () => ref.read(shopControllerProvider.notifier).refresh(),
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
                      onAddToBag: isAdmin ? null : () => _addToBag(p),
                      onEdit: isAdmin ? () => _editProduct(p) : null,
                      onDelete: isAdmin ? () => _deleteProduct(p) : null,
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
            child: Text(body, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, height: 1.5)),
          ),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
