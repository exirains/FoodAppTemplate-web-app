import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../l10n/app_localizations.dart';
import 'auth_validators.dart';

/// Widget that displays password strength indicator
/// Shows a progress bar and text label indicating strength level
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showLabel;
  final bool showRequirements;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showLabel = true,
    this.showRequirements = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = AuthValidators.calculatePasswordStrength(password);
    final strengthLabel = AuthValidators.getPasswordStrengthLabel(password);

    Color barColor;
    switch (strengthLabel) {
      case 'weak':
        barColor = const Color(0xFFE74C3C); // Red
        break;
      case 'fair':
        barColor = const Color(0xFFF39C12); // Orange
        break;
      case 'good':
        barColor = const Color(0xFFF1C40F); // Yellow
        break;
      case 'strong':
        barColor = const Color(0xFF2ECC71); // Green
        break;
      default:
        barColor = BabkaColors.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength indicator bar
        ClipRRect(
          borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
          child: LinearProgressIndicator(
            value: strength,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: BabkaDimens.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.passwordStrength,
                style: BabkaTypography.caption(context).copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                _getLabelText(strengthLabel, l10n),
                style: BabkaTypography.bodySmall(context).copyWith(
                  color: barColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
        if (showRequirements) ...[
          const SizedBox(height: BabkaDimens.spacing16),
          _RequirementsList(password: password, l10n: l10n),
        ],
      ],
    );
  }

  String _getLabelText(String label, AppLocalizations l10n) {
    switch (label) {
      case 'weak':
        return l10n.weak;
      case 'fair':
        return l10n.fair;
      case 'good':
        return l10n.good;
      case 'strong':
        return l10n.strong;
      default:
        return '';
    }
  }
}

/// Internal widget that shows password requirements
class _RequirementsList extends StatelessWidget {
  final String password;
  final AppLocalizations l10n;

  const _RequirementsList({
    required this.password,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final hasMinLength = password.length >= AuthValidators.minPasswordLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequirementItem(
          text: l10n.passwordRequirementLength,
          isMet: hasMinLength,
        ),
      ],
    );
  }
}

/// Individual requirement item
class _RequirementItem extends StatelessWidget {
  final String text;
  final bool isMet;

  const _RequirementItem({
    required this.text,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMet ? const Color(0xFF2ECC71) : Colors.grey.shade400;
    
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMet ? color.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(
              color: isMet ? color : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: isMet
              ? Icon(
                  Icons.check,
                  size: 12,
                  color: color,
                )
              : null,
        ),
        const SizedBox(width: BabkaDimens.spacing12),
        Expanded(
          child: Text(
            text,
            style: BabkaTypography.bodySmall(context).copyWith(
              color: isMet ? Colors.grey.shade700 : Colors.grey.shade400,
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
