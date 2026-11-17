import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:unang_flutter_project/data/auth_repository.dart';
import 'package:unang_flutter_project/state/admin_controller.dart';
import 'package:unang_flutter_project/widgets/product_form.dart' show describeError;

/// In-memory stand-in for Supabase Auth plus the `admins` table.
class FakeAuth implements AuthRepository {
  FakeAuth({required this.accounts, required this.admins});

  /// email -> password
  final Map<String, String> accounts;
  final Set<String> admins;
  final _changes = StreamController<void>.broadcast();
  String? _current;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  String? get currentEmail => _current;

  @override
  bool get signedIn => _current != null;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (accounts[email] != password) {
      throw const AuthException('Invalid login credentials', statusCode: '400');
    }
    _current = email;
    _changes.add(null);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _changes.add(null);
  }

  @override
  Future<bool> isAdmin() async => _current != null && admins.contains(_current);
}

void main() {
  late FakeAuth auth;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuth(
      accounts: {'owner@test.dev': 'right-pass', 'guest@test.dev': 'guest-pass'},
      admins: {'owner@test.dev'},
    );
    container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(auth)]);
    addTearDown(container.dispose);
  });

  AdminState read() => container.read(adminProvider);
  AdminController controller() => container.read(adminProvider.notifier);

  test('visitors start signed out with no admin controls', () {
    expect(read().isAdmin, isFalse);
    expect(read().email, isNull);
  });

  test('an admin account signs in and unlocks editing', () async {
    await controller().signIn(email: 'owner@test.dev', password: 'right-pass');
    await pumpEventQueue();
    expect(read().isAdmin, isTrue);
    expect(read().email, 'owner@test.dev');
  });

  test('a wrong password is rejected with a readable message', () async {
    await expectLater(
      controller().signIn(email: 'owner@test.dev', password: 'nope'),
      throwsA(isA<AuthException>().having(describeError, 'message', 'Wrong email or password.')),
    );
    expect(read().isAdmin, isFalse);
  });

  test('a non-admin account is signed straight back out', () async {
    await expectLater(
      controller().signIn(email: 'guest@test.dev', password: 'guest-pass'),
      throwsA(isA<NotAdminException>()),
    );
    await pumpEventQueue();
    expect(auth.signedIn, isFalse);
    expect(read().isAdmin, isFalse);
    expect(read().email, isNull);
  });

  test('signing out hides the admin controls again', () async {
    await controller().signIn(email: 'owner@test.dev', password: 'right-pass');
    await controller().signOut();
    await pumpEventQueue();
    expect(read().isAdmin, isFalse);
    expect(read().email, isNull);
  });

  test('a database permission error explains that only admins can edit', () {
    expect(
      describeError(Exception('new row violates row-level security policy (42501)')),
      'Only signed-in admin accounts can add, edit or delete products.',
    );
  });
}
