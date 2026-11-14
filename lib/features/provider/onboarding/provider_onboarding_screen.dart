import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  PlatformFile? _identityFile;
  PlatformFile? _tradeFile;
  String? _errorMessage;

  @override
  void dispose() {
    _expController.dispose();
    super.dispose();
  }

  Future<PlatformFile?> _pickVerificationFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (file == null) return null;
    final fileLength = await file.length();
    if (fileLength == null || fileLength > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Choose a document smaller than 10 MB.'),
          ),
        );
      }
      return null;
    }
    final fileBytes = await file.readAsBytes();
    if (fileBytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The selected file could not be read. Try another file.',
            ),
          ),
        );
      }
      return null;
    }
    return file;
  }

  String _contentTypeFor(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _addDocument(String providerId, String documentType) async {
    final file = await _pickVerificationFile();
    if (file == null) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(supabaseServiceProvider)
          .uploadProviderDocument(
            providerId: providerId,
            documentType: documentType,
            fileName: file.name,
            bytes: await file.readAsBytes(),
            contentType: _contentTypeFor(file),
          );
      ref.invalidate(providerDocumentsProvider(providerId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Document uploaded securely. It is awaiting manual review.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
    if (_identityFile == null) {
      setState(
        () => _errorMessage =
            'Upload an accepted photo identity document to continue.',
      );
      return;
    }
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
      final providerId = await supabase.submitProviderOnboarding(
        userId: user.id,
        categoryId: _selectedCategory!,
        serviceAreaId: AppConfig.pilotAreaId,
        experienceYears: int.parse(_expController.text.trim()),
      );
      await supabase.uploadProviderDocument(
        providerId: providerId,
        documentType: 'id_proof',
        fileName: _identityFile!.name,
        bytes: await _identityFile!.readAsBytes(),
        contentType: _contentTypeFor(_identityFile!),
      );
      if (_tradeFile != null) {
        await supabase.uploadProviderDocument(
          providerId: providerId,
          documentType: 'trade_certification',
          fileName: _tradeFile!.name,
          bytes: await _tradeFile!.readAsBytes(),
          contentType: _contentTypeFor(_tradeFile!),
        );
      }

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
      ref.invalidate(providerProfileProvider);
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
                            const SizedBox(height: AppSpacing.md),
                            _ProviderDocumentsPanel(
                              providerId: prov.id,
                              isUploading: _isSubmitting,
                              onUploadIdentity: () =>
                                  _addDocument(prov.id, 'id_proof'),
                              onUploadTrade: () =>
                                  _addDocument(prov.id, 'trade_certification'),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _errorMessage!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
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
                      'Start Earning with Kwick',
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
                                      'HSR Layout, Bengaluru • 560102',
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
                                    'Kwick reviews identity, trade competence, local references and service-area fit before activating a partner. A field skills check may be required.',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _DocumentPickerTile(
                              title: 'Identity proof',
                              subtitle:
                                  _identityFile?.name ??
                                  'Required · JPG, PNG or PDF · max 10 MB',
                              isSelected: _identityFile != null,
                              onTap: () async {
                                final file = await _pickVerificationFile();
                                if (file != null) {
                                  setState(() => _identityFile = file);
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _DocumentPickerTile(
                              title: 'Trade certificate (optional)',
                              subtitle:
                                  _tradeFile?.name ??
                                  'Optional · practical skills check may be used instead',
                              isSelected: _tradeFile != null,
                              onTap: () async {
                                final file = await _pickVerificationFile();
                                if (file != null) {
                                  setState(() => _tradeFile = file);
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Do not upload Aadhaar cards, full Aadhaar numbers, biometric data or Aadhaar e-KYC files. Kwick will confirm accepted alternative identity documents during onboarding.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
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
                                'I agree to the Kwick Partner Terms of Service and consent to identity and trade-competency checks. Aadhaar numbers, biometrics and Aadhaar e-KYC data are not required.',
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

class _DocumentPickerTile extends StatelessWidget {
  const _DocumentPickerTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(
      isSelected ? Icons.check_circle : Icons.upload_file,
      color: isSelected ? AppColors.success : AppColors.primary,
    ),
    label: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall,
        ),
      ],
    ),
    style: OutlinedButton.styleFrom(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(14),
      foregroundColor: AppColors.textPrimary,
      side: BorderSide(
        color: isSelected ? AppColors.success : AppColors.border,
      ),
    ),
  );
}

class _ProviderDocumentsPanel extends ConsumerWidget {
  const _ProviderDocumentsPanel({
    required this.providerId,
    required this.isUploading,
    required this.onUploadIdentity,
    required this.onUploadTrade,
  });
  final String providerId;
  final bool isUploading;
  final VoidCallback onUploadIdentity;
  final VoidCallback onUploadTrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(providerDocumentsProvider(providerId));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verification documents', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          documents.when(
            data: (items) => items.isEmpty
                ? Text(
                    'No documents uploaded yet.',
                    style: AppTextStyles.bodySmall,
                  )
                : Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 17,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (item['document_type'] as String)
                                        .replaceAll('_', ' '),
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                                Text(
                                  (item['verification_status'] as String)
                                      .replaceAll('_', ' '),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color:
                                        item['verification_status'] ==
                                            'approved'
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => Text(
              'Could not load document status: $error',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: isUploading ? null : onUploadIdentity,
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Add identity proof'),
              ),
              OutlinedButton.icon(
                onPressed: isUploading ? null : onUploadTrade,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Add trade proof'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Files are private. Uploading does not mean you are verified; an operator must review them.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
