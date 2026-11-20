import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException, PostgrestException;
import 'package:unang_flutter_project/data/auth_repository.dart';
import 'package:unang_flutter_project/models/order.dart';
import 'package:unang_flutter_project/models/product.dart';
import 'package:unang_flutter_project/state/account_controller.dart';
import 'package:unang_flutter_project/state/bag_controller.dart';
import 'package:unang_flutter_project/three_d/appliances.dart';
import 'package:unang_flutter_project/widgets/product_form.dart' show describeError;

/// In-memory stand-in for Supabase Auth, the Google provider and the role
/// stored in `profiles`.
class FakeAuth implements AuthRepository {
  FakeAuth({required this.passwords, required this.admins});

  /// email -> password
  final Map<String, String> passwords;

  /// ids of admin accounts
  final Set<String> admins;
  final _changes = StreamController<void>.broadcast();
  AccountUser? _current;
  bool googleOpened = false;

  /// How long the role lookup takes, to observe the loading state.
  Duration roleDelay = Duration.zero;

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
  Future<bool> signUp({required String email, required String password, required String fullName}) async {
    if (passwords.containsKey(email)) throw const AuthException('User already registered', statusCode: '422');
    passwords[email] = password;
    _current = AccountUser(id: 'id-$email', email: email, name: fullName);
    _changes.add(null);
    return true;
  }

  @override
  Future<void> signInWithGoogle() async => googleOpened = true;

  /// What Supabase does when the browser comes back from Google.
  void returnFromGoogle({required String login, String? name}) {
    _current = AccountUser(
      id: 'g-$login',
      email: '$login@gmail.example',
      name: name,
      avatarUrl: 'https://avatars.example/$login.png',
      provider: 'google',
    );
    _changes.add(null);
  }

  void failGoogle(String message) => _changes.addError(AuthException(message));

  @override
  Future<void> signOut() async {
    _current = null;
    _changes.add(null);
  }

  @override
  Future<bool> isAdmin() async {
    await Future<void>.delayed(roleDelay);
    return _current != null && admins.contains(_current!.id);
  }
}

Product _item(int id, {int stock = 2}) => Product(
      id: id,
      name: 'Item $id',
      description: '',
      price: 100.0 * id,
      category: 'Kitchen',
      stock: stock,
      kind: ApplianceKind.kettle,
      colorHex: '#F2F2F2',
    );

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
    // Start listening, like the auth gate does.
    container.listen(accountProvider, (_, _) {});
    container.listen(bagProvider, (_, _) {});
  });

  AccountState read() => container.read(accountProvider);
  AccountController controller() => container.read(accountProvider.notifier);

  group('auth', () {
    test('visitors start signed out', () {
      expect(read().signedIn, isFalse);
      expect(read().isAdmin, isFalse);
    });

    test('an admin signing in with email gets admin tools', () async {
      await controller().signInWithEmail(email: 'owner@test.dev', password: 'right-pass');
      await pumpEventQueue();
      expect(read().user?.email, 'owner@test.dev');
      expect(read().isAdmin, isTrue);
    });

    test('a customer signs in without admin tools', () async {
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

    test('signing up creates a customer account and signs it in', () async {
      final signedIn = await controller().signUp(email: 'new@test.dev', password: 'secret1', fullName: 'New Person');
      await pumpEventQueue();
      expect(signedIn, isTrue);
      expect(read().user?.displayName, 'New Person');
      expect(read().isAdmin, isFalse);
    });

    test('signing up twice with one email explains what to do', () async {
      await expectLater(
        controller().signUp(email: 'owner@test.dev', password: 'x12345', fullName: 'Dup'),
        throwsA(isA<AuthException>()
            .having(describeError, 'message', 'That email already has an account. Log in instead.')),
      );
    });

    test('Google sign-in opens Google, then the returning user is a customer', () async {
      await controller().signInWithGoogle();
      expect(auth.googleOpened, isTrue);

      auth.returnFromGoogle(login: 'juan', name: 'Juan Cruz');
      await pumpEventQueue();
      final user = read().user!;
      expect(user.displayName, 'Juan Cruz');
      expect(user.providerLabel, 'Google');
      expect(read().isAdmin, isFalse);
    });

    test('a Google account with the admin role gets admin tools', () async {
      auth.admins.add('g-owner');
      auth.returnFromGoogle(login: 'owner');
      await pumpEventQueue();
      expect(read().isAdmin, isTrue);
    });

    test('the gate waits for the role instead of guessing', () async {
      auth.roleDelay = const Duration(milliseconds: 30);
      auth.returnFromGoogle(login: 'slow');
      await Future<void>.delayed(Duration.zero);
      expect(read().signedIn, isTrue);
      expect(read().roleLoaded, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(read().roleLoaded, isTrue);
    });

    test('a cancelled Google sign-in is reported once, then cleared', () async {
      auth.failGoogle('access_denied: The user has denied your application access.');
      await pumpEventQueue();
      expect(describeError(read().error!), 'Google sign-in was cancelled.');
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
  });

  group('cart', () {
    test('keeps a running total and item count', () {
      final bag = container.read(bagProvider.notifier);
      bag.add(_item(1));
      bag.add(_item(1));
      bag.add(_item(2));
      expect(bag.count, 3);
      expect(bag.total, 400);
    });

    test('never goes above stock and refuses sold-out products', () {
      final bag = container.read(bagProvider.notifier);
      for (var i = 0; i < 5; i++) {
        bag.add(_item(1, stock: 2));
      }
      bag.add(_item(2, stock: 0));
      expect(container.read(bagProvider)[1]!.quantity, 2);
      expect(container.read(bagProvider).containsKey(2), isFalse);
    });

    test('changes quantity and removes lines', () {
      final bag = container.read(bagProvider.notifier);
      bag.add(_item(1));
      bag.add(_item(1));
      bag.decrement(1);
      expect(container.read(bagProvider)[1]!.quantity, 1);
      bag.remove(1);
      expect(container.read(bagProvider), isEmpty);
    });

    test('empties on logout', () async {
      await controller().signInWithEmail(email: 'shopper@test.dev', password: 'shop-pass');
      await pumpEventQueue();
      container.read(bagProvider.notifier).add(_item(1));
      expect(container.read(bagProvider), isNotEmpty);
      await controller().signOut();
      await pumpEventQueue();
      expect(container.read(bagProvider), isEmpty);
    });
  });

  group('orders', () {
    test('an order and its snapshot items read from the database response', () {
      final order = Order.fromMap({
        'id': 42,
        'status': 'done',
        'total': 1290,
        'created_at': '2026-11-20T06:05:00+00:00',
        'order_items': [
          {'product_name': 'Pop 2-Slice Toaster', 'unit_price': 645, 'quantity': 2},
        ],
        'profiles': {'email': 'juan@example.com', 'full_name': 'Juan Cruz'},
      });
      expect(order.id, 42);
      expect(order.itemCount, 2);
      expect(order.items.single.subtotal, 1290);
      expect(order.customerName, 'Juan Cruz');
    });

    test('checkout and permission errors read as plain sentences', () {
      expect(
        describeError(const PostgrestException(message: 'Only 1 left of Pop 2-Slice Toaster.', code: 'P0001')),
        'Only 1 left of Pop 2-Slice Toaster.',
      );
      expect(
        describeError(const PostgrestException(message: 'new row violates row-level security policy', code: '42501')),
        'Your account isn’t allowed to do that.',
      );
      expect(
        describeError(const PostgrestException(message: 'update or delete violates foreign key', code: '23503')),
        'That category still has products. Move or delete them first.',
      );
    });
  });
}
