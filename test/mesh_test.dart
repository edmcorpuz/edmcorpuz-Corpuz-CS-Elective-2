import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:unang_flutter_project/three_d/appliances.dart';
import 'package:unang_flutter_project/three_d/mesh.dart';

/// Every face must wind counter-clockwise from outside, otherwise back-face
/// culling would hide the visible side of the appliance.
void expectOutward(Mesh mesh, Vec3 Function(Vec3 centroid) inside) {
  for (final face in mesh.faces) {
    final pts = [for (final i in face) mesh.vertices[i]];
    final normal = Mesh.faceNormal(pts);
    final mid = Mesh.centroid(pts);
    expect(normal.length, closeTo(1, 1e-6), reason: 'degenerate face $face');
    expect(normal.dot(mid - inside(mid)), greaterThan(0), reason: 'face $face points inward');
  }
}

Mesh built(void Function(MeshBuilder b) f) {
  final b = MeshBuilder(segments: 12);
  f(b);
  return b.build();
}

void main() {
  const c = Vec3(0.3, -0.2, 0.1);
  Vec3 center(Vec3 _) => c;

  test('box faces point outward', () {
    expectOutward(built((b) => b.box(c, const Vec3(0.4, 0.2, 0.7))), center);
  });

  for (final axis in Axis3.values) {
    test('cylinder along ${axis.name} faces point outward', () {
      expectOutward(built((b) => b.frustum(c, r0: 0.3, r1: 0.3, h: 0.8, axis: axis)), center);
    });
    test('tapered frustum along ${axis.name} faces point outward', () {
      expectOutward(built((b) => b.frustum(c, r0: 0.4, r1: 0.15, h: 0.6, axis: axis)), center);
    });
  }

  test('cone faces point outward', () {
    expectOutward(built((b) => b.frustum(c, r0: 0.5, r1: 0, h: 0.9)), center);
  });

  test('ellipsoid and hemisphere faces point outward', () {
    expectOutward(built((b) => b.ellipsoid(c, const Vec3(0.5, 0.3, 0.4))), center);
    expectOutward(
      built((b) => b.ellipsoid(c, const Vec3(0.5, 0.3, 0.4), hemisphere: true)),
      (mid) => c + const Vec3(0, 0.05, 0), // just above the flat base, inside the dome
    );
  });

  test('torus faces point away from the tube center', () {
    const major = 0.6;
    expectOutward(built((b) => b.torus(c, major, 0.15)), (mid) {
      final d = mid - c;
      final phi = math.atan2(d.z, d.x);
      return c + Vec3(major * math.cos(phi), 0, major * math.sin(phi));
    });
  });

  test('screen grid faces +Z', () {
    final mesh = built((b) => b.grid(c, 0.5, 0.3, 4, 3));
    expect(mesh.faces.length, 12);
    for (final face in mesh.faces) {
      final n = Mesh.faceNormal([for (final i in face) mesh.vertices[i]]);
      expect(n.z, closeTo(1, 1e-9));
    }
  });

  for (final kind in ApplianceKind.values) {
    test('${kind.name} model builds and fits the unit sphere', () {
      for (final detail in MeshDetail.values) {
        final model = ApplianceModel(Appliances.build(kind, detail));
        expect(model.faceCount, greaterThan(20));
        expect(model.scale, greaterThan(0));
        expect(model.floorY, lessThan(0));
        expect(model.footprint, inInclusiveRange(0.1, 1.0001));
      }
    });
  }

  test('a fridge door hinge is closed at rest and swings outward when active', () {
    const door = Hinge(Vec3(-0.42, 0, 0.395), Axis3.y, -1.8);
    const rightEdge = Vec3(0.42, 0, 0.395);
    expect(door.apply(rightEdge, const MotionInput(0, 0, 0)).x, closeTo(0.42, 1e-9));
    final open = door.apply(rightEdge, const MotionInput(1, 0, 0));
    expect(open.z, greaterThan(0.395 + 0.5), reason: 'door should swing toward the viewer');
  });

  test('ApplianceKind.fromDb maps column values and falls back to fridge', () {
    expect(ApplianceKind.fromDb('rice_cooker'), ApplianceKind.riceCooker);
    expect(ApplianceKind.fromDb('robot_vacuum'), ApplianceKind.robotVacuum);
    expect(ApplianceKind.fromDb('spaceship'), ApplianceKind.fridge);
    expect(ApplianceKind.fromDb(null), ApplianceKind.fridge);
  });
}
