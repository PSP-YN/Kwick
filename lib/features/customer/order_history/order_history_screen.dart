import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../core/utilities/date_formatter.dart';
import '../../../shared/models/service_request.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../customer_controller.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(customerRequestsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Requests'),
              Tab(text: 'Past / Completed'),
            ],
          ),
        ),
        body: requestsAsync.when(
          data: (requests) {
            final activeRequests = requests
                .where((r) => r.status.isActive)
                .toList();
            final pastRequests = requests
                .where((r) => !r.status.isActive)
                .toList();

            return TabBarView(
              children: [
                _RequestsList(
                  requests: activeRequests,
                  emptyTitle: 'No Active Bookings',
                  emptyMessage:
                      'You do not have any ongoing service requests right now.',
                  actionLabel: 'Book a Service Pro',
                  onAction: () => context.push('/customer/book'),
                ),
                _RequestsList(
                  requests: pastRequests,
                  emptyTitle: 'No Completed Bookings',
                  emptyMessage:
                      'Your completed or cancelled requests will appear here.',
                ),
              ],
            );
          },
          loading: () => const LoadingIndicator(),
          error: (err, _) => ErrorStateView(
            message: err.toString(),
            onRetry: () => ref.invalidate(customerRequestsProvider),
          ),
        ),
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  final List<ServiceRequest> requests;
  final String emptyTitle;
  final String emptyMessage;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _RequestsList({
    required this.requests,
    required this.emptyTitle,
    required this.emptyMessage,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: emptyTitle,
        message: emptyMessage,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingScreen,
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: InkWell(
            onTap: () => context.push('/customer/orders/${req.id}'),
            borderRadius: AppSpacing.roundedMd,
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
                        DateFormatter.formatRelative(req.createdAt),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    req.categoryName ?? 'Service Request',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    req.description,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16.0,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          req.addressLine,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (req.finalPriceMinor != null)
                        Text(
                          CurrencyFormatter.formatPaise(req.finalPriceMinor),
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else if (req.quotedPriceMinor != null)
                        Text(
                          CurrencyFormatter.formatPaise(req.quotedPriceMinor),
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
