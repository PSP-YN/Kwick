import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/service_area.dart';
import '../../shared/models/service_category.dart';
import '../../shared/models/service_request.dart';
import '../../shared/services/supabase_service.dart';
import '../auth/auth_controller.dart';

final activeCategoriesProvider = FutureProvider<List<ServiceCategory>>((
  ref,
) async {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getActiveCategories();
});

final activeServiceAreasProvider = FutureProvider<List<ServiceArea>>((
  ref,
) async {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getActiveServiceAreas();
});

final customerRequestsProvider = FutureProvider<List<ServiceRequest>>((
  ref,
) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.userProfile;
  if (user == null) return [];

  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getCustomerRequests(user.id);
});

final requestDetailsProvider = FutureProvider.family<ServiceRequest?, String>((
  ref,
  requestId,
) async {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getRequestById(requestId);
});

final requestAssignmentProvider = FutureProvider.family<dynamic, String>((
  ref,
  requestId,
) async {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getActiveAssignmentForRequest(requestId);
});
