import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';

/// Sangak Design System Quantity Selector (v1.0.0)
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: SangakColors.primary,
        borderRadius: BorderRadius.circular(SangakDimens.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconButton(icon: Icons.remove, onPressed: onDecrement),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: SangakDimens.spacing8),
            child: Text(
              '$quantity',
              style: SangakTypography.title.copyWith(color: Colors.white, fontSize: 14),
            ),
          ),
          _IconButton(icon: Icons.add, onPressed: onIncrement),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(SangakDimens.radiusM),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SangakDimens.spacing8),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
