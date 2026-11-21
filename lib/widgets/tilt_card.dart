import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A card that leans toward the pointer in 3D perspective, with a moving
/// glare highlight. [builder] receives the tilt (-1..1 per axis) so content
/// can add parallax, and whether the card is hovered (or pressed on touch)
/// so content can play its own hover animation.
class TiltCard extends StatefulWidget {
  const TiltCard({
    super.key,
    required this.builder,
    this.onTap,
    this.maxAngle = 0.16,
    this.radius = 22,
  });

  final Widget Function(BuildContext context, Offset tilt, bool active) builder;
  final VoidCallback? onTap;
  final double maxAngle;
  final double radius;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  Offset _target = Offset.zero;
  bool _hovered = false;
  bool _pressed = false;

  void _track(Offset local, Size size) {
    if (size.isEmpty) return;
    final dx = (local.dx / size.width) * 2 - 1;
    final dy = (local.dy / size.height) * 2 - 1;
    setState(() => _target = Offset(dx.clamp(-1, 1), dy.clamp(-1, 1)));
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return MouseRegion(
          cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onHover: (e) => _track(e.localPosition, size),
          onExit: (_) => setState(() {
            _hovered = false;
            _target = Offset.zero;
          }),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: TweenAnimationBuilder<Offset>(
              tween: Tween(end: _target),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, tilt, _) {
                final transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.0011)
                  ..rotateX(-tilt.dy * widget.maxAngle)
                  ..rotateY(tilt.dx * widget.maxAngle);
                return Transform(
                  alignment: Alignment.center,
                  transform: transform,
                  child: AnimatedScale(
                    scale: _pressed ? 0.97 : (_hovered ? 1.02 : 1),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeInOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(
                          color: _hovered ? Color.lerp(AppColors.line, AppColors.accent, 0.45)! : AppColors.line,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow.withValues(alpha: (_hovered ? 0.5 : 0.26) * (AppColors.isDark ? 1 : 0.4)),
                            blurRadius: _hovered ? 40 : 18,
                            offset: Offset(-tilt.dx * 10, 18 - tilt.dy * 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: radius,
                        child: Stack(
                          fit: StackFit.passthrough,
                          children: [
                            widget.builder(context, tilt, _hovered || _pressed),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: AnimatedOpacity(
                                  opacity: _hovered ? 1 : 0,
                                  duration: const Duration(milliseconds: 380),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        center: Alignment(tilt.dx, tilt.dy),
                                        radius: 1.1,
                                        colors: [
                                          Colors.white.withValues(alpha: AppColors.isDark ? 0.08 : 0.4),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
