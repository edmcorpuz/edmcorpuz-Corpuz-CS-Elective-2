import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../three_d/spinning_mesh.dart';
import 'tilt_card.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onOpen,
    required this.onAddToBag,
  });

  final Product product;
  final VoidCallback onOpen;
  final VoidCallback? onAddToBag;

  @override
  Widget build(BuildContext context) {
    final color = product.color;
    return TiltCard(
      onTap: onOpen,
      builder: (context, tilt) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.35),
            radius: 1.0,
            colors: [
              Color.lerp(AppColors.surfaceHigh, color, 0.16)!,
              AppColors.surface,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(tilt.dx * 8, tilt.dy * 6),
                      child: Hero(
                        tag: 'product-mesh-${product.id}',
                        child: SpinningMesh(
                          shape: product.shape,
                          color: color,
                          tilt: tilt,
                          phase: (product.id ?? 0) * 0.9,
                          speed: 0.38,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Text(product.category.toUpperCase(), style: monoLabel(size: 10)),
                  ),
                  if (product.stock <= 3)
                    Positioned(
                      right: 12,
                      top: 10,
                      child: _StockTag(stock: product.stock),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 10, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: displayStyle(17).copyWith(height: 1.1, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatPeso(product.price),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13.5,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    tooltip: product.inStock ? 'Add to bag' : 'Sold out',
                    onPressed: product.inStock ? onAddToBag : null,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.text,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppColors.line,
                    ),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockTag extends StatelessWidget {
  const _StockTag({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final soldOut = stock == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: soldOut ? AppColors.danger.withValues(alpha: 0.16) : AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        soldOut ? 'SOLD OUT' : 'ONLY $stock LEFT',
        style: monoLabel(size: 9.5, color: soldOut ? AppColors.danger : AppColors.accent),
      ),
    );
  }
}
