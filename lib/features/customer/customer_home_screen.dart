import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utilities/date_formatter.dart';
import '../../shared/models/service_category.dart';
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
  String _searchQuery = '';

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
            Image.asset(
              'assets/branding/kwick_mark.png',
              width: 34,
              height: 34,
              fit: BoxFit.contain,
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
                          'Hello, ${profile?.fullName.split(' ').first ?? 'there'}',
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
                          'HSR Layout · 560102',
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
              TextField(
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search plumbing, electrical…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(() => _searchQuery = ''),
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.roundedMd,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.roundedMd,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.roundedMd,
                    borderSide: const BorderSide(
                      color: AppColors.secondaryDark,
                      width: 1.5,
                    ),
                  ),
                ),
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
              Text('Services in your area', style: AppTextStyles.headingMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choose a service currently available in HSR Layout. More categories will open as local partners are verified.',
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

                  final visibleCategories = categories.where((category) {
                    final query = _searchQuery;
                    return query.isEmpty ||
                        category.name.toLowerCase().contains(query) ||
                        category.description.toLowerCase().contains(query);
                  }).toList();
                  if (visibleCategories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text('No active service matches that search.'),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleCategories.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.03,
                        ),
                    itemBuilder: (context, index) =>
                        _CategoryCard(category: visibleCategories[index]),
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
                    Text('Why Kwick?', style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.md),
                    _TrustItem(
                      icon: Icons.verified_user_outlined,
                      title: 'Verified Professionals',
                      description:
                          'Providers are reviewed before activation. Verification status is visible before dispatch.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _TrustItem(
                      icon: Icons.currency_rupee,
                      title: 'Transparent Pricing',
                      description:
                          'Confirm the service scope and provider quote before work begins.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _TrustItem(
                      icon: Icons.support_agent_outlined,
                      title: 'Operational Support',
                      description:
                          'A Kwick operations team reviews requests and handles support during the pilot.',
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: AppSpacing.roundedMd,
        onTap: () => context.push('/customer/book?categoryId=${category.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _resolveIcon(category.iconKey),
                  size: 25,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                category.name,
                style: AppTextStyles.headingSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                category.description,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Text(
                    'Explore',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: AppColors.secondaryDark,
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
