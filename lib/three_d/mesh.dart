import 'dart:math' as math;

/// A tiny 3D vector used by the software renderer.
class Vec3 {
  const Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  static const zero = Vec3(0, 0, 0);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;

  Vec3 cross(Vec3 o) =>
      Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  double get length => math.sqrt(x * x + y * y + z * z);

  Vec3 normalized() {
    final l = length;
    return l == 0 ? this : Vec3(x / l, y / l, z / l);
  }

  /// Rotates around Y (yaw), then X (pitch), then Z (roll).
  Vec3 rotated(double yaw, double pitch, double roll) {
    var p = rotateAbout(this, Axis3.y, yaw);
    p = rotateAbout(p, Axis3.x, pitch);
    return roll == 0 ? p : rotateAbout(p, Axis3.z, roll);
  }

  @override
  String toString() => 'Vec3($x, $y, $z)';
}

enum Axis3 { x, y, z }

/// Right-handed rotation of [p] by [angle] radians about the origin.
Vec3 rotateAbout(Vec3 p, Axis3 axis, double angle) {
  if (angle == 0) return p;
  final c = math.cos(angle), s = math.sin(angle);
  return switch (axis) {
    Axis3.x => Vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c),
    Axis3.y => Vec3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c),
    Axis3.z => Vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z),
  };
}

/// Polygon mesh. Each face lists vertex indices counter-clockwise when seen
/// from outside, so its normal points out of the solid.
class Mesh {
  const Mesh(this.vertices, this.faces);

  final List<Vec3> vertices;
  final List<List<int>> faces;

  /// Face normal via Newell's method (robust for n-gons and repeated
  /// vertices at sphere poles).
  static Vec3 faceNormal(List<Vec3> pts) {
    var nx = 0.0, ny = 0.0, nz = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      nx += (a.y - b.y) * (a.z + b.z);
      ny += (a.z - b.z) * (a.x + b.x);
      nz += (a.x - b.x) * (a.y + b.y);
    }
    return Vec3(nx, ny, nz).normalized();
  }

  static Vec3 centroid(List<Vec3> pts) {
    var sx = 0.0, sy = 0.0, sz = 0.0;
    for (final p in pts) {
      sx += p.x;
      sy += p.y;
      sz += p.z;
    }
    final n = pts.length.toDouble();
    return Vec3(sx / n, sy / n, sz / n);
  }
}

/// Assembles meshes out of primitives. Curved primitives are built along
/// local +Y and then turned to face [Axis3.x] or [Axis3.z] when asked.
class MeshBuilder {
  MeshBuilder({this.segments = 16});

  final int segments;
  final List<Vec3> _v = [];
  final List<List<int>> _f = [];

  int get mark => _v.length;

  Mesh build() => Mesh(List.unmodifiable(_v), List.unmodifiable(_f));

  /// Applies [f] to every vertex added since [start] (e.g. to rotate a
  /// fan blade into place).
  void transformFrom(int start, Vec3 Function(Vec3) f) {
    for (var i = start; i < _v.length; i++) {
      _v[i] = f(_v[i]);
    }
  }

  static Vec3 _orient(Vec3 p, Axis3 axis) => switch (axis) {
        Axis3.y => p,
        Axis3.z => rotateAbout(p, Axis3.x, math.pi / 2),
        Axis3.x => rotateAbout(p, Axis3.z, -math.pi / 2),
      };

  void _place(int start, Vec3 center, Axis3 axis) =>
      transformFrom(start, (p) => _orient(p, axis) + center);

  /// Axis-aligned box with half-extents [h].
  void box(Vec3 c, Vec3 h) {
    const axes = [
      (Vec3(0, 0, 1), Vec3(1, 0, 0), Vec3(0, 1, 0)),
      (Vec3(0, 0, -1), Vec3(-1, 0, 0), Vec3(0, 1, 0)),
      (Vec3(1, 0, 0), Vec3(0, 0, -1), Vec3(0, 1, 0)),
      (Vec3(-1, 0, 0), Vec3(0, 0, 1), Vec3(0, 1, 0)),
      (Vec3(0, 1, 0), Vec3(1, 0, 0), Vec3(0, 0, -1)),
      (Vec3(0, -1, 0), Vec3(1, 0, 0), Vec3(0, 0, 1)),
    ];
    Vec3 scaled(Vec3 a) => Vec3(a.x * h.x, a.y * h.y, a.z * h.z);
    for (final (n, u, v) in axes) {
      final fc = c + scaled(n);
      final us = scaled(u), vs = scaled(v);
      final base = _v.length;
      _v.addAll([fc - us - vs, fc + us - vs, fc + us + vs, fc - us + vs]);
      _f.add([base, base + 1, base + 2, base + 3]);
    }
  }

