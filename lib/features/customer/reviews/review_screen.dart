import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/assignment.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/auth_controller.dart';
import '../customer_controller.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ReviewScreen({super.key, required this.orderId});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(String customerId, String providerId) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.submitReview(
        customerId: customerId,
        requestId: widget.orderId,
        providerId: providerId,
        rating: _rating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your review has been submitted.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
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
    final authState = ref.watch(authControllerProvider);
    final user = authState.userProfile;
    final assignmentAsync = ref.watch(
      requestAssignmentProvider(widget.orderId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rate & Review Service')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: assignmentAsync.when(
            data: (assignment) {
              if (assignment is! Assignment) {
                return const Center(
                  child: Text(
                    'Unable to identify assigned provider for this request.',
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: AppSpacing.paddingCard,
                      child: Column(
                        children: [
                          Text(
                            'How was the service?',
                            style: AppTextStyles.headingMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Provided by ${assignment.providerName ?? 'Service Pro'}',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Interactive Star Rating Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starIndex = index + 1;
                              return IconButton(
                                iconSize: 40.0,
                                icon: Icon(
                                  starIndex <= _rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                ),
                                onPressed: () =>
                                    setState(() => _rating = starIndex),
                              );
                            }),
                          ),
                          Text(
                            _getRatingLabel(_rating),
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
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

                  AppTextField(
                    label: 'Feedback & Comments (Optional)',
                    hint:
                        'Was the pro punctual? Did they solve the issue cleanly?',
                    controller: _commentController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  PrimaryButton(
                    label: 'Submit Review',
                    onPressed: _isSubmitting || user == null
                        ? null
                        : () => _submitReview(user.id, assignment.providerId),
                    isLoading: _isSubmitting,
                    icon: Icons.send_outlined,
                  ),
                ],
              );
            },
            loading: () => const LoadingIndicator(),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent ★★★★★';
      case 4:
        return 'Good ★★★★☆';
      case 3:
        return 'Average ★★★☆☆';
      case 2:
        return 'Poor ★★☆☆☆';
      case 1:
        return 'Very Poor ★☆☆☆☆';
      default:
        return '';
    }
  }
}
