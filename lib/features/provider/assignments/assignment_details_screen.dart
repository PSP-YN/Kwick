import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../core/utilities/date_formatter.dart';
import '../../../shared/models/assignment.dart';
import '../../../shared/models/service_request.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../customer/customer_controller.dart';
import '../provider_controller.dart';

class AssignmentDetailsScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const AssignmentDetailsScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailsScreen> createState() =>
      _AssignmentDetailsScreenState();
}

class _AssignmentDetailsScreenState
    extends ConsumerState<AssignmentDetailsScreen> {
  bool _isProcessing = false;

  Future<void> _respondToJob(bool accept) async {
    String? declineReason;
    if (!accept) {
      final reasonController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Decline Job Assignment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please state the reason for declining this request:'),
              const SizedBox(height: 8.0),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'E.g., Currently occupied / Outside area',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Decline'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      declineReason = reasonController.text.trim();
    }

    setState(() => _isProcessing = true);
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.respondToAssignment(
        assignmentId: widget.assignmentId,
        accept: accept,
        declineReason: declineReason,
      );

      ref.invalidate(providerAssignmentsProvider);
      ref.invalidate(providerProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'Job accepted! Please proceed to the address.'
                  : 'Job declined.',
            ),
            backgroundColor: accept ? AppColors.success : AppColors.textPrimary,
          ),
        );
        if (!accept) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _progressJob(
    String requestId,
    String newStatus, [
    int? finalPriceMinor,
  ]) async {
    setState(() => _isProcessing = true);
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.progressServiceRequest(
        requestId: requestId,
        newStatus: newStatus,
        finalPriceMinor: finalPriceMinor,
      );

      ref.invalidate(providerAssignmentsProvider);
      ref.invalidate(requestDetailsProvider(requestId));
      ref.invalidate(providerProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _completeJobWithPrice(String requestId, int? quotedPaise) async {
    final priceController = TextEditingController(
      text: quotedPaise != null
          ? (quotedPaise / 100.0).toStringAsFixed(0)
          : '350',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Service Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm the final bill amount collected from the customer:',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                labelText: 'Final Amount (INR)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Completion'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final amount = double.tryParse(priceController.text.trim()) ?? 0.0;
      final paise = CurrencyFormatter.rupeesToPaise(amount);
      await _progressJob(requestId, 'completed', paise);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(providerAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Assignment Details')),
      body: assignmentsAsync.when(
        data: (assignments) {
          final assignment = assignments
              .where((a) => a.id == widget.assignmentId)
              .firstOrNull;
          if (assignment == null) {
            return const Center(child: Text('Assignment record not found.'));
          }

          final requestAsync = ref.watch(
            requestDetailsProvider(assignment.requestId),
          );

          return requestAsync.when(
            data: (req) {
              if (req == null) {
                return const Center(
                  child: Text('Associated service request not found.'),
                );
              }

              return SingleChildScrollView(
                padding: AppSpacing.paddingScreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Card(
                      child: Padding(
                        padding: AppSpacing.paddingCard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StatusBadge.fromOrderStatus(req.status),
                                const Spacer(),
                                Text(
                                  'Assignment: ${assignment.status.label}',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              req.categoryName ?? 'Service Job',
                              style: AppTextStyles.headingLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Assigned on ${DateFormatter.formatDateTime(assignment.assignedAt)}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Customer & Location Card
                    Card(
                      child: Padding(
                        padding: AppSpacing.paddingCard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Job Location & Customer',
                              style: AppTextStyles.headingSmall,
                            ),
                            const Divider(height: 24.0),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: 22.0,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    '${req.addressLine}\nPincode: ${req.pincode} (Bengaluru South)',
                                    style: AppTextStyles.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20.0,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Work Required:',
                                        style: AppTextStyles.label,
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        req.description,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (req.customerNotes != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.notes,
                                    color: AppColors.textSecondary,
                                    size: 20.0,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Customer Instructions:',
                                          style: AppTextStyles.label,
                                        ),
                                        Text(
                                          req.customerNotes!,
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Pricing Guidance Card
                    Card(
                      child: Padding(
                        padding: AppSpacing.paddingCard,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimated Payment',
                              style: AppTextStyles.bodyLarge,
                            ),
                            Text(
                              CurrencyFormatter.formatPaise(
                                req.finalPriceMinor ?? req.quotedPriceMinor,
                              ),
                              style: AppTextStyles.headingMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Action Controls Based on Status
                    if (assignment.status == AssignmentStatus.offered) ...[
                      PrimaryButton(
                        label: 'Accept Job Assignment',
                        icon: Icons.check,
                        isLoading: _isProcessing,
                        onPressed: _isProcessing
                            ? null
                            : () => _respondToJob(true),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SecondaryButton(
                        label: 'Decline Job',
                        icon: Icons.close,
                        onPressed: _isProcessing
                            ? null
                            : () => _respondToJob(false),
                      ),
                    ] else if (assignment.status ==
                        AssignmentStatus.accepted) ...[
                      if (req.status == OrderStatus.accepted)
                        PrimaryButton(
                          label: 'I am Travelling / En Route',
                          icon: Icons.directions_bike,
                          isLoading: _isProcessing,
                          onPressed: _isProcessing
                              ? null
                              : () => _progressJob(req.id, 'travelling'),
                        ),
                      if (req.status == OrderStatus.travelling)
                        PrimaryButton(
                          label: 'Arrived at Location — Start Work',
                          icon: Icons.construction,
                          isLoading: _isProcessing,
                          onPressed: _isProcessing
                              ? null
                              : () => _progressJob(req.id, 'in_progress'),
                        ),
                      if (req.status == OrderStatus.inProgress)
                        PrimaryButton(
                          label: 'Service Completed',
                          icon: Icons.check_circle_outline,
                          isLoading: _isProcessing,
                          backgroundColor: AppColors.success,
                          onPressed: _isProcessing
                              ? null
                              : () => _completeJobWithPrice(
                                  req.id,
                                  req.quotedPriceMinor,
                                ),
                        ),
                    ] else if (assignment.status ==
                        AssignmentStatus.completed) ...[
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: AppColors.successBackground,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'This job has been completed successfully.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorStateView(message: e.toString()),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorStateView(message: e.toString()),
      ),
    );
  }
}
