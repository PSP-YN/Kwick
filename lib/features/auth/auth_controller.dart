import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../shared/models/provider_profile.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/user_role.dart';
import '../../shared/services/supabase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserProfile? userProfile;
  final ProviderProfile? providerProfile;
  final UserRole activeRole;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userProfile,
    this.providerProfile,
    this.activeRole = UserRole.customer,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && userProfile != null;
  bool get isProvider => activeRole == UserRole.provider;
  bool get isAdmin =>
      activeRole == UserRole.admin || activeRole == UserRole.superAdmin;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? userProfile,
    ProviderProfile? providerProfile,
    UserRole? activeRole,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      providerProfile: providerProfile ?? this.providerProfile,
      activeRole: activeRole ?? this.activeRole,
      errorMessage: errorMessage,
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  SupabaseService get _supabase => ref.read(supabaseServiceProvider);

  @override
  AuthState build() {
    Future.microtask(() => _init());
    return const AuthState();
  }

  Future<void> _init() async {
    final user = _supabase.currentUser;
    if (user != null) {
      await refreshProfile();
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }

    _supabase.authStateChanges.listen((data) {
      if (data.session == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else {
        refreshProfile();
      }
    });
  }

  Future<void> refreshProfile() async {
    final user = _supabase.currentUser;
    if (user == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final profile = await _supabase.fetchUserProfile(user.id);
      ProviderProfile? providerProfile;

      if (profile != null && profile.isProvider) {
        providerProfile = await _supabase.getProviderProfile(user.id);
      }

      final activeRole =
          (profile != null &&
              profile.isProvider &&
              !profile.roles.contains(UserRole.customer))
          ? UserRole.provider
          : (profile?.roles.first ?? UserRole.customer);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        userProfile: profile,
        providerProfile: providerProfile,
        activeRole: activeRole,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _supabase.signIn(email: email, password: password);
      await refreshProfile();
    } on Failure catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to sign in: $e',
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    UserRole initialRole = UserRole.customer,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _supabase.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        initialRole: initialRole,
      );
      await refreshProfile();
    } on Failure catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to create account: $e',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _supabase.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to sign out: $e',
      );
    }
  }

  void switchActiveRole(UserRole role) {
    if (state.userProfile?.roles.contains(role) == true) {
      state = state.copyWith(activeRole: role);
    }
  }
}
