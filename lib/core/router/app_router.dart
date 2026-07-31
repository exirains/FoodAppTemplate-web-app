import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/gallery/design_system_gallery_screen.dart';
import '../../features/language/language_selection_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';

import '../../features/home/main_screen.dart';
import '../../features/home/product_details_screen.dart';
import '../../models/bread.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/gallery',
      builder: (context, state) => const DesignSystemGalleryScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/product-details',
      builder: (context, state) {
        final bread = state.extra as Bread;
        return ProductDetailsScreen(bread: bread);
      },
    ),
  ],
);
