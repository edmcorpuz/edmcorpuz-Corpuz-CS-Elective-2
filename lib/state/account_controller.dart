import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(Supabase.instance.client),
);

final accountProvider = NotifierProvider<AccountController, AccountState>(AccountController.new);

class AccountState {
  const AccountState({this.user, this.isAdmin = false, this.error});

  /// The signed-in person, or null for visitors.
  final AccountUser? user;

  /// True only for accounts listed in `public.admins`. The UI shows the
  /// add/edit/delete controls only then; the database enforces the same rule.
  final bool isAdmin;

  /// A sign-in that failed after leaving the app (for example, the GitHub
  /// round trip). The shop shows it once, then clears it.
  final Object? error;

  bool get signedIn => user != null;
}

class AccountController extends Notifier<AccountState> {
  late AuthRepository _auth;

  /// Bumped on every state change so a slow, older admin check can't
  /// overwrite a newer result.
  int _version = 0;

  @override
  AccountState build() {
    _auth = ref.watch(authRepositoryProvider);
    final sub = _auth.changes.listen(
      (_) => _recheck(),
      onError: (Object e) {
        if (ref.mounted) state = AccountState(user: state.user, isAdmin: state.isAdmin, error: e);
      },
    );
    ref.onDispose(sub.cancel);
    final user = _auth.currentUser;
    if (user != null) Future.microtask(_recheck);
    return AccountState(user: user);
  }

  Future<void> signInWithEmail({required String email, required String password}) async {
    await _auth.signInWithEmail(email: email, password: password);
    await _recheck();
  }

  /// On the web this leaves the page; the app reloads signed in.
  Future<void> signInWithGitHub() => _auth.signInWithGitHub();

  Future<void> signOut() async {
    await _auth.signOut();
    _version++;
    if (ref.mounted) state = const AccountState();
  }

  void clearError() {
    if (state.error != null) state = AccountState(user: state.user, isAdmin: state.isAdmin);
  }

  Future<void> _recheck() async {
    final version = ++_version;
    final user = _auth.currentUser;
    var admin = false;
    if (user != null) {
      try {
        admin = await _auth.isAdmin();
      } catch (_) {
        // Offline or tables missing: treat as a regular shopper.
      }
    }
    if (version != _version || !ref.mounted) return;
    state = AccountState(user: user, isAdmin: admin);
  }
}
