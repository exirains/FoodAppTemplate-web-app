import 'package:flutter/material.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/design_system/sangak_tokens.dart';

/// Sangak Design System Freshness Badge (v1.0.0)
///
/// Reusable status badge for freshness indicators.
class FreshnessBadge extends StatelessWidget {
  final FreshnessToken token;

  const FreshnessBadge({
    super.key,
    required this.token,
  });

  factory FreshnessBadge.freshToday() => FreshnessBadge(token: SangakTokens.freshToday);
  factory FreshnessBadge.outOfOven() => FreshnessBadge(token: SangakTokens.outOfOven);
  factory FreshnessBadge.limited() => FreshnessBadge(token: SangakTokens.limitedQuantity);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SangakDimens.spacing8,
        vertical: SangakDimens.spacing4,
      ),
      decoration: BoxDecoration(
        color: token.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(SangakDimens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            token.icon,
            size: 14,
            color: token.color,
          ),
          const SizedBox(width: SangakDimens.spacing4),
          Text(
            token.label.toUpperCase(),
            style: SangakTypography.caption.copyWith(
              color: token.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
