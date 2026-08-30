import 'package:flutter/material.dart';
import '../../core/design_system/babka_colors.dart';

class UserRoleTag extends StatelessWidget {
  final String role;
  
  const UserRoleTag({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == 'customer') return const SizedBox.shrink();

    Color color;
    switch (role) {
      case 'admin':
        color = BabkaColors.error;
        break;
      case 'staff':
        color = BabkaColors.info;
        break;
      case 'delivery':
        color = BabkaColors.primary;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

