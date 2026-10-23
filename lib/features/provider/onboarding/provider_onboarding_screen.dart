import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/validation/validators.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/auth_controller.dart';
import '../../customer/customer_controller.dart';
import '../provider_controller.dart';

class ProviderOnboardingScreen extends ConsumerStatefulWidget {
  const ProviderOnboardingScreen({super.key});

  @override
  ConsumerState<ProviderOnboardingScreen> createState() =>
      _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState
    extends ConsumerState<ProviderOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _expController = TextEditingController(text: '3');
  String? _selectedCategory;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _expController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    if (!_agreedToTerms) {
      setState(
        () => _errorMessage =
            'Please accept the service partner terms to proceed.',
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      setState(
        () => _errorMessage = 'Please select your primary trade category.',
      );
      return;
    }

    final user = ref.read(authControllerProvider).userProfile;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.submitProviderOnboarding(
        userId: user.id,
        categoryId: _selectedCategory!,
        serviceAreaId: AppConfig.pilotAreaId,
        experienceYears: int.parse(_expController.text.trim()),
      );

      ref.invalidate(providerProfileProvider);
      await ref.read(authControllerProvider.notifier).refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Onboarding details submitted! Our operations team is reviewing your profile.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerAsync = ref.watch(providerProfileProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service Professional Onboarding'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: providerAsync.when(
          data: (prov) {
            // If already submitted and pending or rejected
            if (prov != null) {
              return SingleChildScrollView(
                padding: AppSpacing.paddingScreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            StatusBadge.fromVerificationStatus(
                              prov.verificationStatus,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              prov.isApproved
                                  ? 'You are Verified & Approved!'
                                  : 'Application Under Review',
                              style: AppTextStyles.headingMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              prov.isApproved
                                  ? 'You can now go online to accept incoming job requests in Bengaluru South.'
                                  : 'Thank you for submitting your trade profile. Our operations team is reviewing your background and contact info.',
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            if (prov.verificationNotes != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: AppColors.infoBackground,
                                  borderRadius: AppSpacing.roundedSm,
                                ),
                                child: Text(
                                  'Operator Note: ${prov.verificationNotes}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            if (prov.isApproved)
                              PrimaryButton(
                                label: 'Go to Provider Dashboard',
                                icon: Icons.dashboard_outlined,
                                onPressed: () => context.go('/provider/home'),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: () =>
                                    ref.invalidate(providerProfileProvider),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Check Approval Status'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Fresh onboarding form
            return SingleChildScrollView(
              padding: AppSpacing.paddingScreen,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Start Earning with NexHelp',
                      style: AppTextStyles.headingLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Complete your trade profile for background verification and job dispatch.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppColors.errorBackground,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    Card(
                      child: Padding(
                        padding: AppSpacing.paddingCard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Primary Trade Category',
                              style: AppTextStyles.label,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            categoriesAsync.when(
                              data: (categories) {
                                if (_selectedCategory == null &&
                                    categories.isNotEmpty) {
                                  _selectedCategory = categories.first.id;
                                }
                                return DropdownButtonFormField<String>(
                                  initialValue: _selectedCategory,
                                  items: categories.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat.id,
                                      child: Text(cat.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedCategory = val);
                                    }
                                  },
                                );
                              },
                              loading: () => const LoadingIndicator(),
                              error: (e, _) => Text('Error: $e'),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            AppTextField(
                              label: 'Years of Experience',
                              hint: 'E.g., 5',
                              controller: _expController,
                              keyboardType: TextInputType.number,
                              validator: Validators.validateExperienceYears,
                              prefixIcon: const Icon(
                                Icons.work_history_outlined,
                                size: 20.0,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            Text(
                              'Operating Service Area',
                              style: AppTextStyles.label,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: AppSpacing.roundedSm,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 18.0,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Bengaluru South (HSR & Koramangala • 560102)',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Document checklist notice
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: AppColors.warningBackground,
                                borderRadius: AppSpacing.roundedSm,
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.security,
                                        size: 18.0,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        'Verification Requirement',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.warning,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Our field supervisor will verify your Govt ID proof and trade experience before assigning real customer jobs.',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Terms Checkbox
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _agreedToTerms,
                              onChanged: (val) =>
                                  setState(() => _agreedToTerms = val ?? false),
                              title: Text(
                                'I agree to the NexHelp Partner Terms of Service and consent to background checks.',
                                style: AppTextStyles.bodySmall,
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            PrimaryButton(
                              label: 'Submit Application for Review',
                              onPressed: _isSubmitting
                                  ? null
                                  : _submitOnboarding,
                              isLoading: _isSubmitting,
                              icon: Icons.check_circle_outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const LoadingIndicator(),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
