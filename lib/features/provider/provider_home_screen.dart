import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utilities/date_formatter.dart';
import '../../../shared/models/assignment.dart';
import '../../../shared/models/provider_profile.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../auth/auth_controller.dart';
import 'provider_controller.dart';

class ProviderHomeScreen extends ConsumerStatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  ConsumerState<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends ConsumerState<ProviderHomeScreen> {
  bool _isTogglingAvailability = false;

  Future<void> _toggleAvailability(ProviderProfile prov, bool goOnline) async {
    setState(() => _isTogglingAvailability = true);
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final newStatus = goOnline
          ? AvailabilityStatus.available
          : AvailabilityStatus.unavailable;
      await supabase.updateProviderAvailability(prov.id, newStatus);
      ref.invalidate(providerProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingAvailability = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.userProfile;
    final providerAsync = ref.watch(providerProfileProvider);
    final assignmentsAsync = ref.watch(providerAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/branding/kwick_mark.png',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 8),
            const Text('Kwick Partner'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(providerProfileProvider);
          ref.invalidate(providerAssignmentsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingScreen,
          child: providerAsync.when(
            data: (prov) {
              if (prov == null) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () => context.go('/provider/onboarding'),
                    child: const Text('Complete Onboarding'),
                  ),
                );
              }

              // Check if unapproved
              if (!prov.isApproved) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        StatusBadge.fromVerificationStatus(
                          prov.verificationStatus,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Application Under Verification',
                          style: AppTextStyles.headingMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'You cannot accept job requests until our operations team verifies your background.',
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton(
                          onPressed: () => context.go('/provider/onboarding'),
                          child: const Text('View Application Details'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Provider Profile & Availability Switch Card
                  Card(
                    child: Padding(
                      padding: AppSpacing.paddingCard,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24.0,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                child: const Icon(
                                  Icons.handyman,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? 'Service Professional',
                                      style: AppTextStyles.headingSmall,
                                    ),
                                    const SizedBox(height: 2.0),
                                    StatusBadge.fromVerificationStatus(
                                      prov.verificationStatus,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24.0),

                          // Online / Offline Switch
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Availability for Jobs',
                                    style: AppTextStyles.label,
                                  ),
                                  const SizedBox(height: 2.0),
                                  StatusBadge.fromAvailabilityStatus(
                                    prov.availabilityStatus,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (_isTogglingAvailability)
                                const LoadingIndicator(size: 20.0)
                              else
                                Switch(
                                  value: prov.isAvailable,
                                  onChanged: (val) =>
                                      _toggleAvailability(prov, val),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/provider/pricing'),
                    icon: const Icon(Icons.currency_rupee),
                    label: const Text('Manage Services & Pricing'),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Job Assignments List
                  Text(
                    'Job Requests & Assignments',
                    style: AppTextStyles.headingMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  assignmentsAsync.when(
                    data: (assignments) {
                      if (assignments.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: const EmptyStateView(
                              icon: Icons.work_outline,
                              title: 'No Job Assignments Yet',
                              message:
                                  'Keep your status set to Online. New plumbing and electrical jobs will appear here when assigned.',
                            ),
                          ),
                        );
                      }

                      // Check if there is an offered or active job
                      final offered = assignments
                          .where((a) => a.status == AssignmentStatus.offered)
                          .toList();
                      final active = assignments
                          .where((a) => a.status == AssignmentStatus.accepted)
                          .toList();
                      final completed = assignments
                          .where(
                            (a) =>
                                a.status == AssignmentStatus.completed ||
                                a.status == AssignmentStatus.declined,
                          )
                          .toList();

                      return Column(
                        children: [
                          // Urgent Offered Jobs Banner
                          if (offered.isNotEmpty) ...[
                            ...offered.map(
                              (assign) => _OfferedJobBanner(assignment: assign),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          // Active in-progress jobs
                          if (active.isNotEmpty) ...[
                            ...active.map(
                              (assign) => _ActiveJobCard(assignment: assign),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          // Past jobs
                          if (completed.isNotEmpty) ...[
                            Text('Past Jobs', style: AppTextStyles.label),
                            const SizedBox(height: AppSpacing.xs),
                            ...completed.map(
                              (assign) => _JobHistoryItem(assignment: assign),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const LoadingIndicator(),
                    error: (err, _) => ErrorStateView(
                      message: err.toString(),
                      onRetry: () =>
                          ref.invalidate(providerAssignmentsProvider),
                    ),
                  ),
                ],
              );
            },
            loading: () => const LoadingIndicator(),
            error: (err, _) => ErrorStateView(
              message: err.toString(),
              onRetry: () => ref.invalidate(providerProfileProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferedJobBanner extends StatelessWidget {
  final Assignment assignment;

  const _OfferedJobBanner({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.warning, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'New Job Offered!',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
              const Spacer(),
              Text(
                DateFormatter.formatRelative(assignment.assignedAt),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'A customer booking matching your trade has been assigned to you by Kwick dispatch.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.textInverse,
            ),
            onPressed: () =>
                context.push('/provider/assignments/${assignment.id}'),
            child: const Text('Review & Respond to Job'),
          ),
        ],
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  final Assignment assignment;

  const _ActiveJobCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: AppSpacing.roundedMd,
        onTap: () => context.push('/provider/assignments/${assignment.id}'),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successBackground,
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Text(
                      'Active Accepted Job',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14.0,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Job ID: ${assignment.requestId.substring(0, 8)}',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Assigned on ${DateFormatter.formatDateTime(assignment.assignedAt)}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.touch_app,
                    size: 16.0,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Tap to update progress or complete job',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobHistoryItem extends StatelessWidget {
  final Assignment assignment;

  const _JobHistoryItem({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(
          'Job #${assignment.requestId.substring(0, 8)}',
          style: AppTextStyles.bodyLarge,
        ),
        subtitle: Text(
          DateFormatter.formatDateTime(assignment.assignedAt),
          style: AppTextStyles.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: assignment.status == AssignmentStatus.completed
                ? AppColors.successBackground
                : AppColors.border,
            borderRadius: AppSpacing.roundedSm,
          ),
          child: Text(
            assignment.status.label,
            style: AppTextStyles.bodySmall.copyWith(
              color: assignment.status == AssignmentStatus.completed
                  ? AppColors.success
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
