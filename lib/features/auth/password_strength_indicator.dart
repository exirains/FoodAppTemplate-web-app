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
        barColor = SangakColors.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength indicator bar
        ClipRRect(
          borderRadius: BorderRadius.circular(SangakDimens.spacing8),
          child: LinearProgressIndicator(
            value: strength,
            minHeight: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: SangakDimens.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.passwordStrength,
                style: SangakTypography.caption(context).copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                _getLabelText(strengthLabel, l10n),
                style: SangakTypography.bodySmall(context).copyWith(
                  color: barColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
        if (showRequirements) ...[
          const SizedBox(height: SangakDimens.spacing16),
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
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    final hasSpecialChar =
        RegExp(r"[!@#$%^&*()_+\-=\[\]{};:',.<>?/\\|`~]").hasMatch(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequirementItem(
          text: '${l10n.passwordTooShort} (8+ characters)',
          isMet: hasMinLength,
        ),
        const SizedBox(height: SangakDimens.spacing8),
        _RequirementItem(
          text: 'At least one uppercase letter (A-Z)',
          isMet: hasUpperCase,
        ),
        const SizedBox(height: SangakDimens.spacing8),
        _RequirementItem(
          text: 'At least one lowercase letter (a-z)',
          isMet: hasLowerCase,
        ),
        const SizedBox(height: SangakDimens.spacing8),
        _RequirementItem(
          text: 'At least one number (0-9)',
          isMet: hasNumber,
        ),
        const SizedBox(height: SangakDimens.spacing8),
        _RequirementItem(
          text: 'Special characters (!@#\$%^&*) - Recommended',
          isMet: hasSpecialChar,
          isOptional: true,
        ),
      ],
    );
  }
}

/// Individual requirement item
class _RequirementItem extends StatelessWidget {
  final String text;
  final bool isMet;
  final bool isOptional;

  const _RequirementItem({
    required this.text,
    required this.isMet,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isMet ? const Color(0xFF2ECC71) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: isMet
              ? const Icon(
                  Icons.check,
                  size: 14,
                  color: Color(0xFF2ECC71),
                )
              : null,
        ),
        const SizedBox(width: SangakDimens.spacing12),
        Expanded(
          child: Text(
            text,
            style: SangakTypography.bodySmall(context).copyWith(
              color: isMet ? Colors.grey.shade600 : Colors.grey.shade400,
              decoration: isOptional ? TextDecoration.none : null,
            ),
          ),
        ),
      ],
    );
  }
}
