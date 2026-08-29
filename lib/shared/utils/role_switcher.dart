import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../l10n/app_localizations.dart';

class RoleSwitcher {
  static void show(BuildContext context, String userRole) {
    debugPrint('Opening RoleSwitcher with role: $userRole');
    
    final l10n = AppLocalizations.of(context);
    final currentPath = GoRouterState.of(context).uri.path;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Fix ListTile ink splashes
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: BabkaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: BabkaColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(l10n.roleSwitch, style: BabkaTypography.h3(context)),
              const SizedBox(height: 24),
              
              // Everyone can see the Customer App
              _buildRoleItem(
                context, 
                l10n.customerApp, 
                Icons.person_outline, 
                currentPath.startsWith('/home') || currentPath == '/', 
                '/home',
              ),
              
              // Admin Panel
              if (userRole == 'admin')
                _buildRoleItem(
                  context, 
                  l10n.adminPanel, 
                  Icons.admin_panel_settings_outlined, 
                  currentPath.startsWith('/admin'), 
                  '/admin',
                ),

              // Kitchen Panel (Admin or Staff)
              if (userRole == 'staff' || userRole == 'admin')
                _buildRoleItem(
                  context, 
                  l10n.kitchenPanel, 
                  Icons.restaurant_menu_rounded, 
                  currentPath.startsWith('/staff'), 
                  '/staff',
                ),
              
              // Delivery Panel (Admin or Delivery)
              if (userRole == 'delivery' || userRole == 'admin')
                _buildRoleItem(
                  context, 
                  l10n.deliveryPanel, 
                  Icons.delivery_dining_outlined, 
                  currentPath.startsWith('/delivery'), 
                  '/delivery',
                ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRoleItem(BuildContext context, String label, IconData icon, bool isActive, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive ? null : () {
            Navigator.pop(context);
            context.go(route);
          },
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isActive ? BabkaColors.primary.withValues(alpha: 0.05) : BabkaColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? BabkaColors.primary.withValues(alpha: 0.2) : BabkaColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: isActive ? BabkaColors.primary : BabkaColors.inkLight),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label, style: BabkaTypography.title(context).copyWith(
                    fontSize: 16,
                    color: isActive ? BabkaColors.ink : BabkaColors.inkLight,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  )),
                ),
                if (isActive) 
                  const Icon(Icons.check_circle, color: BabkaColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
