import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utilities/date_formatter.dart';
import '../../../core/validation/validators.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../customer_controller.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String? preselectedCategoryId;

  const BookingScreen({super.key, this.preselectedCategoryId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController(
    text: AppConfig.pilotPincode,
  );
  final _notesController = TextEditingController();

  String? _selectedCategoryId;
  DateTime? _scheduledDateTime;
  bool _isSubmitting = false;
  bool _isDiagnosing = false;
  Map<String, dynamic>? _diagnosis;
  String? _diagnosisError;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.preselectedCategoryId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _analyzeIssue() async {
    final description = _descriptionController.text.trim();
    final validationError = Validators.validateDescription(description);
    if (validationError != null) {
      setState(() => _diagnosisError = validationError);
      return;
    }

    setState(() {
      _isDiagnosing = true;
      _diagnosisError = null;
      _diagnosis = null;
    });

    try {
      final categoryHint = _selectedCategoryId == AppConfig.plumbingCategoryId
          ? 'plumbing'
          : _selectedCategoryId == AppConfig.electricalCategoryId
              ? 'electrical'
              : null;
      final result = await ref
          .read(supabaseServiceProvider)
          .diagnoseServiceIssue(
            description: description,
            categoryHint: categoryHint,
          );
      if (mounted) setState(() => _diagnosis = result);
    } catch (e) {
      if (mounted) setState(() => _diagnosisError = e.toString());
    } finally {
      if (mounted) setState(() => _isDiagnosing = false);
    }
  }

  Widget _buildDiagnosisCard() {
    final diagnosis = _diagnosis;
    if (diagnosis == null) return const SizedBox.shrink();

    final safetyAlerts = (diagnosis['safety_alerts'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    final questions = (diagnosis['follow_up_questions'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    final urgency = diagnosis['urgency']?.toString() ?? 'routine';

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'NexHelp Intelligence',
                  style: AppTextStyles.headingSmall,
                ),
              ),
              Text(
                urgency.toUpperCase(),
                style: AppTextStyles.label.copyWith(
                  color: urgency == 'emergency'
                      ? AppColors.error
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            diagnosis['summary']?.toString() ?? '',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Suggested category: ${diagnosis['category'] ?? 'other'} · Confidence: ${diagnosis['confidence'] ?? 'low'}',
            style: AppTextStyles.bodySmall,
          ),
          if (safetyAlerts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Safety guidance', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            for (final alert in safetyAlerts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: Text(alert, style: AppTextStyles.bodySmall)),
                  ],
                ),
              ),
          ],
          if (questions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Questions to clarify', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            for (final question in questions)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text('• $question', style: AppTextStyles.bodySmall),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'AI-generated triage is advisory only. A service professional must verify the issue. Do not approach electrical, fire, gas or flooding hazards.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitBooking() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategoryId == null) {
      setState(() => _errorMessage = 'Please select a service category.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final requestId = await supabase.createServiceRequest(
        categoryId: _selectedCategoryId!,
        serviceAreaId: AppConfig.pilotAreaId,
        description: _descriptionController.text.trim(),
        addressLine: _addressController.text.trim(),
        pincode: _pincodeController.text.trim(),
        scheduledAt: _scheduledDateTime,
        customerNotes: [
          _notesController.text.trim(),
          if (_diagnosis != null)
            'NexHelp AI triage (advisory): ${_diagnosis!['summary']} '
                'Urgency: ${_diagnosis!['urgency']}. '
                'Dispatcher note: ${_diagnosis!['dispatcher_note']}.',
        ].where((note) => note.trim().isNotEmpty).join('\n\n').isNotEmpty
            ? [
                _notesController.text.trim(),
                if (_diagnosis != null)
                  'NexHelp AI triage (advisory): ${_diagnosis!['summary']} '
                      'Urgency: ${_diagnosis!['urgency']}. '
                      'Dispatcher note: ${_diagnosis!['dispatcher_note']}.',
              ].where((note) => note.trim().isNotEmpty).join('\n\n')
            : null,
      );

      ref.invalidate(customerRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Service request submitted successfully! An operator will assign a pro shortly.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/customer/orders/$requestId');
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
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Book a Service Pro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pilot location reminder banner
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.infoBackground,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20.0,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'NexHelp pilot is operating in Bengaluru South (${AppConfig.pilotPincode} HSR/Koramangala).',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.errorBackground,
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
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

                // Category Selection
                Text('Select Service Category', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.xs),
                categoriesAsync.when(
                  data: (categories) {
                    if (_selectedCategoryId == null && categories.isNotEmpty) {
                      _selectedCategoryId = categories.first.id;
                    }
                    return Column(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategoryId == cat.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InkWell(
                            onTap: () =>
                                setState(() => _selectedCategoryId = cat.id),
                            borderRadius: AppSpacing.roundedMd,
                            child: Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.05)
                                    : AppColors.surface,
                                borderRadius: AppSpacing.roundedMd,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    cat.slug == 'plumbing'
                                        ? Icons.plumbing
                                        : Icons.electrical_services,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat.name,
                                          style: AppTextStyles.headingSmall,
                                        ),
                                        Text(
                                          cat.description,
                                          style: AppTextStyles.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => Text('Failed to load categories: $e'),
                ),
                const SizedBox(height: AppSpacing.md),

                // Problem Description
                AppTextField(
                  label: 'Describe the Problem',
                  hint:
                      'E.g., Kitchen sink pipe is leaking water, tap valve loose (minimum 10 characters)',
                  controller: _descriptionController,
                  maxLines: 3,
                  validator: Validators.validateDescription,
                  onChanged: (_) {
                    if (_diagnosis != null || _diagnosisError != null) {
                      setState(() {
                        _diagnosis = null;
                        _diagnosisError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _isDiagnosing || _isSubmitting
                      ? null
                      : _analyzeIssue,
                  icon: _isDiagnosing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isDiagnosing
                        ? 'Assessing issue…'
                        : 'Analyze issue with NexHelp AI',
                  ),
                ),
                if (_diagnosisError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _diagnosisError!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                _buildDiagnosisCard(),
                const SizedBox(height: AppSpacing.md),

                // Service Address
                AppTextField(
                  label: 'Service Address (Flat, House/Street)',
                  hint: 'E.g., Flat 302, Green Glen Apartments, 14th Main Rd',
                  controller: _addressController,
                  maxLines: 2,
                  validator: Validators.validateAddress,
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    size: 20.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Pincode
                AppTextField(
                  label: 'Pincode',
                  hint: '560102',
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  validator: Validators.validatePincode,
                  prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20.0),
                ),
                const SizedBox(height: AppSpacing.md),

                // Preferred Appointment Time
                Text('Appointment Preference', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: AppSpacing.roundedMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 20.0,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _scheduledDateTime != null
                                ? DateFormatter.formatDateTime(
                                    _scheduledDateTime,
                                  )
                                : 'Select date & time (or leave for earliest available)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _scheduledDateTime != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        if (_scheduledDateTime != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18.0),
                            onPressed: () =>
                                setState(() => _scheduledDateTime = null),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Optional Customer Notes
                AppTextField(
                  label: 'Optional Notes for Pro / Dispatcher',
                  hint:
                      'E.g., Call before arrival, ask for security gate pass code',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                PrimaryButton(
                  label: 'Confirm and Submit Request',
                  onPressed: _isSubmitting ? null : _submitBooking,
                  isLoading: _isSubmitting,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
