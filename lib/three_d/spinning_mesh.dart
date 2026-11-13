import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'mesh_painter.dart';
import 'shapes.dart';

/// A product rendered as a live 3D object. It idles with a slow turntable
/// spin; with [interactive] it can be dragged to rotate and keeps spinning
/// with momentum. [tilt] (-1..1 on each axis) leans the object toward the
/// pointer for the card parallax effect.
class SpinningMesh extends StatefulWidget {
  const SpinningMesh({
    super.key,
    required this.shape,
    required this.color,
    this.detail = MeshDetail.low,
    this.speed = 0.45,
    this.zoom = 1,
    this.interactive = false,
    this.tilt = Offset.zero,
    this.phase = 0,
    this.showShadow = true,
  });

  final ShapeKind shape;
  final Color color;
  final MeshDetail detail;

  /// Idle spin in radians per second.
  final double speed;
  final double zoom;
  final bool interactive;
  final Offset tilt;

  /// Starting yaw, so a grid of identical shapes doesn't spin in lockstep.
  final double phase;
  final bool showShadow;

  @override
  State<SpinningMesh> createState() => _SpinningMeshState();
}

class _SpinningMeshState extends State<SpinningMesh>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final MeshPose _pose;
  Duration _last = Duration.zero;

  double _yaw = 0;
  double _pitch = 0.42;
  double _yawVelocity = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _yaw = widget.phase;
    _pose = MeshPose()..set(_yaw, _pitch, _roll);
    _ticker = createTicker(_onTick)..start();
  }

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  double get _roll => widget.shape == ShapeKind.torus ? 0.32 : 0.0;

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (!_dragging) {
      final idle = _reduceMotion ? 0.0 : widget.speed;
      _yaw += (idle + _yawVelocity) * dt;
      _yawVelocity *= math.pow(0.08, dt).toDouble();
      _pitch += (0.42 - _pitch) * math.min(1, dt * 1.6);
    }

    final tiltYaw = widget.tilt.dx * 0.55;
    final tiltPitch = widget.tilt.dy * 0.35;
    _pose.set(_yaw + tiltYaw, _pitch + tiltPitch, _roll);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = RepaintBoundary(
      child: CustomPaint(
        painter: MeshPainter(
          mesh: Shapes.of(widget.shape, widget.detail),
          color: widget.color,
          pose: _pose,
          zoom: widget.zoom,
          showShadow: widget.showShadow,
        ),
        size: Size.infinite,
      ),
    );
    if (widget.interactive) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          _dragging = true;
          _yawVelocity = 0;
        },
        onPanUpdate: (d) {
          _yaw += d.delta.dx * 0.012;
          _pitch = (_pitch + d.delta.dy * 0.01).clamp(-1.3, 1.3);
        },
        onPanEnd: (d) {
          _dragging = false;
          _yawVelocity = (d.velocity.pixelsPerSecond.dx * 0.004).clamp(-9.0, 9.0);
        },
        child: MouseRegion(cursor: SystemMouseCursors.grab, child: child),
      );
    }
    return child;
  }
}
