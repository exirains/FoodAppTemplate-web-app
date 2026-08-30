import 'package:flutter/material.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';

/// Babka Design System AppBar (v1.0.0)
class BabkaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;

  const BabkaAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null ? Text(title!, style: BabkaTypography.h3(context)) : null,
      leading: leading ?? (showBackButton && Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null),
      actions: actions,
      backgroundColor: BabkaColors.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


