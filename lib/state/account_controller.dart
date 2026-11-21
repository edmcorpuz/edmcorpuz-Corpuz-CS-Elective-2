import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(Supabase.instance.client),
);

final accountProvider = NotifierProvider<AccountController, AccountState>(AccountController.new);

class AccountState {
  const AccountState({this.user, this.isAdmin = false, this.roleLoaded = true, this.error});

  /// The signed-in person, or null when signed out.
  final AccountUser? user;

  /// True only for accounts whose profile has the admin role. The UI swaps
  /// screens on it; the database enforces the same rule with RLS.
  final bool isAdmin;

  /// False while the role is still being read after a sign-in, so the app
  /// can wait instead of flashing the customer screens at an admin.
  final bool roleLoaded;

  /// A sign-in that failed after leaving the app (the Google round trip).
  /// The auth screen shows it once, then clears it.
  final Object? error;

  bool get signedIn => user != null;
}

class AccountController extends Notifier<AccountState> {
  late AuthRepository _auth;

  /// Bumped on every state change so a slow, older role check can't
  /// overwrite a newer result.
  int _version = 0;

  @override
  AccountState build() {
    _auth = ref.watch(authRepositoryProvider);
    final sub = _auth.changes.listen(
      (_) => _recheck(),
      onError: (Object e) {
        if (ref.mounted) {
          state = AccountState(user: state.user, isAdmin: state.isAdmin, roleLoaded: state.roleLoaded, error: e);
        }
      },
    );
    ref.onDispose(sub.cancel);
    final user = _auth.currentUser;
    if (user != null) Future.microtask(_recheck);
    return AccountState(user: user, roleLoaded: user == null);
  }

  Future<void> signInWithEmail({required String email, required String password}) async {
    await _auth.signInWithEmail(email: email, password: password);
    await _recheck();
  }

  /// Returns false when the new account must confirm its email first.
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final signedIn = await _auth.signUp(email: email, password: password, firstName: firstName, lastName: lastName);
    if (signedIn) await _recheck();
    return signedIn;
  }

  /// On the web this leaves the page; the app reloads signed in.
  Future<void> signInWithGoogle() => _auth.signInWithGoogle();

  Future<void> signOut() async {
    await _auth.signOut();
    _version++;
    if (ref.mounted) state = const AccountState();
  }

  void clearError() {
    if (state.error != null) {
      state = AccountState(user: state.user, isAdmin: state.isAdmin, roleLoaded: state.roleLoaded);
    }
  }

  Future<void> _recheck() async {
    final version = ++_version;
    final user = _auth.currentUser;
    if (user != null && state.user?.id != user.id && ref.mounted) {
      state = AccountState(user: user, roleLoaded: false);
    }
    var admin = false;
    if (user != null) {
      try {
        admin = await _auth.isAdmin();
      } catch (_) {
        // Offline or profile missing: fall back to the customer screens.
      }
    }
    if (version != _version || !ref.mounted) return;
    state = AccountState(user: user, isAdmin: admin);
  }
}
