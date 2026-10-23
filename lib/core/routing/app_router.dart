import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/customer/booking/booking_screen.dart';
import '../../features/customer/customer_home_screen.dart';
import '../../features/customer/order_history/order_details_screen.dart';
import '../../features/customer/order_history/order_history_screen.dart';
import '../../features/customer/reviews/review_screen.dart';
import '../../features/customer/support/support_screen.dart';
import '../../features/provider/assignments/assignment_details_screen.dart';
import '../../features/provider/onboarding/provider_onboarding_screen.dart';
import '../../features/provider/provider_home_screen.dart';
import '../../shared/models/user_role.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isAuth = authState.isAuthenticated;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // If still checking initial state, allow navigation to continue
      if (authState.status == AuthStatus.initial) {
        return null;
      }

      // Unauthenticated users must be on login/register
      if (!isAuth) {
        return isLoggingIn ? null : '/login';
      }

      // If authenticated and visiting login or register, route to appropriate home
      if (isLoggingIn) {
        if (authState.activeRole == UserRole.provider) {
          final isApproved = authState.providerProfile?.isApproved ?? false;
          return isApproved ? '/provider/home' : '/provider/onboarding';
        }
        return '/customer/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer Routes
      GoRoute(
        path: '/customer/home',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: '/customer/book',
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          return BookingScreen(preselectedCategoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/customer/orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/customer/orders/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailsScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/customer/review/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return ReviewScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/customer/support',
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'];
          return SupportScreen(orderId: orderId);
        },
      ),

      // Provider Routes
      GoRoute(
        path: '/provider/onboarding',
        builder: (context, state) => const ProviderOnboardingScreen(),
      ),
      GoRoute(
        path: '/provider/home',
        builder: (context, state) => const ProviderHomeScreen(),
      ),
      GoRoute(
        path: '/provider/assignments/:assignmentId',
        builder: (context, state) {
          final assignmentId = state.pathParameters['assignmentId']!;
          return AssignmentDetailsScreen(assignmentId: assignmentId);
        },
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) => notifyListeners(),
    );
  }
}
