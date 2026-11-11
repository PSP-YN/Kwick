import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/failures.dart';
import '../models/assignment.dart';
import '../models/provider_profile.dart';
import '../models/review.dart';
import '../models/service_area.dart';
import '../models/service_category.dart';
import '../models/service_request.dart';
import '../models/support_ticket.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

/// Riverpod provider for SupabaseService instance
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(Supabase.instance.client);
});

/// Central client wrapper executing all Supabase queries, RPC transactions, and RLS operations
class SupabaseService {
  final SupabaseClient client;

  SupabaseService(this.client);

  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // ---------------------------------------------------------------------------
  // Authentication & Session
  // ---------------------------------------------------------------------------
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    UserRole initialRole = UserRole.customer,
  }) async {
    try {
      // The trusted auth.users trigger provisions profiles and the allowlisted
      // customer/provider role. The client must never write to user_roles.
      return await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'initial_role': initialRole == UserRole.provider
              ? 'provider'
              : 'customer',
        },
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerFailure('Sign up failed: $e');
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerFailure('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw ServerFailure('Sign out failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Profile & Roles
  // ---------------------------------------------------------------------------
  Future<UserProfile?> fetchUserProfile(String userId) async {
    try {
      final profileData = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profileData == null) return null;

      final rolesData = await client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId);

      final roles = (rolesData as List)
          .map((r) => UserRole.fromString(r['role'] as String))
          .toList();

      return UserProfile.fromJson(profileData, roles);
    } catch (e) {
      throw ServerFailure('Failed to load user profile: $e');
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;

      await client.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw ServerFailure('Failed to update profile: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Service Catalogue & Areas
  // ---------------------------------------------------------------------------
  Future<List<ServiceCategory>> getActiveCategories() async {
    try {
      final data = await client
          .from('service_categories')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (data as List).map((c) => ServiceCategory.fromJson(c)).toList();
    } catch (e) {
      throw ServerFailure('Failed to load categories: $e');
    }
  }

  Future<List<ServiceArea>> getActiveServiceAreas() async {
    try {
      final data = await client
          .from('service_areas')
          .select()
          .eq('is_active', true);

      return (data as List).map((a) => ServiceArea.fromJson(a)).toList();
    } catch (e) {
      throw ServerFailure('Failed to load service areas: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Customer Booking & Requests
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> diagnoseServiceIssue({
    required String description,
    String? categoryHint,
    required bool aiConsent,
    required String consentVersion,
  }) async {
    try {
      final response = await client.functions.invoke(
        'diagnose-service',
        body: {
          'description': description,
          'categoryHint': categoryHint,
          'aiConsent': aiConsent,
          'aiConsentVersion': consentVersion,
        },
      );
      if (response.status < 200 || response.status >= 300) {
        final data = response.data;
        final message = data is Map ? data['error']?.toString() : null;
        throw ServerFailure(
          message ?? 'AI assessment failed with status ${response.status}.',
        );
      }
      if (response.data is! Map) {
        throw ServerFailure('AI assessment returned an invalid response.');
      }
      return Map<String, dynamic>.from(response.data as Map);
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure('AI issue analysis unavailable: $e');
    }
  }

  Future<String> createServiceRequest({
    required String categoryId,
    required String serviceAreaId,
    required String description,
    required String addressLine,
    required String pincode,
    DateTime? scheduledAt,
    String? customerNotes,
  }) async {
    try {
      final response = await client.rpc(
        'create_service_request',
        params: {
          'p_category_id': categoryId,
          'p_service_area_id': serviceAreaId,
          'p_description': description,
          'p_address_line': addressLine,
          'p_pincode': pincode,
          'p_scheduled_at': scheduledAt?.toIso8601String(),
          'p_customer_notes': customerNotes,
        },
      );

      return response as String;
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure('Failed to submit booking: $e');
    }
  }

  Future<List<ServiceRequest>> getCustomerRequests(String customerId) async {
    try {
      final data = await client
          .from('service_requests')
          .select('*, service_categories(name)')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (data as List).map((r) => ServiceRequest.fromJson(r)).toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch request history: $e');
    }
  }

  Future<ServiceRequest?> getRequestById(String requestId) async {
    try {
      final data = await client
          .from('service_requests')
          .select('*, service_categories(name)')
          .eq('id', requestId)
          .maybeSingle();

      if (data == null) return null;
      return ServiceRequest.fromJson(data);
    } catch (e) {
      throw ServerFailure('Failed to load request: $e');
    }
  }

  Future<Assignment?> getActiveAssignmentForRequest(String requestId) async {
    try {
      final data = await client
          .from('assignments')
          .select('*, providers(profiles(full_name, phone))')
          .eq('request_id', requestId)
          .inFilter('status', ['offered', 'accepted', 'completed'])
          .maybeSingle();

      if (data == null) return null;
      return Assignment.fromJson(data);
    } catch (e) {
      throw ServerFailure('Failed to load assignment: $e');
    }
  }

  Future<void> cancelServiceRequest(String requestId, String reason) async {
    try {
      await client.rpc(
        'cancel_service_request',
        params: {'p_request_id': requestId, 'p_reason': reason},
      );
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure('Failed to cancel request: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Provider Workflows
  // ---------------------------------------------------------------------------
  Future<ProviderProfile?> getProviderProfile(String userId) async {
    try {
      final data = await client
          .from('providers')
          .select('*, profiles(full_name, phone, email)')
          .eq('profile_id', userId)
          .maybeSingle();

      if (data == null) return null;
      return ProviderProfile.fromJson(data);
    } catch (e) {
      throw ServerFailure('Failed to load provider profile: $e');
    }
  }

  Future<void> submitProviderOnboarding({
    required String userId,
    required String categoryId,
    required String serviceAreaId,
    required int experienceYears,
  }) async {
    try {
      final provData = await client
          .from('providers')
          .upsert({
            'profile_id': userId,
            'service_area_id': serviceAreaId,
            'experience_years': experienceYears,
            'verification_status': 'pending',
            'availability_status': 'unavailable',
          })
          .select()
          .single();

      final providerId = provData['id'] as String;

      // Link category
      await client.from('provider_services').upsert({
        'provider_id': providerId,
        'category_id': categoryId,
        'is_active': true,
      });
    } catch (e) {
      throw ServerFailure('Failed to submit provider onboarding: $e');
    }
  }

  Future<void> updateProviderAvailability(
    String providerId,
    AvailabilityStatus status,
  ) async {
    try {
      await client
          .from('providers')
          .update({'availability_status': status.value})
          .eq('id', providerId);
    } catch (e) {
      throw ServerFailure('Failed to update availability: $e');
    }
  }

  Future<List<Assignment>> getProviderAssignments(String providerId) async {
    try {
      final data = await client
          .from('assignments')
          .select('*, service_requests(*, service_categories(name))')
          .eq('provider_id', providerId)
          .order('assigned_at', ascending: false);

      return (data as List).map((a) => Assignment.fromJson(a)).toList();
    } catch (e) {
      throw ServerFailure('Failed to load assignments: $e');
    }
  }

  Future<void> respondToAssignment({
    required String assignmentId,
    required bool accept,
    String? declineReason,
  }) async {
    try {
      await client.rpc(
        'respond_to_assignment',
        params: {
          'p_assignment_id': assignmentId,
          'p_accept': accept,
          'p_decline_reason': declineReason,
        },
      );
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure('Failed to respond to assignment: $e');
    }
  }

  Future<void> progressServiceRequest({
    required String requestId,
    required String newStatus,
    int? finalPriceMinor,
  }) async {
    try {
      await client.rpc(
        'progress_service_request',
        params: {
          'p_request_id': requestId,
          'p_new_status': newStatus,
          'p_final_price_minor': finalPriceMinor,
        },
      );
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure('Failed to progress service order: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------------
  Future<void> submitReview({
    required String customerId,
    required String requestId,
    required String providerId,
    required int rating,
    String? comment,
  }) async {
    try {
      await client.from('reviews').insert({
        'customer_id': customerId,
        'request_id': requestId,
        'provider_id': providerId,
        'rating': rating,
        'comment': comment,
        'moderation_status': 'published',
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ValidationFailure(
          'You have already submitted a review for this completed service.',
        );
      }
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure('Failed to submit review: $e');
    }
  }

  Future<Review?> getReviewForRequest(String requestId) async {
    try {
      final data = await client
          .from('reviews')
          .select()
          .eq('request_id', requestId)
          .maybeSingle();

      if (data == null) return null;
      return Review.fromJson(data);
    } catch (e) {
      throw ServerFailure('Failed to load review: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Support Tickets
  // ---------------------------------------------------------------------------
  Future<void> submitSupportTicket({
    required String userId,
    String? requestId,
    required String issueCategory,
    required String description,
  }) async {
    try {
      await client.from('support_tickets').insert({
        'user_id': userId,
        'request_id': requestId,
        'issue_category': issueCategory,
        'description': description,
        'status': 'open',
      });
    } catch (e) {
      throw ServerFailure('Failed to submit support ticket: $e');
    }
  }

  Future<List<SupportTicket>> getUserTickets(String userId) async {
    try {
      final data = await client
          .from('support_tickets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((t) => SupportTicket.fromJson(t)).toList();
    } catch (e) {
      throw ServerFailure('Failed to load tickets: $e');
    }
  }
}