  /// Flat rectangle facing +Z split into [nx] x [ny] cells (TV screens).
  void grid(Vec3 c, double hx, double hy, int nx, int ny) {
    final base = _v.length;
    for (var j = 0; j <= ny; j++) {
      for (var i = 0; i <= nx; i++) {
        _v.add(Vec3(c.x - hx + 2 * hx * i / nx, c.y - hy + 2 * hy * j / ny, c.z));
      }
    }
    int idx(int i, int j) => base + j * (nx + 1) + i;
    for (var j = 0; j < ny; j++) {
      for (var i = 0; i < nx; i++) {
        _f.add([idx(i, j), idx(i + 1, j), idx(i + 1, j + 1), idx(i, j + 1)]);
      }
    }
  }

  /// Cylinder / truncated cone. [r0] is the bottom radius, [r1] the top
  /// (0 makes a cone). Caps are triangle fans so depth sorting stays sane.
  void frustum(
    Vec3 c, {
    required double r0,
    required double r1,
    required double h,
    Axis3 axis = Axis3.y,
    int? seg,
    bool capTop = true,
    bool capBottom = true,
  }) {
    final n = seg ?? segments;
    final start = _v.length;
    for (var j = 0; j < n; j++) {
      final phi = 2 * math.pi * j / n;
      final cx = math.cos(phi), cz = math.sin(phi);
      _v.add(Vec3(r1 * cx, h / 2, r1 * cz));
      _v.add(Vec3(r0 * cx, -h / 2, r0 * cz));
    }
    int top(int j) => start + 2 * (j % n);
    int bottom(int j) => start + 2 * (j % n) + 1;
    for (var j = 0; j < n; j++) {
      _f.add([top(j), top(j + 1), bottom(j + 1), bottom(j)]);
    }
    if (capTop && r1 > 0) {
      final t = _v.length;
      _v.add(Vec3(0, h / 2, 0));
      for (var j = 0; j < n; j++) {
        _f.add([t, top(j + 1), top(j)]);
      }
    }
    if (capBottom && r0 > 0) {
      final b = _v.length;
      _v.add(Vec3(0, -h / 2, 0));
      for (var j = 0; j < n; j++) {
        _f.add([b, bottom(j), bottom(j + 1)]);
      }
    }
    _place(start, c, axis);
  }

  /// Ellipsoid with radii [r]; [hemisphere] keeps the top half and closes
  /// it with a flat base.
  void ellipsoid(Vec3 c, Vec3 r, {int? rings, int? seg, bool hemisphere = false}) {
    final n = seg ?? segments;
    final rc = rings ?? math.max(4, n ~/ 2);
    final start = _v.length;
    final thetaMax = hemisphere ? math.pi / 2 : math.pi;
    for (var i = 0; i <= rc; i++) {
      final theta = thetaMax * i / rc;
      for (var j = 0; j <= n; j++) {
        final phi = 2 * math.pi * j / n;
        _v.add(Vec3(
          r.x * math.sin(theta) * math.cos(phi),
          r.y * math.cos(theta),
          r.z * math.sin(theta) * math.sin(phi),
        ));
      }
    }
    int idx(int i, int j) => start + i * (n + 1) + j;
    for (var i = 0; i < rc; i++) {
      for (var j = 0; j < n; j++) {
        if (i == 0) {
          _f.add([idx(0, j), idx(1, j + 1), idx(1, j)]);
        } else if (i == rc - 1 && !hemisphere) {
          _f.add([idx(i, j), idx(i, j + 1), idx(i + 1, j)]);
        } else {
          _f.add([idx(i, j), idx(i, j + 1), idx(i + 1, j + 1), idx(i + 1, j)]);
        }
      }
    }
    if (hemisphere) {
      final b = _v.length;
      _v.add(Vec3.zero);
      for (var j = 0; j < n; j++) {
        _f.add([b, idx(rc, j), idx(rc, j + 1)]);
      }
    }
    transformFrom(start, (p) => p + c);
  }

  /// Ring around [axis].
  void torus(Vec3 c, double major, double minor, {Axis3 axis = Axis3.y, int? seg, int? sides}) {
    final n = seg ?? segments * 2;
    final m = sides ?? math.max(5, segments ~/ 2);
    final start = _v.length;
    for (var i = 0; i < n; i++) {
      final phi = 2 * math.pi * i / n;
      for (var j = 0; j < m; j++) {
        final theta = 2 * math.pi * j / m;
        final ring = major + minor * math.cos(theta);
        _v.add(Vec3(ring * math.cos(phi), minor * math.sin(theta), ring * math.sin(phi)));
      }
    }
    int idx(int i, int j) => start + (i % n) * m + (j % m);
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < m; j++) {
        _f.add([idx(i, j), idx(i, j + 1), idx(i + 1, j + 1), idx(i + 1, j)]);
      }
    }
    _place(start, c, axis);
  }
}
