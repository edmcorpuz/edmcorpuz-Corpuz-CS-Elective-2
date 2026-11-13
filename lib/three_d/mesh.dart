import 'dart:math' as math;

/// A tiny 3D vector used by the software renderer.
class Vec3 {
  const Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

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
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final x1 = x * cy + z * sy;
    final z1 = -x * sy + z * cy;

    final cp = math.cos(pitch), sp = math.sin(pitch);
    final y2 = y * cp - z1 * sp;
    final z2 = y * sp + z1 * cp;

    final cr = math.cos(roll), sr = math.sin(roll);
    return Vec3(x1 * cr - y2 * sr, x1 * sr + y2 * cr, z2);
  }

  @override
  String toString() => 'Vec3($x, $y, $z)';
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
