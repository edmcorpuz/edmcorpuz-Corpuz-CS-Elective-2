/// Supabase settings, passed at build time from `env.json`:
///
///   flutter run --dart-define-from-file=env.json
///
/// `env.json` is git-ignored; copy `env.example.json` to create it.
/// The key is the project's publishable key (`sb_publishable_…`); the
/// legacy `anon` key also works.
class Env {
  Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
