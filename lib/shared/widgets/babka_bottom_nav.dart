import 'package:flutter/material.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../core/design_system/babka_dimens.dart';
import '../../l10n/app_localizations.dart';

/// Babka Design System Bottom Navigation (v1.0.0)
class BabkaBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BabkaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: BabkaColors.surface,
        boxShadow: BabkaDimens.shadowHigh,
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: BabkaColors.surface,
        selectedItemColor: BabkaColors.primary,
        unselectedItemColor: BabkaColors.inkLight,
        selectedLabelStyle: BabkaTypography.caption(context).copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: BabkaTypography.caption(context),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.breakfast_dining_outlined),
            activeIcon: const Icon(Icons.breakfast_dining),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
            label: l10n.explore,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_basket_outlined),
            activeIcon: const Icon(Icons.shopping_basket),
            label: l10n.basket,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}


