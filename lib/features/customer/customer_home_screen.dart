import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utilities/date_formatter.dart';
import '../../shared/models/service_category.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/error_state_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/status_badge.dart';
import '../auth/auth_controller.dart';
import 'customer_controller.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.userProfile;
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final requestsAsync = ref.watch(customerRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: const Icon(
                Icons.handyman,
                size: 20.0,
                color: AppColors.textInverse,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppConfig.appName,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          // If user has provider role, show pro switch shortcut
          if (profile?.roles.contains(UserRole.provider) ?? false)
            TextButton.icon(
              onPressed: () {
                ref
                    .read(authControllerProvider.notifier)
                    .switchActiveRole(UserRole.provider);
                context.go('/provider/home');
              },
              icon: const Icon(Icons.swap_horiz, size: 18.0),
              label: const Text('Pro Mode'),
            ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign Out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeCategoriesProvider);
          ref.invalidate(customerRequestsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting & Pilot Region Indicator
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${profile?.fullName.split(' ').first ?? 'there'} 👋',
                          style: AppTextStyles.headingLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'What service do you need today?',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.infoBackground,
                      borderRadius: AppSpacing.roundedFull,
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14.0,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'HSR Layout • 560102',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Active Request Alert Card (if any active request exists)
              requestsAsync.when(
                data: (requests) {
                  final activeRequests = requests
                      .where((r) => r.status.isActive)
                      .toList();
                  if (activeRequests.isEmpty) return const SizedBox.shrink();

                  final latest = activeRequests.first;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: InkWell(
                      onTap: () =>
                          context.push('/customer/orders/${latest.id}'),
                      borderRadius: AppSpacing.roundedMd,
                      child: Container(
                        padding: AppSpacing.paddingCard,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(
                            color: AppColors.primaryLight,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              blurRadius: 10.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StatusBadge.fromOrderStatus(latest.status),
                                const Spacer(),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              latest.categoryName ?? 'Service Request',
                              style: AppTextStyles.headingSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              latest.description,
                              style: AppTextStyles.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14.0,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  DateFormatter.formatDateTime(
                                    latest.createdAt,
                                  ),
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),

              // Service Categories Section
              Text(
                'Available Pilot Services',
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Book trusted, background-checked professionals in Bengaluru South',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),

              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No active service categories available.',
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: categories
                        .map((cat) => _CategoryCard(category: cat))
                        .toList(),
                  );
                },
                loading: () => const Center(child: LoadingIndicator()),
                error: (err, _) => ErrorStateView(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(activeCategoriesProvider),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Trust & Quality Banner
              Container(
                padding: AppSpacing.paddingCard,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why Choose NexHelp?',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _TrustItem(
                      icon: Icons.verified_user_outlined,
                      title: 'Verified Professionals',
                      description:
                          'Plumbers and electricians are personally verified with trade checks.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _TrustItem(
                      icon: Icons.currency_rupee,
                      title: 'Transparent Pricing',
                      description:
                          'Fair pricing guidance with no hidden platform charges.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _TrustItem(
                      icon: Icons.support_agent_outlined,
                      title: 'Operational Support',
                      description:
                          'Dedicated operator dispatch and dispute resolution for every job.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 1) {
            context.push('/customer/orders');
          } else if (index == 2) {
            context.push('/customer/support');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'My Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: 'Support',
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;

  const _CategoryCard({required this.category});

  IconData _resolveIcon(String key) {
    switch (key) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical_services':
      case 'electrical':
        return Icons.electrical_services;
      default:
        return Icons.home_repair_service;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: AppSpacing.roundedMd,
        onTap: () => context.push('/customer/book?categoryId=${category.id}'),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Icon(
                  _resolveIcon(category.iconKey),
                  size: 32.0,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      category.description,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text(
                          'Book Service',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.primary,
                            fontSize: 13.0,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        const Icon(
                          Icons.arrow_forward,
                          size: 14.0,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TrustItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.0, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(description, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
