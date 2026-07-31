import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';

/// Sangak Design System Bottom Navigation (v1.0.0)
class SangakBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SangakBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SangakColors.surface,
        boxShadow: SangakDimens.shadowHigh,
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: SangakColors.surface,
        selectedItemColor: SangakColors.primary,
        unselectedItemColor: SangakColors.inkLight,
        selectedLabelStyle: SangakTypography.caption.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: SangakTypography.caption,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.breakfast_dining_outlined),
            activeIcon: Icon(Icons.breakfast_dining),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket_outlined),
            activeIcon: Icon(Icons.shopping_basket),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
