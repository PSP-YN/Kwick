import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_mode.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class KwickApp extends ConsumerWidget {
  const KwickApp({super.key, required this.mode});

  final KwickAppMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: mode.displayName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
