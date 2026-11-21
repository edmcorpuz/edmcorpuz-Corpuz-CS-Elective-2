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
    this.onAddToBag,
    this.onEdit,
    this.onDelete,
  });

  final Product product;
  final VoidCallback onOpen;

  /// Customers: the add-to-cart button.
  final VoidCallback? onAddToBag;

  /// Admins: edit and delete buttons replace add-to-cart.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  // Slow enough to read as a smooth showroom turn, not a snap.
  static const _duration = Duration(milliseconds: 520);

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
                          speed: 0.25,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Text(product.category.toUpperCase(), style: monoLabel(size: 10)),
                  ),
                  if (product.imageUrl != null)
                    Positioned(
                      right: 12,
                      bottom: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          product.imageUrl!,
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          semanticLabel: 'Photo of ${product.name}',
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
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
                  if (onEdit != null || onDelete != null) ...[
                    IconButton.outlined(
                      tooltip: 'Edit ${product.name}',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    const SizedBox(width: 4),
                    IconButton.outlined(
                      tooltip: 'Delete ${product.name}',
                      onPressed: onDelete,
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    ),
                  ] else
                  AnimatedScale(
                    scale: active ? 1.12 : 1,
                    duration: _duration,
                    curve: Curves.easeInOutCubic,
                    child: IconButton.filled(
                      tooltip: product.inStock ? 'Add to cart' : 'Sold out',
                      onPressed: product.inStock ? onAddToBag : null,
                      style: IconButton.styleFrom(
                        backgroundColor: active ? AppColors.accent : AppColors.text,
                        foregroundColor: active ? AppColors.onAccent : AppColors.bg,
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
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
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
