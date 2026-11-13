import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../three_d/shapes.dart';
import '../three_d/spinning_mesh.dart';

/// Opening "stage": oversized headline beside one large object the visitor
/// can grab and spin — the single-hero-object pattern from 3D commerce sites.
class ShopHero extends StatelessWidget {
  const ShopHero({
    super.key,
    required this.total,
    required this.filtered,
    this.priceLabel,
  });

  final int total;
  final bool filtered;
  final String? priceLabel;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final headline = compact ? 50.0 : 84.0;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text('COLLECTION 03 — OBJECTS IN DEPTH', style: monoLabel(color: AppColors.text)),
          ],
        ),
        const SizedBox(height: 18),
        Text('Objects\nwith depth.', style: displayStyle(headline)),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: const Text(
            'Sculptural lamps, speakers and desk pieces — every one rendered live in 3D. '
            'Grab the torus and give it a spin.',
            style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5),
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Stat(label: filtered ? 'MATCHING' : 'OBJECTS', value: '$total'),
            if (priceLabel != null) _Stat(label: 'PRICE RANGE', value: priceLabel!),
          ],
        ),
      ],
    );

    final stage = Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [AppColors.accent.withValues(alpha: 0.16), Colors.transparent],
                radius: 0.62,
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: SpinningMesh(
            shape: ShapeKind.torus,
            color: AppColors.accent,
            detail: MeshDetail.high,
            interactive: true,
            zoom: 1.15,
            speed: 0.3,
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Row(
            children: [
              const Icon(Icons.pan_tool_alt_outlined, size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
              Text('DRAG TO ROTATE', style: monoLabel(size: 10)),
            ],
          ),
        ),
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 260, child: stage),
            const SizedBox(height: 8),
            copy,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: SizedBox(
        height: 420,
        child: Row(
          children: [
            Expanded(flex: 5, child: Align(alignment: Alignment.centerLeft, child: copy)),
            Expanded(flex: 4, child: stage),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: monoLabel(size: 9.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }
}

String? priceRangeLabel(double? min, double? max) =>
    min == null || max == null ? null : '${formatPeso(min)} – ${formatPeso(max)}';
