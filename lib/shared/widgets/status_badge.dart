import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/provider_profile.dart';
import '../models/service_request.dart';

/// Semantic, accessible status badge for order and provider states
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.fromOrderStatus(OrderStatus status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case OrderStatus.requested:
        bg = AppColors.border;
        fg = AppColors.textSecondary;
        icon = Icons.schedule;
        break;
      case OrderStatus.reviewing:
        bg = AppColors.infoBackground;
        fg = AppColors.info;
        icon = Icons.manage_search;
        break;
      case OrderStatus.assigned:
        bg = AppColors.warningBackground;
        fg = AppColors.warning;
        icon = Icons.person_pin;
        break;
      case OrderStatus.accepted:
        bg = const Color(0xFFF3E8FF);
        fg = AppColors.statusAccepted;
        icon = Icons.thumb_up_alt_outlined;
        break;
      case OrderStatus.travelling:
        bg = const Color(0xFFCCFBF1);
        fg = AppColors.statusTravelling;
        icon = Icons.directions_bike;
        break;
      case OrderStatus.inProgress:
        bg = const Color(0xFFDBEAFE);
        fg = AppColors.statusInProgress;
        icon = Icons.construction;
        break;
      case OrderStatus.completed:
        bg = AppColors.successBackground;
        fg = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.cancelled:
        bg = AppColors.errorBackground;
        fg = AppColors.error;
        icon = Icons.cancel_outlined;
        break;
      case OrderStatus.disputed:
        bg = const Color(0xFFFEE2E2);
        fg = AppColors.statusDisputed;
        icon = Icons.report_problem_outlined;
        break;
    }

    return StatusBadge(
      label: status.label,
      backgroundColor: bg,
      textColor: fg,
      icon: icon,
    );
  }

  factory StatusBadge.fromVerificationStatus(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.approved:
        return const StatusBadge(
          label: 'Verified Professional',
          backgroundColor: AppColors.successBackground,
          textColor: AppColors.success,
          icon: Icons.verified,
        );
      case VerificationStatus.pending:
        return const StatusBadge(
          label: 'Pending Verification',
          backgroundColor: AppColors.warningBackground,
          textColor: AppColors.warning,
          icon: Icons.hourglass_top,
        );
      case VerificationStatus.rejected:
        return const StatusBadge(
          label: 'Application Rejected',
          backgroundColor: AppColors.errorBackground,
          textColor: AppColors.error,
          icon: Icons.highlight_off,
        );
      case VerificationStatus.suspended:
        return const StatusBadge(
          label: 'Account Suspended',
          backgroundColor: AppColors.errorBackground,
          textColor: AppColors.error,
          icon: Icons.block,
        );
    }
  }

  factory StatusBadge.fromAvailabilityStatus(AvailabilityStatus status) {
    switch (status) {
      case AvailabilityStatus.available:
        return const StatusBadge(
          label: 'Online & Available',
          backgroundColor: AppColors.successBackground,
          textColor: AppColors.success,
          icon: Icons.radio_button_checked,
        );
      case AvailabilityStatus.busy:
        return const StatusBadge(
          label: 'On a Job',
          backgroundColor: AppColors.infoBackground,
          textColor: AppColors.info,
          icon: Icons.engineering,
        );
      case AvailabilityStatus.unavailable:
        return const StatusBadge(
          label: 'Offline',
          backgroundColor: AppColors.border,
          textColor: AppColors.textMuted,
          icon: Icons.radio_button_off,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14.0, color: textColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
