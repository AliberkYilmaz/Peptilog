class AppConstants {
  static const String bundleId = 'com.peptilog.app';
  static const String appName = 'Peptilog';
  static const String appVersion = '1.0.0';

  // Supabase — set via environment / build config
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
}
