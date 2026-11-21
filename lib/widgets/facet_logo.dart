import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// FACET logo: an extruded "F" on a terracotta tile (the faceted-3D idea in
/// one mark) beside the wordmark. [showWordmark] false gives the mark alone.
class FacetLogo extends StatelessWidget {
  const FacetLogo({super.key, this.size = 30, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: FacetMarkPainter(tile: AppColors.accent)),
    );
    return Semantics(
      label: 'FACET',
      excludeSemantics: true,
      child: showWordmark
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                mark,
                SizedBox(width: size * 0.32),
                Text('FACET', style: displayStyle(size * 0.82).copyWith(letterSpacing: size * 0.04)),
              ],
            )
          : mark,
    );
  }
}

/// Drawn on a 32 x 32 grid. Kept in step with web/favicon.svg.
class FacetMarkPainter extends CustomPainter {
  FacetMarkPainter({required this.tile});

  final Color tile;

  static const _face = Color(0xFFFFFBF5);

  Path _f(double dx, double dy) => Path()
    ..moveTo(9 + dx, 7 + dy)
    ..lineTo(24 + dx, 7 + dy)
    ..lineTo(24 + dx, 12 + dy)
    ..lineTo(14 + dx, 12 + dy)
    ..lineTo(14 + dx, 14.5 + dy)
    ..lineTo(20.5 + dx, 14.5 + dy)
    ..lineTo(20.5 + dx, 19.5 + dy)
    ..lineTo(14 + dx, 19.5 + dy)
    ..lineTo(14 + dx, 25 + dy)
    ..lineTo(9 + dx, 25 + dy)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 32, size.height / 32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 32, 32), const Radius.circular(8)),
      Paint()..color = tile,
    );
    // The side facet: the same F pushed back and down, in a darker tone.
    final side = Color.lerp(tile, const Color(0xFF000000), 0.42)!;
    for (var i = 2.6; i > 0; i -= 0.65) {
      canvas.drawPath(_f(i, i), Paint()..color = side);
    }
    canvas.drawPath(_f(0, 0), Paint()..color = _face);
  }

  @override
  bool shouldRepaint(FacetMarkPainter old) => old.tile != tile;
}
