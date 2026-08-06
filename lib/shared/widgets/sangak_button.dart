import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/design_system/sangak_tokens.dart';

enum SangakButtonVariant { primary, outlined, ghost }

/// Sangak Design System Button (v1.0.0)
///
/// Supports Primary, Outlined, and Ghost variants with Loading and Disabled states.
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
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  Color _getBackgroundColor() {
    if (!_isEnabled && widget.variant == SangakButtonVariant.primary) {
      return SangakColors.border;
    }
    
    switch (widget.variant) {
      case SangakButtonVariant.primary:
        return widget.backgroundColor ?? (_isPressed ? SangakColors.secondary : SangakColors.primary);
      case SangakButtonVariant.outlined:
      case SangakButtonVariant.ghost:
        return _isPressed ? SangakColors.background : Colors.transparent;
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
    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: _isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _isEnabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: SangakTokens.animFast,
          child: AnimatedContainer(
            duration: SangakTokens.animFast,
            width: widget.width,
            height: 54, // Fixed height for consistency
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: SangakDimens.spacing24),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(SangakDimens.radiusM),
              border: _getBorder(),
              boxShadow: widget.variant == SangakButtonVariant.primary && !_isPressed
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
