import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../core/config/app_mode.dart';
import '../../core/logging/app_logger.dart';
import '../../shared/models/provider_profile.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/user_role.dart';
import '../../shared/services/supabase_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  awaitingEmailConfirmation,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserProfile? userProfile;
  final ProviderProfile? providerProfile;
  final UserRole activeRole;
  final String? errorMessage;
  final String? infoMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userProfile,
    this.providerProfile,
    this.activeRole = UserRole.customer,
    this.errorMessage,
    this.infoMessage,
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
    String? infoMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      providerProfile: providerProfile ?? this.providerProfile,
      activeRole: activeRole ?? this.activeRole,
      errorMessage: errorMessage,
      infoMessage: infoMessage ?? this.infoMessage,
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  SupabaseService get _supabase => ref.read(supabaseServiceProvider);
  StreamSubscription<dynamic>? _authSubscription;
  int _refreshGeneration = 0;

  @override
  AuthState build() {
    ref.onDispose(() => _authSubscription?.cancel());
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

    _authSubscription = _supabase.authStateChanges.listen((data) {
      if (data.session == null) {
        _refreshGeneration++;
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else {
        refreshProfile();
      }
    });
  }

  Future<void> refreshProfile() async {
    final generation = ++_refreshGeneration;
    final user = _supabase.currentUser;
    if (user == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final profile = await _supabase.fetchUserProfile(user.id);
      if (generation != _refreshGeneration) return;
      final requiredRole = ref.read(kwickAppModeProvider).role;
      if (profile == null || !profile.roles.contains(requiredRole)) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: requiredRole == UserRole.provider
              ? 'This account is not registered as a Kwick service partner. Use the customer app or create a partner account.'
              : 'This account is not registered as a Kwick customer. Use the Kwick Partner app or create a customer account.',
        );
        return;
      }

      ProviderProfile? providerProfile;
      if (requiredRole == UserRole.provider) {
        providerProfile = await _supabase.getProviderProfile(user.id);
      }
      final activeRole = requiredRole;

      state = state.copyWith(
        status: AuthStatus.authenticated,
        userProfile: profile,
        providerProfile: providerProfile,
        activeRole: activeRole,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      if (generation != _refreshGeneration) return;
      AppLogger.error(
        'auth_profile_refresh_failed',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage:
            'We could not load your account. Check your connection and try again.',
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _supabase.signIn(email: email, password: password);
      await refreshProfile();
    } on Failure catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (e, stackTrace) {
      AppLogger.error('auth_sign_in_failed', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Sign-in failed. Check your details and try again.',
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    UserRole? initialRole,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final requiredRole = ref.read(kwickAppModeProvider).role;
      if (initialRole != null && initialRole != requiredRole) {
        throw const ValidationFailure(
          'This Kwick app can only create its own account type.',
        );
      }
      final response = await _supabase.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        initialRole: requiredRole,
      );
      if (response.session == null) {
        state = AuthState(
          status: AuthStatus.awaitingEmailConfirmation,
          infoMessage:
              'Account created. Check $email for the confirmation link, then sign in.',
        );
        return;
      }
      await refreshProfile();
    } on Failure catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (e, stackTrace) {
      AppLogger.error('auth_sign_up_failed', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage:
            'Account creation failed. Check the details and try again.',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _supabase.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e, stackTrace) {
      AppLogger.error('auth_sign_out_failed', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Sign-out failed. Please try again.',
      );
    }
  }

  void switchActiveRole(UserRole role) {
    if (state.userProfile?.roles.contains(role) == true) {
      state = state.copyWith(activeRole: role);
    }
  }
}
