import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/gallery/design_system_gallery_screen.dart';
import '../../features/language/language_selection_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';

import '../../features/home/main_screen.dart';
import '../../features/home/product_details_screen.dart';
import '../../features/basket/checkout_screen.dart';
import '../../features/basket/address_selection_screen.dart';
import '../../features/basket/payment_selection_screen.dart';
import '../../features/basket/order_confirmation_screen.dart';
import '../../features/orders/order_history_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/order_management_screen.dart';
import '../../features/admin/admin_order_detail_screen.dart';
import '../../features/admin/product_management_screen.dart';
import '../../features/admin/user_management_screen.dart';
import '../../features/staff/staff_kitchen_screen.dart';
import '../../features/delivery/delivery_dashboard_screen.dart';
import '../../features/delivery/delivery_order_detail_screen.dart';
import '../../features/auth/profile_provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../models/bread.dart';

// Helper for silky smooth transitions
CustomTransitionPage _buildPageWithTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        )),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = authState.asData?.value;
      final profile = profileAsync.value;
      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/register';

      if (user != null && profile != null && isLoggingIn) {
        // Redirect based on role after login
        switch (profile.role) {
          case 'admin':
            return '/admin';
          case 'staff':
            return '/staff';
          case 'delivery':
            return '/delivery';
          default:
            return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/language',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const LanguageSelectionScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/gallery',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const DesignSystemGalleryScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const MainScreen(),
        ),
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const CheckoutScreen(),
        ),
      ),
      GoRoute(
        path: '/address-selection',
        pageBuilder: (context, state) {
          final fromCheckout = state.uri.queryParameters['from'] == 'checkout';
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: AddressSelectionScreen(fromCheckout: fromCheckout),
          );
        },
      ),
      GoRoute(
        path: '/payment-selection',
        pageBuilder: (context, state) {
          final fromCheckout = state.uri.queryParameters['from'] == 'checkout';
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: PaymentSelectionScreen(fromCheckout: fromCheckout),
          );
        },
      ),
      GoRoute(
        path: '/order-confirmation',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const OrderConfirmationScreen(),
        ),
      ),
      GoRoute(
        path: '/orders',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const OrderHistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const FavoritesScreen(),
        ),
      ),
      // Admin Routes
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const AdminDashboardScreen(),
        ),
        routes: [
          GoRoute(
            path: 'orders',
            pageBuilder: (context, state) {
              final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
              return _buildPageWithTransition(
                context: context,
                state: state,
                child: OrderManagementScreen(initialTab: tab),
              );
            },
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _buildPageWithTransition(
                    context: context,
                    state: state,
                    child: AdminOrderDetailScreen(orderId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'products',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context: context,
              state: state,
              child: const ProductManagementScreen(),
            ),
          ),
          GoRoute(
            path: 'users',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context: context,
              state: state,
              child: const UserManagementScreen(),
            ),
          ),
        ],
      ),
      // Staff Routes
      GoRoute(
        path: '/staff',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const StaffKitchenScreen(),
        ),
      ),
      // Delivery Routes
      GoRoute(
        path: '/delivery',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const DeliveryDashboardScreen(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _buildPageWithTransition(
                context: context,
                state: state,
                child: DeliveryOrderDetailScreen(orderId: id),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/product-details',
        pageBuilder: (context, state) {
          final bread = state.extra as Bread;
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: ProductDetailsScreen(bread: bread),
          );
        },
      ),
    ],
  );
});
