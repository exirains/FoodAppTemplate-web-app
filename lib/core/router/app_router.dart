import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/gallery/design_system_gallery_screen.dart';
import '../../features/language/language_selection_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';

import '../../features/home/main_screen.dart';
import '../../features/home/product_details_screen.dart';
import '../../features/cart/checkout_screen.dart';
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
      // Professional fade + slightly more pronounced slide
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeIn).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05), // Increased from 0.02 to 0.05
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 500), // Increased from 400 to 500
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
