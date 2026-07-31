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
  final double? width;

  const SangakButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = SangakButtonVariant.primary;

  const SangakButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = SangakButtonVariant.outlined;

  const SangakButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
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
        return _isPressed ? SangakColors.secondary : SangakColors.primary;
      case SangakButtonVariant.outlined:
      case SangakButtonVariant.ghost:
        return _isPressed ? SangakColors.background : Colors.transparent;
    }
  }

  Color _getForegroundColor() {
    if (!_isEnabled) return SangakColors.inkLight;
    
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
        color: _isEnabled ? SangakColors.primary : SangakColors.border,
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
        child: AnimatedContainer(
          duration: SangakTokens.animFast,
          width: widget.width,
          height: 54, // Fixed height for consistency
          padding: const EdgeInsets.symmetric(horizontal: SangakDimens.spacing24),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(SangakDimens.radiusM),
            border: _getBorder(),
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
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: _getForegroundColor()),
                        const SizedBox(width: SangakDimens.spacing8),
                      ],
                      Text(
                        widget.label,
                        style: SangakTypography.button.copyWith(
                          color: _getForegroundColor(),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
