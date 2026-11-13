import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../three_d/appliance_view.dart';
import 'tilt_card.dart';

/// Grid card. On hover the card tilts toward the pointer, the spotlight
/// brightens, the appliance lifts, turns to face you and runs its own
/// animation (door opens, toast pops…), and an action tag slides in.
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

  static const _duration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final color = product.color;
    return TiltCard(
      onTap: onOpen,
      builder: (context, tilt, active) => AnimatedContainer(
        duration: _duration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: active ? 1.15 : 0.95,
            colors: [
              Color.lerp(AppColors.surfaceHigh, color, active ? 0.34 : 0.14)!,
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
                        tag: 'product-model-${product.id}',
                        child: ApplianceView(
                          kind: product.kind,
                          color: color,
                          tilt: tilt,
                          active: active,
                          phase: (product.id ?? 0) * 0.9,
                          speed: 0.35,
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
                    Positioned(right: 12, top: 10, child: _StockTag(stock: product.stock)),
                  Positioned(
                    left: 12,
                    bottom: 6,
                    child: AnimatedSlide(
                      offset: active ? Offset.zero : const Offset(0, 0.6),
                      duration: _duration,
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: active ? 1 : 0,
                        duration: _duration,
                        child: _ActionTag(label: product.kind.action),
                      ),
                    ),
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
                          style: displayStyle(16.5).copyWith(height: 1.1, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: _duration,
                          style: TextStyle(
                            color: active ? AppColors.text : AppColors.muted,
                            fontSize: 13.5,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          child: Text(formatPeso(product.price)),
                        ),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    scale: active ? 1.12 : 1,
                    duration: _duration,
                    curve: Curves.easeOutBack,
                    child: IconButton.filled(
                      tooltip: product.inStock ? 'Add to bag' : 'Sold out',
                      onPressed: product.inStock ? onAddToBag : null,
                      style: IconButton.styleFrom(
                        backgroundColor: active ? AppColors.accent : AppColors.text,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: AppColors.line,
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
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

class _ActionTag extends StatelessWidget {
  const _ActionTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label.toUpperCase(), style: monoLabel(size: 9.5, color: AppColors.text)),
        ],
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
