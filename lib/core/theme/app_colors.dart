import 'package:flutter/material.dart';

/// Kwick brand tokens derived from the supplied black-and-saffron logo.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF17212B); // Graphite ink
  static const Color primaryLight = Color(0xFF354452);
  static const Color primaryDark = Color(0xFF0D141B);
  static const Color secondary = Color(0xFFF4A900); // Kwick saffron
  static const Color secondaryLight = Color(0xFFFFC247);
  static const Color secondaryDark = Color(0xFFB97900);

  // Status & feedback
  static const Color success = Color(0xFF16845B);
  static const Color successBackground = Color(0xFFEAF6EF);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningBackground = Color(0xFFFFF5DF);
  static const Color error = Color(0xFFB42318);
  static const Color errorBackground = Color(0xFFFEF0EE);
  static const Color info = Color(0xFF315B75);
  static const Color infoBackground = Color(0xFFEDF4F7);

  // Surfaces and typography
  static const Color background = Color(0xFFFAF9F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8E5DC);
  static const Color borderSubtle = Color(0xFFF1EFE8);
  static const Color textPrimary = Color(0xFF17212B);
  static const Color textSecondary = Color(0xFF5D6670);
  static const Color textMuted = Color(0xFF858D95);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Order lifecycle
  static const Color statusRequested = Color(0xFF687580);
  static const Color statusReviewing = Color(0xFF315B75);
  static const Color statusAssigned = Color(0xFFB7791F);
  static const Color statusAccepted = Color(0xFF3C6C5A);
  static const Color statusTravelling = Color(0xFF287A78);
  static const Color statusInProgress = Color(0xFF315B75);
  static const Color statusCompleted = Color(0xFF16845B);
  static const Color statusCancelled = Color(0xFFB42318);
  static const Color statusDisputed = Color(0xFF8F1D17);
}
