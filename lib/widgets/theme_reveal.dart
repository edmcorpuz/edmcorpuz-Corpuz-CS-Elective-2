import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Reveals the newly selected theme from the toggle button's screen position.
class ThemeRevealOverlay extends StatefulWidget {
  final Widget child;
  final Offset? origin;
  final ui.Image? oldImage;
  final Color revealColor;

  const ThemeRevealOverlay({
    super.key,
    required this.child,
    required this.origin,
    required this.oldImage,
    required this.revealColor,
  });

  @override
  State<ThemeRevealOverlay> createState() => _ThemeRevealOverlayState();
}

class _ThemeRevealOverlayState extends State<ThemeRevealOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.origin != null) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.oldImage?.dispose();
    super.dispose();
  }

  double _radiusFor(Size size, Offset origin) {
    final corners = <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    return corners
        .map((corner) => (corner - origin).distance)
        .reduce(math.max);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.origin == null) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final renderBox = context.findRenderObject() as RenderBox?;
        final origin = renderBox?.globalToLocal(widget.origin!) ?? widget.origin!;
        final maxRadius = _radiusFor(size, origin);

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final progress = Curves.easeOutCubic.transform(
                        _controller.value,
                      );
                      return CustomPaint(
                        isComplex: true,
                        willChange: true,
                        painter: _ThemeRevealPainter(
                          origin: origin,
                          radius: math.max(1, maxRadius * progress),
                          progress: progress,
                          oldImage: widget.oldImage,
                          revealColor: widget.revealColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeRevealPainter extends CustomPainter {
  final Offset origin;
  final double radius;
  final double progress;
  final ui.Image? oldImage;
  final Color revealColor;

  const _ThemeRevealPainter({
    required this.origin,
    required this.radius,
    required this.progress,
    required this.oldImage,
    required this.revealColor,
  });

  Path _outsideCircle(Size size) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: origin, radius: radius));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    if (oldImage != null) {
      // The captured old screen stays visible outside the circle while the
      // newly themed screen is revealed inside it. Nothing disappears.
      canvas.save();
      canvas.clipPath(_outsideCircle(size));
      canvas.drawImageRect(
        oldImage!,
        Rect.fromLTWH(
          0,
          0,
          oldImage!.width.toDouble(),
          oldImage!.height.toDouble(),
        ),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.low,
      );
      canvas.restore();
    } else {
      // Safe fallback for platforms where a repaint boundary cannot be
      // captured: keep the new page visible and draw only a soft wave.
      canvas.drawCircle(
        origin,
        radius,
        Paint()..color = revealColor.withValues(alpha: 0.07 * (1 - progress)),
      );
    }

    canvas.drawCircle(
      origin,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = revealColor.withValues(
          alpha: (0.24 * (1 - progress)).clamp(0.0, 1.0),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _ThemeRevealPainter oldDelegate) {
    return oldDelegate.origin != origin ||
        oldDelegate.radius != radius ||
        oldDelegate.progress != progress ||
        oldDelegate.oldImage != oldImage ||
        oldDelegate.revealColor != revealColor;
  }
}
