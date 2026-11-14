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
import '../../features/provider/pricing/provider_pricing_screen.dart';
import '../config/app_mode.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final mode = ref.watch(kwickAppModeProvider);
  final isProviderApp = mode == KwickAppMode.provider;

  final customerRoutes = <RouteBase>[
    GoRoute(
      path: '/customer/home',
      builder: (context, state) => const CustomerHomeScreen(),
    ),
    GoRoute(
      path: '/customer/book',
      builder: (context, state) => BookingScreen(
        preselectedCategoryId: state.uri.queryParameters['categoryId'],
      ),
    ),
    GoRoute(
      path: '/customer/orders',
      builder: (context, state) => const OrderHistoryScreen(),
    ),
    GoRoute(
      path: '/customer/orders/:orderId',
      builder: (context, state) =>
          OrderDetailsScreen(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/customer/review/:orderId',
      builder: (context, state) =>
          ReviewScreen(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/customer/support',
      builder: (context, state) =>
          SupportScreen(orderId: state.uri.queryParameters['orderId']),
    ),
  ];

  final providerRoutes = <RouteBase>[
    GoRoute(
      path: '/provider/onboarding',
      builder: (context, state) => const ProviderOnboardingScreen(),
    ),
    GoRoute(
      path: '/provider/home',
      builder: (context, state) => const ProviderHomeScreen(),
    ),
    GoRoute(
      path: '/provider/pricing',
      builder: (context, state) => const ProviderPricingScreen(),
    ),
    GoRoute(
      path: '/provider/assignments/:assignmentId',
      builder: (context, state) => AssignmentDetailsScreen(
        assignmentId: state.pathParameters['assignmentId']!,
      ),
    ),
  ];

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (authState.status == AuthStatus.initial) return null;
      if (!authState.isAuthenticated) return isLoggingIn ? null : '/login';
      if (!authState.userProfile!.roles.contains(mode.role)) return '/login';
      if (isLoggingIn) {
        if (isProviderApp) {
          final approved = authState.providerProfile?.isApproved ?? false;
          return approved ? '/provider/home' : '/provider/onboarding';
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
      if (isProviderApp) ...providerRoutes else ...customerRoutes,
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
