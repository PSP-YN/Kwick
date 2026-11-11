import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.hasValidSupabaseConfig) {
    runApp(const _BackendConfigurationRequiredApp());
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (error, stackTrace) {
    debugPrint('NexHelp backend initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(const _BackendConfigurationRequiredApp());
    return;
  }

  runApp(const ProviderScope(child: NexHelpApp()));
}

class _BackendConfigurationRequiredApp extends StatelessWidget {
  const _BackendConfigurationRequiredApp();

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF172B25);
    const green = Color(0xFF1F5948);

    return MaterialApp(
      title: 'NexHelp setup required',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF7F7F2),
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
                    border: Border.all(color: const Color(0xFFE2E7DE)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          color: green,
                          size: 42,
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'NexHelp is not connected yet',
                          style: TextStyle(
                            color: ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This app build is missing a valid NexHelp backend configuration. No bookings or account data can be loaded until the dedicated Supabase project is configured.',
                          style: TextStyle(
                            color: Color(0xFF5D6B63),
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
                        SelectableText(
                          'SUPABASE_URL=https://<project-ref>.supabase.co\n'
                          'SUPABASE_ANON_KEY=<public-anon-or-publishable-key>',
                          style: TextStyle(
                            color: green,
                            fontFamily: 'monospace',
                            fontSize: 11,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Do not put a service-role key or Gemini API key in this app. Configure secrets only in the trusted server environment.',
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
