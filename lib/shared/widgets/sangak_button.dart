import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';

enum SangakButtonVariant { primary, outlined, ghost }

/// Sangak Design System Button (v1.1.0)
///
/// Refined with Material/InkWell for superior gesture stability and reliability.
class SangakButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final SangakButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final Widget? leading;
  final double? width;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const SangakButton.primary({
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
  }) : variant = SangakButtonVariant.primary;

  const SangakButton.outlined({
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
  }) : variant = SangakButtonVariant.outlined;

  const SangakButton.ghost({
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
  }) : variant = SangakButtonVariant.ghost;

  @override
  State<SangakButton> createState() => _SangakButtonState();
}

class _SangakButtonState extends State<SangakButton> {
  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  Color _getBackgroundColor() {
    if (!_isEnabled && widget.variant == SangakButtonVariant.primary) {
      return SangakColors.border;
    }
    
    switch (widget.variant) {
      case SangakButtonVariant.primary:
        return widget.backgroundColor ?? SangakColors.primary;
      case SangakButtonVariant.outlined:
      case SangakButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor() {
    if (!_isEnabled) return SangakColors.inkLight;
    if (widget.foregroundColor != null) return widget.foregroundColor!;
    
    switch (widget.variant) {
      case SangakButtonVariant.primary:
        return Colors.white;
      case SangakButtonVariant.outlined:
      case SangakButtonVariant.ghost:
        return SangakColors.primary;
    }
  }

  Border? _getBorder() {
    if (widget.variant == SangakButtonVariant.outlined) {
      return Border.all(
        color: _isEnabled ? (widget.borderColor ?? SangakColors.primary) : SangakColors.border,
        width: 1.5,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: 54, // Signature standard height
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(SangakDimens.radiusM),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isEnabled ? widget.onPressed : null,
          splashColor: _isEnabled 
              ? (widget.variant == SangakButtonVariant.primary 
                  ? Colors.white10 
                  : SangakColors.primary.withValues(alpha: 0.1))
              : null,
          highlightColor: Colors.transparent,
          child: Container(
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: SangakDimens.spacing24),
            decoration: BoxDecoration(
              border: _getBorder(),
              borderRadius: BorderRadius.circular(SangakDimens.radiusM),
              boxShadow: widget.variant == SangakButtonVariant.primary && _isEnabled
                  ? SangakDimens.shadowLow
                  : null,
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_getForegroundColor()),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.leading != null) ...[
                            widget.leading!,
                            const SizedBox(width: SangakDimens.spacing8),
                          ],
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 20, color: _getForegroundColor()),
                            const SizedBox(width: SangakDimens.spacing8),
                          ],
                          Flexible(
                            child: Text(
                              widget.label,
                              style: SangakTypography.button(context).copyWith(
                                color: _getForegroundColor(),
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
