import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../state/account_controller.dart';
import '../state/orders_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/product_form.dart' show describeError;

/// Customers: their own order history. Admins: every order, with a status
/// control. Same query for both; Row Level Security decides which rows come
/// back.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(accountProvider.select((a) => a.isAdmin));
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'All orders' : 'My orders', style: displayStyle(24)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(ordersProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: switch (orders) {
        AsyncValue(:final value?, :final isLoading) when value.isNotEmpty => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                children: [
                  if (isLoading) const LinearProgressIndicator(color: AppColors.accent, minHeight: 2),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: value.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _OrderCard(order: value[i], isAdmin: isAdmin),
                    ),
                  ),
                ],
              ),
            ),
          ),
        AsyncValue(:final error?) => _Message(
            icon: Icons.error_outline_rounded,
            title: 'Couldn’t load orders',
            body: describeError(error),
            action: 'Try again',
            onAction: () => ref.read(ordersProvider.notifier).refresh(),
          ),
        AsyncValue(:final value?) when value.isEmpty => _Message(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            body: isAdmin ? 'Orders appear here as soon as customers check out.' : 'Your orders appear here after checkout.',
            action: isAdmin ? 'Refresh' : 'Back to the shop',
            onAction: isAdmin ? () => ref.read(ordersProvider.notifier).refresh() : () => Navigator.of(context).pop(),
          ),
        _ => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      },
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.order, required this.isAdmin});

  final Order order;
  final bool isAdmin;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _saving = false;

  Future<void> _setStatus(String status) async {
    setState(() => _saving = true);
    try {
      await ref.read(ordersProvider.notifier).setStatus(widget.order.id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order #${widget.order.id} marked $status')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Order #${o.id}', style: displayStyle(20)),
              const SizedBox(width: 12),
              if (widget.isAdmin)
                _saving
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : DropdownButton<String>(
                        value: o.status,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(12),
                        items: [
                          for (final s in Order.statuses)
                            DropdownMenuItem(value: s, child: _StatusChip(status: s)),
                        ],
                        onChanged: (s) => s == null || s == o.status ? null : _setStatus(s),
                      )
              else
                _StatusChip(status: o.status),
              const Spacer(),
              Text(formatPeso(o.total), style: displayStyle(20)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              formatOrderDate(o.createdAt),
              '${o.itemCount} ${o.itemCount == 1 ? 'item' : 'items'}',
              if (widget.isAdmin) o.customerName ?? o.customerEmail ?? 'Unknown customer',
            ].join(' · '),
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          for (final item in o.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text('${item.quantity} × ${item.productName}')),
                  Text('${formatPeso(item.unitPrice)} each', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 90,
                    child: Text(formatPeso(item.subtotal), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'done' || 'shipped' => AppColors.accent,
      'cancelled' => AppColors.danger,
      _ => AppColors.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(status.toUpperCase(), style: monoLabel(size: 9.5, color: color)),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body, required this.action, required this.onAction});

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(title, style: displayStyle(26), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.5)),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Nov 20, 2026 · 2:05 PM" without pulling in the intl package.
String formatOrderDate(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  return '${_months[d.month - 1]} ${d.day}, ${d.year} · $hour:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
}
