import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'mesh.dart';

/// Orientation of a mesh on screen. Mutated every frame by [SpinningMesh]
/// and used as the painter's repaint signal, so spinning never rebuilds
/// widgets.
class MeshPose extends ChangeNotifier {
  double _yaw = 0;
  double _pitch = 0.4;
  double _roll = 0;

  double get yaw => _yaw;
  double get pitch => _pitch;
  double get roll => _roll;

  void set(double yaw, double pitch, double roll) {
    if (yaw == _yaw && pitch == _pitch && roll == _roll) return;
    _yaw = yaw;
    _pitch = pitch;
    _roll = roll;
    notifyListeners();
  }
}

/// Software 3D renderer: rotate, perspective-project, back-face cull,
/// depth-sort (painter's algorithm) and flat-shade each face with a
/// key light, a fill light, a specular highlight and a rim light.
class MeshPainter extends CustomPainter {
  MeshPainter({
    required this.mesh,
    required this.color,
    required this.pose,
    this.zoom = 1,
    this.showShadow = true,
    this.rimColor = const Color(0xFF9CC9FF),
  }) : super(repaint: pose);

  final Mesh mesh;
  final Color color;
  final MeshPose pose;
  final double zoom;
  final bool showShadow;
  final Color rimColor;

  static const _cameraDistance = 4.2;
  static final _keyLight = const Vec3(-0.55, 0.75, 0.62).normalized();
  static final _fillLight = const Vec3(0.85, -0.15, 0.45).normalized();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = math.min(size.width, size.height) * 0.36 * zoom;
    final center = Offset(size.width / 2, size.height / 2 - scale * 0.06);

    if (showShadow) _paintShadow(canvas, center, scale);

    final rotated = [
      for (final v in mesh.vertices) v.rotated(pose.yaw, pose.pitch, pose.roll),
    ];

    Offset project(Vec3 p) {
      final k = _cameraDistance / (_cameraDistance - p.z);
      return Offset(center.dx + p.x * k * scale, center.dy - p.y * k * scale);
    }

    const camera = Vec3(0, 0, _cameraDistance);
    final faces = <_ShadedFace>[];
    for (final face in mesh.faces) {
      final pts = [for (final i in face) rotated[i]];
      final normal = Mesh.faceNormal(pts);
      final mid = Mesh.centroid(pts);
      final view = (camera - mid).normalized();
      final facing = normal.dot(view);
      if (facing <= 0.0001) continue;
      faces.add(_ShadedFace(
        points: [for (final p in pts) project(p)],
        depth: mid.z,
        color: _shade(normal, view, facing),
      ));
    }
    faces.sort((a, b) => a.depth.compareTo(b.depth));

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final f in faces) {
      final path = Path()..addPolygon(f.points, true);
      fill.color = f.color;
      seam.color = f.color;
      canvas.drawPath(path, fill);
      canvas.drawPath(path, seam);
    }
  }

  Color _shade(Vec3 n, Vec3 view, double facing) {
    final key = math.max(0.0, n.dot(_keyLight));
    final fillAmt = math.max(0.0, n.dot(_fillLight)) * 0.28;
    final half = (_keyLight + view).normalized();
    final spec = math.pow(math.max(0.0, n.dot(half)), 32).toDouble() * 0.5;
    final rim = math.pow(1 - facing, 2.6).toDouble() * 0.42;
    const ambient = 0.2;
    final lit = ambient + key * 0.86 + fillAmt;

    double channel(double base, double rimBase) =>
        (base * lit + spec + rim * rimBase).clamp(0.0, 1.0);

    return Color.from(
      alpha: 1,
      red: channel(color.r, rimColor.r),
      green: channel(color.g, rimColor.g),
      blue: channel(color.b, rimColor.b),
    );
  }

  void _paintShadow(Canvas canvas, Offset center, double scale) {
    final shadowCenter = center + Offset(0, scale * 1.32);
    final rect = Rect.fromCenter(
      center: shadowCenter,
      width: scale * 2.1,
      height: scale * 0.34,
    );
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        shadowCenter,
        scale * 1.05,
        [const Color(0x8C000000), const Color(0x00000000)],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.save();
    canvas.translate(shadowCenter.dx, shadowCenter.dy);
    canvas.scale(1, rect.height / rect.width);
    canvas.translate(-shadowCenter.dx, -shadowCenter.dy);
    canvas.drawCircle(shadowCenter, rect.width / 2, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(MeshPainter old) =>
      old.mesh != mesh ||
      old.color != color ||
      old.pose != pose ||
      old.zoom != zoom ||
      old.showShadow != showShadow ||
      old.rimColor != rimColor;
}

class _ShadedFace {
  _ShadedFace({required this.points, required this.depth, required this.color});

  final List<Offset> points;
  final double depth;
  final Color color;
}
