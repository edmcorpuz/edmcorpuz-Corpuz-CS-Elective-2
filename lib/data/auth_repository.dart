import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when someone signs in with an account that isn't in `public.admins`.
class NotAdminException implements Exception {
  const NotAdminException();

  @override
  String toString() => 'This account isn’t a store admin, so it can’t change products.';
}

/// Sign-in for store admins. Visitors never need an account: they can browse
/// the catalogue, and only accounts listed in `public.admins` may change it.
abstract interface class AuthRepository {
  /// Fires whenever someone signs in or out, including when a saved session
  /// is restored on startup.
  Stream<void> get changes;

  String? get currentEmail;

  bool get signedIn;

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  /// Whether the signed-in account has a row in `public.admins`.
  Future<bool> isAdmin();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<void> get changes => _client.auth.onAuthStateChange.map((_) {});

  @override
  String? get currentEmail => _client.auth.currentUser?.email;

  @override
  bool get signedIn => _client.auth.currentUser != null;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<bool> isAdmin() async {
    final id = _client.auth.currentUser?.id;
    if (id == null) return false;
    // RLS only lets an account read its own row, so this finds a row only
    // when the signed-in account is an admin.
    final row = await _client.from('admins').select('user_id').eq('user_id', id).maybeSingle();
    return row != null;
  }
}
