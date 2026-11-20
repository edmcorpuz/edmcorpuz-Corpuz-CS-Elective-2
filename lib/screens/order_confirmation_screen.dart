import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'orders_screen.dart';

/// Shown right after checkout: the order number and total from the database.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 40, color: AppColors.accent),
                ),
                const SizedBox(height: 24),
                Text('Order placed', style: displayStyle(40), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text(
                  'Thanks! Your order is saved and the stock has been set aside for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 28),
                _Fact(label: 'ORDER NUMBER', value: '#${order.id}'),
                _Fact(label: 'TOTAL', value: formatPeso(order.total)),
                _Fact(label: 'STATUS', value: order.status.toUpperCase()),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(builder: (_) => const OrdersScreen()),
                  ),
                  child: const Text('See my orders'),
                ),
                const SizedBox(height: 10),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Keep shopping')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Text(label, style: monoLabel(size: 10)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}
