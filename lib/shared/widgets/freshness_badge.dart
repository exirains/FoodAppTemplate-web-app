import 'package:flutter/material.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/design_system/sangak_tokens.dart';

/// Sangak Design System Freshness Badge (v1.1.0)
///
/// Reusable status badge for freshness indicators.
class FreshnessBadge extends StatelessWidget {
  final FreshnessToken token;

  const FreshnessBadge({
    super.key,
    required this.token,
  });

  factory FreshnessBadge.freshToday() => FreshnessBadge(token: BabkaTokens.freshToday);
  factory FreshnessBadge.outOfOven() => FreshnessBadge(token: BabkaTokens.outOfOven);
  factory FreshnessBadge.limited() => FreshnessBadge(token: BabkaTokens.limitedQuantity);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BabkaDimens.spacing8,
        vertical: BabkaDimens.spacing4,
      ),
      decoration: BoxDecoration(
        color: token.color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            token.icon,
            size: 14,
            color: token.color,
          ),
          const SizedBox(width: BabkaDimens.spacing4),
          Text(
            token.localizedLabel(l10n).toUpperCase(),
            style: BabkaTypography.caption(context).copyWith(
              color: token.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
