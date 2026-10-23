/// Global application configuration and environment constants
class AppConfig {
  AppConfig._();

  static const String appName = 'NexHelp';
  static const String appTagline = 'Trusted Local Home Services';

  // Supabase Configuration
  // Can be overridden via --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_anon_key_for_local_development',
  );

  // Pilot Region Configuration
  static const String pilotCity = 'Bengaluru';
  static const String pilotState = 'Karnataka';
  static const String pilotPincode = '560102';
  static const String pilotAreaName =
      'Bengaluru South — HSR & Koramangala Pilot Sector';
  static const String pilotAreaId = 'a0000000-0000-0000-0000-000000000001';

  // Seed Categories
  static const String plumbingCategoryId =
      'c0000000-0000-0000-0000-000000000001';
  static const String electricalCategoryId =
      'c0000000-0000-0000-0000-000000000002';

  // Operational Constraints
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 2000;
  static const int minAddressLength = 5;
  static const int maxNotesLength = 1000;
}
