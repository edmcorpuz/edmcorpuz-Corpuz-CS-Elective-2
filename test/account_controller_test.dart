import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:unang_flutter_project/data/auth_repository.dart';
import 'package:unang_flutter_project/state/account_controller.dart';
import 'package:unang_flutter_project/widgets/product_form.dart' show describeError;

/// In-memory stand-in for Supabase Auth, the GitHub provider and the
/// `admins` table.
class FakeAuth implements AuthRepository {
  FakeAuth({required this.passwords, required this.admins});

  /// email -> password
  final Map<String, String> passwords;

  /// ids of admin accounts
  final Set<String> admins;
  final _changes = StreamController<void>.broadcast();
  AccountUser? _current;
  bool githubOpened = false;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  AccountUser? get currentUser => _current;

  @override
  Future<void> signInWithEmail({required String email, required String password}) async {
    if (passwords[email] != password) {
      throw const AuthException('Invalid login credentials', statusCode: '400');
    }
    _current = AccountUser(id: 'id-$email', email: email);
    _changes.add(null);
  }

  @override
  Future<void> signInWithGitHub() async => githubOpened = true;

  /// What Supabase does when the browser comes back from GitHub.
  void returnFromGitHub({required String login, String? name}) {
    _current = AccountUser(
      id: 'gh-$login',
      email: '$login@users.example',
      name: name,
      avatarUrl: 'https://avatars.example/$login.png',
      provider: 'github',
    );
    _changes.add(null);
  }

  void failGitHub(String message) => _changes.addError(AuthException(message));

  @override
  Future<void> signOut() async {
    _current = null;
    _changes.add(null);
  }

  @override
  Future<bool> isAdmin() async => _current != null && admins.contains(_current!.id);
}

void main() {
  late FakeAuth auth;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuth(
      passwords: {'owner@test.dev': 'right-pass', 'shopper@test.dev': 'shop-pass'},
      admins: {'id-owner@test.dev'},
    );
    container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(auth)]);
    addTearDown(container.dispose);
    // Start listening, like the shop screen does.
    container.listen(accountProvider, (_, _) {});
  });

  AccountState read() => container.read(accountProvider);
  AccountController controller() => container.read(accountProvider.notifier);

  test('visitors start signed out', () {
    expect(read().signedIn, isFalse);
    expect(read().isAdmin, isFalse);
  });

  test('an admin signing in with email unlocks editing', () async {
    await controller().signInWithEmail(email: 'owner@test.dev', password: 'right-pass');
    await pumpEventQueue();
    expect(read().user?.email, 'owner@test.dev');
    expect(read().isAdmin, isTrue);
  });

  test('a regular shopper signs in without admin tools', () async {
    await controller().signInWithEmail(email: 'shopper@test.dev', password: 'shop-pass');
    await pumpEventQueue();
    expect(read().signedIn, isTrue);
    expect(read().isAdmin, isFalse);
  });

  test('a wrong password is rejected with a readable message', () async {
    await expectLater(
      controller().signInWithEmail(email: 'owner@test.dev', password: 'nope'),
      throwsA(isA<AuthException>().having(describeError, 'message', 'Wrong email or password.')),
    );
    expect(read().signedIn, isFalse);
  });

  test('GitHub sign-in opens GitHub, then the returning user is signed in', () async {
    await controller().signInWithGitHub();
    expect(auth.githubOpened, isTrue);

    auth.returnFromGitHub(login: 'octo', name: 'Octo Cat');
    await pumpEventQueue();
    final user = read().user!;
    expect(user.displayName, 'Octo Cat');
    expect(user.providerLabel, 'GitHub');
    expect(user.avatarUrl, isNotNull);
    expect(read().isAdmin, isFalse);
  });

  test('a GitHub user listed in admins gets admin tools', () async {
    auth.admins.add('gh-owner');
    auth.returnFromGitHub(login: 'owner');
    await pumpEventQueue();
    expect(read().isAdmin, isTrue);
  });

  test('a cancelled GitHub sign-in is reported once, then cleared', () async {
    auth.failGitHub('access_denied: The user has denied your application access.');
    await pumpEventQueue();
    expect(describeError(read().error!), 'GitHub sign-in was cancelled.');
    controller().clearError();
    expect(read().error, isNull);
    expect(read().signedIn, isFalse);
  });

  test('signing out clears the account and admin tools', () async {
    await controller().signInWithEmail(email: 'owner@test.dev', password: 'right-pass');
    await controller().signOut();
    await pumpEventQueue();
    expect(read().signedIn, isFalse);
    expect(read().isAdmin, isFalse);
  });

  test('a database permission error explains that only admins can edit', () {
    expect(
      describeError(Exception('new row violates row-level security policy (42501)')),
      'Only signed-in admin accounts can add, edit or delete products.',
    );
  });
}
