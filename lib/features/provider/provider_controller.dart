import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/assignment.dart';
import '../../shared/models/provider_profile.dart';
import '../../shared/services/supabase_service.dart';
import '../auth/auth_controller.dart';

final providerProfileProvider = FutureProvider<ProviderProfile?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.userProfile;
  if (user == null) return null;

  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getProviderProfile(user.id);
});

final providerAssignmentsProvider = FutureProvider<List<Assignment>>((
  ref,
) async {
  final providerAsync = ref.watch(providerProfileProvider);
  final provider = providerAsync.value;
  if (provider == null) return [];

  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getProviderAssignments(provider.id);
});

final providerDocumentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      providerId,
    ) async {
      final supabase = ref.watch(supabaseServiceProvider);
      return supabase.getProviderDocuments(providerId);
    });

final providerServicesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      providerId,
    ) async {
      final supabase = ref.watch(supabaseServiceProvider);
      return supabase.getProviderServices(providerId);
    });
