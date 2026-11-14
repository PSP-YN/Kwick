import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_mode.dart';

Future<void> main() => bootstrapKwick(KwickAppMode.customer);

Future<void> bootstrapKwick(KwickAppMode mode) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.hasValidSupabaseConfig) {
    runApp(_BackendConfigurationRequiredApp(mode: mode));
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (error, stackTrace) {
    debugPrint('Kwick backend initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(_BackendConfigurationRequiredApp(mode: mode));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [kwickAppModeProvider.overrideWithValue(mode)],
      child: KwickApp(mode: mode),
    ),
  );
}

class _BackendConfigurationRequiredApp extends StatelessWidget {
  const _BackendConfigurationRequiredApp({required this.mode});

  final KwickAppMode mode;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17212B);
    const gold = Color(0xFFF4A900);

    return MaterialApp(
      title: '${mode.displayName} setup required',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: gold),
        scaffoldBackgroundColor: const Color(0xFFFAF9F5),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8E5DC)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          color: ink,
                          size: 42,
                        ),
                        const SizedBox(height: 22),
                        Text(
                          '${mode.displayName} is not connected yet',
                          style: const TextStyle(
                            color: ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This build is missing a valid Kwick backend configuration. Accounts, provider verification and bookings remain unavailable until the Kwick Supabase project is configured.',
                          style: TextStyle(
                            color: Color(0xFF5D6670),
                            height: 1.6,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Required build configuration',
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const SelectableText(
                          'SUPABASE_URL=https://<project-ref>.supabase.co\nSUPABASE_ANON_KEY=<public-anon-or-publishable-key>',
                          style: TextStyle(
                            color: ink,
                            fontFamily: 'monospace',
                            fontSize: 11,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Never put a service-role key or AI provider key in either mobile app. Keep privileged secrets on the server.',
                          style: TextStyle(
                            color: Color(0xFF7A6250),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
