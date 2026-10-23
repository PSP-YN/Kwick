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
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../customer_controller.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _isCancelling = false;

  Future<void> _cancelBooking() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Cancel Booking',
      message:
          'Are you sure you want to cancel this service request? This action cannot be undone.',
      confirmLabel: 'Cancel Request',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.cancelServiceRequest(
        widget.orderId,
        'Cancelled by customer',
      );
      ref.invalidate(requestDetailsProvider(widget.orderId));
      ref.invalidate(customerRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service request cancelled.'),
            backgroundColor: AppColors.textPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(requestDetailsProvider(widget.orderId));
    final assignmentAsync = ref.watch(
      requestAssignmentProvider(widget.orderId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(requestDetailsProvider(widget.orderId));
              ref.invalidate(requestAssignmentProvider(widget.orderId));
            },
          ),
        ],
      ),
      body: requestAsync.when(
        data: (req) {
          if (req == null) {
            return const Center(child: Text('Service request not found.'));
          }

          return SingleChildScrollView(
            padding: AppSpacing.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card with Status
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
                              'ID: ${req.id.substring(0, 8)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          req.categoryName ?? 'Service Request',
                          style: AppTextStyles.headingLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Created on ${DateFormatter.formatDateTime(req.createdAt)}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Order Progress Stepper Tracker
                _OrderProgressTracker(status: req.status),
                const SizedBox(height: AppSpacing.md),

                // Assigned Provider Card (if assigned)
                assignmentAsync.when(
                  data: (assignment) {
                    if (assignment is! Assignment) {
                      return const SizedBox.shrink();
                    }
                    return Card(
                      child: Padding(
                        padding: AppSpacing.paddingCard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned Professional',
                              style: AppTextStyles.headingSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        assignment.providerName ??
                                            'Assigned Pro',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (assignment.providerPhone != null)
                                        Text(
                                          'Phone: ${assignment.providerPhone}',
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                    ],
                                  ),
                                ),
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
                                    'Verified',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Service Address & Details Card
                Card(
                  child: Padding(
                    padding: AppSpacing.paddingCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Details',
                          style: AppTextStyles.headingSmall,
                        ),
                        const Divider(height: 24.0),
                        _DetailRow(
                          icon: Icons.description_outlined,
                          label: 'Problem Description',
                          value: req.description,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailRow(
                          icon: Icons.location_on_outlined,
                          label: 'Service Address',
                          value: '${req.addressLine}\nPincode: ${req.pincode}',
                        ),
                        if (req.scheduledAt != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _DetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Preferred Appointment',
                            value: DateFormatter.formatDateTime(
                              req.scheduledAt,
                            ),
                          ),
                        ],
                        if (req.customerNotes != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _DetailRow(
                            icon: Icons.notes_outlined,
                            label: 'Customer Notes',
                            value: req.customerNotes!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Price Summary Card
                Card(
                  child: Padding(
                    padding: AppSpacing.paddingCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pricing', style: AppTextStyles.headingSmall),
                        const Divider(height: 24.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              req.finalPriceMinor != null
                                  ? 'Final Total'
                                  : 'Quoted Estimate',
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Action Buttons based on status
                if (req.status == OrderStatus.completed) ...[
                  PrimaryButton(
                    label: 'Leave a Review & Rating',
                    icon: Icons.star_rate_outlined,
                    onPressed: () => context.push('/customer/review/${req.id}'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (req.status.isCancellable) ...[
                  SecondaryButton(
                    label: 'Cancel Request',
                    icon: Icons.cancel_outlined,
                    onPressed: _isCancelling ? null : _cancelBooking,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/customer/support?orderId=${req.id}'),
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Need Help / Raise Dispute'),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (err, _) => ErrorStateView(
          message: err.toString(),
          onRetry: () => ref.invalidate(requestDetailsProvider(widget.orderId)),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.0, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.label),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderProgressTracker extends StatelessWidget {
  final OrderStatus status;

  const _OrderProgressTracker({required this.status});

  int get _stepIndex {
    switch (status) {
      case OrderStatus.requested:
        return 0;
      case OrderStatus.reviewing:
        return 1;
      case OrderStatus.assigned:
        return 2;
      case OrderStatus.accepted:
        return 3;
      case OrderStatus.travelling:
        return 4;
      case OrderStatus.inProgress:
        return 5;
      case OrderStatus.completed:
        return 6;
      case OrderStatus.cancelled:
      case OrderStatus.disputed:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppColors.errorBackground,
          borderRadius: AppSpacing.roundedMd,
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'This request was cancelled.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ],
        ),
      );
    }

    final steps = [
      'Requested',
      'Assigned',
      'Accepted',
      'En Route',
      'In Progress',
      'Completed',
    ];
    final currentIndex = _stepIndex;

    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Progress', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: List.generate(steps.length, (index) {
                final isDone = currentIndex >= index;
                final isCurrent = currentIndex == index;

                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                          color: isDone ? AppColors.primary : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check,
                                  size: 16.0,
                                  color: AppColors.textInverse,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: AppTextStyles.bodySmall,
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        steps[index],
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10.0,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isDone
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
