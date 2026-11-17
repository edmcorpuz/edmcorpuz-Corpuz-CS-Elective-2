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

  /// How they signed in: `email` or `github`.
  final String provider;

  String get displayName => name ?? email ?? 'Your account';

  String get providerLabel => switch (provider) {
        'github' => 'GitHub',
        'email' => 'email',
        _ => provider,
      };
}

/// Sign-in for shoppers and admins. Anyone can browse without an account;
/// only accounts listed in `public.admins` may change the catalogue.
abstract interface class AuthRepository {
  /// Fires whenever someone signs in or out, including when a saved session
  /// is restored or a GitHub sign-in returns. Sign-in failures from the
  /// GitHub round trip arrive as stream errors.
  Stream<void> get changes;

  AccountUser? get currentUser;

  Future<void> signInWithEmail({required String email, required String password});

  /// Sends the browser (or the in-app browser on phones) to GitHub. The
  /// result arrives later through [changes].
  Future<void> signInWithGitHub();

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
  AccountUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final meta = user.userMetadata ?? const {};
    String? text(String key) {
      final value = meta[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    // Supabase joins a GitHub sign-in to an existing account with the same
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
  Future<void> signInWithGitHub() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.github,
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
    // RLS only lets an account read its own row, so this finds a row only
    // when the signed-in account is an admin.
    final row = await _client.from('admins').select('user_id').eq('user_id', id).maybeSingle();
    return row != null;
  }
}
