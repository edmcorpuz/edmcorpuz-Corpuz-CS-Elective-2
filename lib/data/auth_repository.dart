import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Where the sign-in provider sends people back to after they approve.
/// Every value here must be listed under Supabase → Authentication →
/// URL Configuration → Redirect URLs.
const kMobileAuthRedirect = 'io.supabase.facetshop://login-callback/';

/// The signed-in person, in the shape the UI needs.
class AccountUser {
  const AccountUser({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
    this.provider = 'email',
  });

  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;

  /// How they signed in: `email` or `google`.
  final String provider;

  String get displayName => name ?? email ?? 'Your account';

  String get providerLabel => switch (provider) {
        'google' => 'Google',
        'email' => 'email',
        _ => provider,
      };
}

/// Sign-up and sign-in for customers and admins. Every new account is a
/// customer; an account's role lives in `public.profiles`.
abstract interface class AuthRepository {
  /// Fires whenever someone signs in or out, including when a saved session
  /// is restored or a Google sign-in returns. Sign-in failures from the
  /// Google round trip arrive as stream errors.
  Stream<void> get changes;

  AccountUser? get currentUser;

  Future<void> signInWithEmail({required String email, required String password});

  /// Creates a customer account. Returns false when Supabase wants the email
  /// confirmed before the first sign-in.
  Future<bool> signUp({required String email, required String password, required String fullName});

  /// Sends the browser (or the in-app browser on phones) to Google. The
  /// result arrives later through [changes].
  Future<void> signInWithGoogle();

  Future<void> signOut();

  /// Whether the signed-in account's profile has the admin role.
  Future<bool> isAdmin();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<void> get changes => _client.auth.onAuthStateChange.map((_) {});

  @override
  AccountUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final meta = user.userMetadata ?? const {};
    String? text(String key) {
      final value = meta[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    // Supabase joins a Google sign-in to an existing account with the same
    // email, so one account can have several identities. Report the one
    // used most recently, not the account's first provider.
    final identities = [...?user.identities]
      ..sort((a, b) => (b.lastSignInAt ?? '').compareTo(a.lastSignInAt ?? ''));

    return AccountUser(
      id: user.id,
      email: user.email,
      name: text('full_name') ?? text('name') ?? text('user_name'),
      avatarUrl: text('avatar_url'),
      provider: identities.isNotEmpty
          ? identities.first.provider
          : (user.appMetadata['provider'] as String?) ?? 'email',
    );
  }

  @override
  Future<void> signInWithEmail({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  @override
  Future<bool> signUp({required String email, required String password, required String fullName}) async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
      emailRedirectTo: kIsWeb ? _webReturnUrl() : kMobileAuthRedirect,
    );
    return res.session != null;
  }

  @override
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? _webReturnUrl() : kMobileAuthRedirect,
    );
  }

  /// The page the app is running on, without any query or fragment, so the
  /// same build works on localhost and on GitHub Pages.
  static String _webReturnUrl() => '${Uri.base.origin}${Uri.base.path}';

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<bool> isAdmin() async {
    final id = _client.auth.currentUser?.id;
    if (id == null) return false;
    final row = await _client.from('profiles').select('roles(name)').eq('id', id).maybeSingle();
    return (row?['roles'] as Map?)?['name'] == 'admin';
  }
}
