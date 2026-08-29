import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';

enum BabkaButtonVariant { primary, outlined, ghost }

/// Sangak Design System Buttons (v4.1.0)
///
/// Refined color application and hit-testing.
class BabkaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final BabkaButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final Widget? leading;
  final double? width;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const BabkaButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.leading,
    this.width,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  }) : variant = BabkaButtonVariant.primary;

  const BabkaButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.leading,
    this.width,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  }) : variant = BabkaButtonVariant.outlined;

  const BabkaButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.leading,
    this.width,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  }) : variant = BabkaButtonVariant.ghost;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = variant == BabkaButtonVariant.primary;
    final bool isOutlined = variant == BabkaButtonVariant.outlined;

    final Color effectiveBgColor = _isEnabled
        ? (backgroundColor ?? (isPrimary ? BabkaColors.primary : Colors.transparent))
        : (isPrimary ? BabkaColors.border : Colors.transparent);

    final Color effectiveFgColor = _isEnabled
        ? (foregroundColor ?? (isPrimary ? Colors.white : BabkaColors.primary))
        : BabkaColors.inkLight;

    final Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveFgColor),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: BabkaDimens.spacing8),
              ],
              if (icon != null) ...[
                Icon(icon, size: 20, color: effectiveFgColor),
                if (label.isNotEmpty) const SizedBox(width: BabkaDimens.spacing8),
              ],
              if (label.isNotEmpty)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: BabkaTypography.button(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: effectiveFgColor,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
            ],
          );

    final ButtonStyle style = (isOutlined || variant == BabkaButtonVariant.ghost)
        ? TextButton.styleFrom(
            backgroundColor: effectiveBgColor,
            foregroundColor: effectiveFgColor,
            minimumSize: Size(width ?? double.infinity, 54),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
              side: isOutlined
                  ? BorderSide(
                      color: _isEnabled ? (borderColor ?? BabkaColors.primary) : BabkaColors.border,
                      width: 1.5,
                    )
                  : BorderSide.none,
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: effectiveBgColor,
            foregroundColor: effectiveFgColor,
            disabledBackgroundColor: BabkaColors.border,
            disabledForegroundColor: BabkaColors.inkLight,
            elevation: _isEnabled ? 2 : 0,
            minimumSize: Size(width ?? double.infinity, 54),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
            ),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: isPrimary
          ? ElevatedButton(
              onPressed: _isEnabled ? onPressed : null,
              style: style,
              child: child,
            )
          : TextButton(
              onPressed: _isEnabled ? onPressed : null,
              style: style,
              child: child,
            ),
    );
  }
}
