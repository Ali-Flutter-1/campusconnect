/// Application configuration sourced from compile-time environment values.
///
/// Values are injected via `--dart-define-from-file=env.json` (see
/// `env.example.json`). They are read with [String.fromEnvironment] so secrets
/// never live in source control. The Supabase anon key is safe to ship in the
/// client — row-level-security policies are what actually protect the data.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Whether the required Supabase credentials were provided at build time.
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
