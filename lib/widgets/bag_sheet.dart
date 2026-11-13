import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../state/bag_controller.dart';
import '../theme/app_theme.dart';
import '../three_d/spinning_mesh.dart';

void showBag(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => const BagSheet(),
  );
}

class BagSheet extends ConsumerWidget {
  const BagSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(bagProvider).values.toList();
    final bag = ref.read(bagProvider.notifier);
    final total = lines.fold(0.0, (sum, l) => sum + l.subtotal);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your bag', style: displayStyle(30)),
            const SizedBox(height: 16),
            if (lines.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Nothing here yet. Tap + on an object to add it.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: lines.length,
                  separatorBuilder: (_, _) => const Divider(height: 20),
                  itemBuilder: (context, i) {
                    final line = lines[i];
                    final p = line.product;
                    return Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: SpinningMesh(shape: p.shape, color: p.color, showShadow: false, zoom: 1.1),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(formatPeso(p.price), style: const TextStyle(color: AppColors.muted)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'One less',
                          onPressed: () => bag.decrement(p.id!),
                          icon: const Icon(Icons.remove_rounded, size: 18),
                        ),
                        Text('${line.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        IconButton(
                          tooltip: 'One more',
                          onPressed: line.quantity < p.stock ? () => bag.add(p) : null,
                          icon: const Icon(Icons.add_rounded, size: 18),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('TOTAL', style: monoLabel()),
                const Spacer(),
                Text(formatPeso(total), style: displayStyle(26)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: lines.isEmpty
                  ? null
                  : () {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.of(context).pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Demo store: checkout isn’t connected yet. Your bag is saved.')),
                      );
                    },
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
