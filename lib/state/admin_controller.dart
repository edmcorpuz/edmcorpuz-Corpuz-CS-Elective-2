import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(Supabase.instance.client),
);

final adminProvider = NotifierProvider<AdminController, AdminState>(AdminController.new);

class AdminState {
  const AdminState({this.email, this.isAdmin = false});

  /// Email of the signed-in account, or null for visitors.
  final String? email;

  /// True only for accounts listed in `public.admins`. The UI shows the
  /// add/edit/delete controls only then; the database enforces the same rule.
  final bool isAdmin;
}

class AdminController extends Notifier<AdminState> {
  late AuthRepository _auth;

  /// Bumped on every state change so a slow, older admin check can't
  /// overwrite a newer result.
  int _version = 0;

  @override
  AdminState build() {
    _auth = ref.watch(authRepositoryProvider);
    final sub = _auth.changes.listen((_) => _recheck());
    ref.onDispose(sub.cancel);
    return AdminState(email: _auth.currentEmail);
  }

  /// Signs in and keeps the session only if the account is an admin.
  /// Throws [NotAdminException] for any other account.
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signIn(email: email, password: password);
    final bool admin;
    try {
      admin = await _auth.isAdmin();
    } catch (_) {
      await _signOutQuietly();
      rethrow;
    }
    if (!admin) {
      await _signOutQuietly();
      throw const NotAdminException();
    }
    _set(AdminState(email: _auth.currentEmail, isAdmin: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _set(const AdminState());
  }

  Future<void> _signOutQuietly() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    _set(const AdminState());
  }

  void _set(AdminState next) {
    _version++;
    if (ref.mounted) state = next;
  }

  Future<void> _recheck() async {
    final version = ++_version;
    final email = _auth.currentEmail;
    var admin = false;
    if (_auth.signedIn) {
      try {
        admin = await _auth.isAdmin();
      } catch (_) {
        // Offline or tables missing: hide the admin controls.
      }
    }
    if (version != _version || !ref.mounted) return;
    state = AdminState(email: email, isAdmin: admin);
  }
}
