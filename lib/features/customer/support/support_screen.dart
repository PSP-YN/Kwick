import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/auth_controller.dart';

class SupportScreen extends ConsumerStatefulWidget {
  final String? orderId;

  const SupportScreen({super.key, this.orderId});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  String _selectedCategory = 'service_quality';
  bool _isSubmitting = false;

  final Map<String, String> _categories = {
    'service_quality': 'Service Quality / Incomplete Work',
    'pricing': 'Pricing Dispute / Overcharging',
    'delay': 'Provider Late / No-Show',
    'behavior': 'Professional Conduct / Behavior',
    'safety': 'Safety Incident / Immediate Escalation',
    'other': 'General Inquiry or Question',
  };

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authControllerProvider).userProfile;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.submitSupportTicket(
        userId: user.id,
        requestId: widget.orderId,
        issueCategory: _selectedCategory,
        description: _descController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Support ticket created. Our Bangalore operations team will contact you shortly.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting ticket: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Customer Support & Disputes')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.orderId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.infoBackground,
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt,
                          size: 20.0,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Regarding Booking ID: ${widget.orderId!.substring(0, 8)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                          'Raise an Issue',
                          style: AppTextStyles.headingSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Every complaint is logged with our dispatch operators for timely resolution.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        Text('Issue Category', style: AppTextStyles.label),
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          items: _categories.entries.map((e) {
                            return DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          label: 'Detailed Description',
                          hint:
                              'Explain what happened so our team can investigate (at least 10 characters)...',
                          controller: _descController,
                          maxLines: 4,
                          validator: (val) {
                            if (val == null || val.trim().length < 10) {
                              return 'Please provide at least 10 characters of detail.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        PrimaryButton(
                          label: 'Submit Support Ticket',
                          onPressed: _submitTicket,
                          isLoading: _isSubmitting,
                          icon: Icons.send_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
