import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../auth/auth_controller.dart';
import '../provider_controller.dart';

class ProviderPricingScreen extends ConsumerWidget {
  const ProviderPricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).providerProfile;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('Complete partner onboarding first.')),
      );
    }
    final services = ref.watch(providerServicesProvider(profile.id));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Services & pricing')),
      body: services.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: AppSpacing.paddingScreen,
            child: Text('Could not load your services: $error'),
          ),
        ),
        data: (items) => ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            Text(
              'You control your service prices',
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose a quote after inspecting the job, or propose a fixed price you have agreed with Kwick. Fixed prices stay pending until an operator approves them.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No services are linked to your partner profile yet.',
                  ),
                ),
              ),
            ...items.map(
              (item) => _ServicePricingCard(
                providerId: profile.id,
                service: item,
                onSaved: () =>
                    ref.invalidate(providerServicesProvider(profile.id)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Commission terms are negotiated separately with each provider. If no signed/agreed term exists, no commission percentage is configured. Kwick does not charge a monthly partner subscription during the pilot.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicePricingCard extends ConsumerWidget {
  const _ServicePricingCard({
    required this.providerId,
    required this.service,
    required this.onSaved,
  });
  final String providerId;
  final Map<String, dynamic> service;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = service['service_categories'];
    final categoryName = category is Map
        ? category['name']?.toString() ?? 'Service'
        : 'Service';
    final model = service['pricing_model']?.toString() ?? 'provider_quote';
    final approval =
        service['price_approval_status']?.toString() ?? 'not_required';
    final priceMinor = service['base_price_minor'] as num?;
    final categoryId = service['category_id'] as String;
    final commission = ref.watch(
      activeCommissionTermProvider((providerId, categoryId)),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(categoryName, style: AppTextStyles.headingSmall),
                ),
                _StatusChip(status: approval),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              model == 'agreed_fixed' && priceMinor != null
                  ? 'Fixed price: ₹${(priceMinor / 100).toStringAsFixed(2)}'
                  : 'Provider quote after job assessment',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            commission.when(
              data: (term) => Text(
                term == null
                    ? 'Platform commission: not agreed / not configured'
                    : 'Agreed platform commission: ${((term['commission_rate_bps'] as num).toInt() / 100).toStringAsFixed(2)}%',
                style: AppTextStyles.bodySmall,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text(
                'Commission terms unavailable',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _editPricing(context, ref, model, priceMinor?.toInt()),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Update price'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPricing(
    BuildContext context,
    WidgetRef ref,
    String currentModel,
    int? currentPrice,
  ) async {
    var selectedModel = currentModel;
    final priceController = TextEditingController(
      text: currentPrice == null ? '' : (currentPrice / 100).toStringAsFixed(2),
    );
    var saving = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set service pricing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedModel,
                decoration: const InputDecoration(labelText: 'Pricing model'),
                items: const [
                  DropdownMenuItem(
                    value: 'provider_quote',
                    child: Text('Quote after assessment'),
                  ),
                  DropdownMenuItem(
                    value: 'agreed_fixed',
                    child: Text('Agreed fixed price'),
                  ),
                ],
                onChanged: saving
                    ? null
                    : (value) => setDialogState(
                        () => selectedModel = value ?? 'provider_quote',
                      ),
              ),
              if (selectedModel == 'agreed_fixed') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Fixed price (₹)',
                    hintText: 'e.g. 450.00',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This proposal is not customer-visible until Kwick reviews and approves it.',
                  style: AppTextStyles.bodySmall,
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'You will provide a job-specific quote after understanding the work. Confirm the amount with the customer before starting.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorMessage!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      int? minor;
                      if (selectedModel == 'agreed_fixed') {
                        final raw = priceController.text.trim();
                        if (!RegExp(r'^\d{1,7}(?:\.\d{1,2})?$').hasMatch(raw)) {
                          setDialogState(
                            () => errorMessage =
                                'Enter a valid amount with up to two decimal places.',
                          );
                          return;
                        }
                        minor = (double.parse(raw) * 100).round();
                        if (minor <= 0) {
                          setDialogState(
                            () => errorMessage =
                                'The fixed price must be greater than zero.',
                          );
                          return;
                        }
                      }
                      setDialogState(() {
                        saving = true;
                        errorMessage = null;
                      });
                      try {
                        await ref
                            .read(supabaseServiceProvider)
                            .updateProviderServicePricing(
                              providerServiceId: service['id'] as String,
                              pricingModel: selectedModel,
                              basePriceMinor: minor,
                            );
                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        onSaved();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pricing updated. Fixed-price proposals require Kwick approval.',
                              ),
                            ),
                          );
                        }
                      } catch (error) {
                        setDialogState(() {
                          saving = false;
                          errorMessage = error.toString();
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save pricing'),
            ),
          ],
        ),
      ),
    );
    priceController.dispose();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending';
    final approved = status == 'approved';
    final color = approved
        ? AppColors.success
        : pending
        ? AppColors.warning
        : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

final activeCommissionTermProvider =
    FutureProvider.family<Map<String, dynamic>?, (String, String)>((
      ref,
      key,
    ) async {
      return ref
          .watch(supabaseServiceProvider)
          .getActiveCommissionTerm(providerId: key.$1, categoryId: key.$2);
    });
