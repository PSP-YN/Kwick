import 'package:flutter/material.dart';

/// Design tokens: Curated, accessible color palette for NexHelp
class AppColors {
  AppColors._();

  // Brand Primaries
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF172554);

  // Secondary / Accent
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color secondaryLight = Color(0xFF14B8A6);

  // Status & Feedback
  static const Color success = Color(0xFF059669); // Emerald
  static const Color successBackground = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFD97706); // Amber
  static const Color warningBackground = Color(0xFFFFFBEB);

  static const Color error = Color(0xFFDC2626); // Rose/Crimson
  static const Color errorBackground = Color(0xFFFEF2F2);

  static const Color info = Color(0xFF0284C7); // Sky
  static const Color infoBackground = Color(0xFFF0F9FF);

  // Neutrals & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Specific Order Status Colors
  static const Color statusRequested = Color(0xFF64748B); // Slate
  static const Color statusReviewing = Color(0xFF0284C7); // Sky
  static const Color statusAssigned = Color(0xFFD97706); // Amber
  static const Color statusAccepted = Color(0xFF7C3AED); // Purple
  static const Color statusTravelling = Color(0xFF0D9488); // Teal
  static const Color statusInProgress = Color(0xFF2563EB); // Blue
  static const Color statusCompleted = Color(0xFF059669); // Emerald
  static const Color statusCancelled = Color(0xFFDC2626); // Red
  static const Color statusDisputed = Color(0xFFB91C1C); // Dark Red
}
