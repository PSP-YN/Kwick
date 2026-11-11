import 'package:flutter/foundation.dart';

/// Global application configuration and environment constants
class AppConfig {
  AppConfig._();

  static const String appName = 'NexHelp';
  static const String appTagline = 'Trusted Local Home Services';

  // Supply project-specific values with --dart-define at build/run time.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_anon_key_for_local_development',
  );

  /// Accepts HTTPS hosted projects in every build and local emulator URLs only
  /// in debug/profile builds. CI placeholders and dummy keys are always rejected.
  static bool get hasValidSupabaseConfig {
    final isHttpsProjectUrl = supabaseUrl.startsWith('https://') &&
        supabaseUrl.endsWith('.supabase.co');
    final isLocalDevelopmentUrl = !kReleaseMode &&
        !kProfileMode &&
        (supabaseUrl == 'http://10.0.2.2:54321' ||
            supabaseUrl == 'http://127.0.0.1:54321');
    final hasPublicKey = supabaseAnonKey.startsWith('eyJ') ||
        supabaseAnonKey.startsWith('sb_publishable_');
    final isKnownPlaceholder = supabaseAnonKey.contains('dummy_') ||
        supabaseAnonKey == 'ci-placeholder';

    return (isHttpsProjectUrl || isLocalDevelopmentUrl) &&
        hasPublicKey &&
        !isKnownPlaceholder;
  }

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
  static const int maxAddressLength = 1000;
  static const int maxNotesLength = 1000;
}
