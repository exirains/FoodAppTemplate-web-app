import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sangak Design System Quantity Selector (v1.1.0)
///
/// Supports Trash icon for deletion when quantity is 1.
class QuantitySelector extends ConsumerWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onDelete;
  final bool compact;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.onDelete,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(localeProvider).languageCode;
    final formattedQuantity = SangakNumberFormatter.format(quantity, languageCode);

    return Container(
      height: compact ? 34 : 36,
      decoration: BoxDecoration(
        color: SangakColors.primary,
        borderRadius: BorderRadius.circular(SangakDimens.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconButton(
            icon: quantity == 1 && onDelete != null ? Icons.delete_outline : Icons.remove,
            onPressed: quantity == 1 && onDelete != null ? onDelete! : onDecrement,
            compact: compact,
          ),
          Container(
            constraints: BoxConstraints(minWidth: compact ? 24 : 28),
            padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
            child: Text(
              formattedQuantity,
              textAlign: TextAlign.center,
              style: SangakTypography.title(context).copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          _IconButton(icon: Icons.add, onPressed: onIncrement, compact: compact),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool compact;

  const _IconButton({
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(SangakDimens.radiusM),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 8),
          child: Icon(icon, size: compact ? 17 : 18, color: Colors.white),
        ),
      ),
    );
  }
}
