import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      // Modern horizontal sliding transition
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0), // Start from right
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

final appRouter = GoRouter(
  initialLocation: '/',
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
