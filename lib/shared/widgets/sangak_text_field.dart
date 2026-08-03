import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';

/// Sangak Design System TextField (v2.0.0)
///
/// Enhanced version supporting:
/// - Label, Hint, Error, Leading/Trailing Icons
/// - Password visibility toggle
/// - Focus node management
/// - Text input actions
/// - Custom trailing icon handlers
class SangakTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? errorText;
  final bool isPassword;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingIconPressed;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final VoidCallback? onEditingComplete;
  final bool enabled;

  const SangakTextField({
    super.key,
    required this.label,
    this.hintText,
    this.errorText,
    this.isPassword = false,
    this.controller,
    this.focusNode,
    this.leadingIcon,
    this.trailingIcon,
    this.onTrailingIconPressed,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
    this.enabled = true,
  });

  @override
  State<SangakTextField> createState() => _SangakTextFieldState();
}

class _SangakTextFieldState extends State<SangakTextField> {
  bool _obscureText = true;
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _setFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(covariant SangakTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
      _setFocusNode(widget.focusNode);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _setFocusNode(FocusNode? focusNode) {
    _ownsFocusNode = focusNode == null;
    _focusNode = focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: SangakTypography.title(context).copyWith(fontSize: 14),
        ),
        const SizedBox(height: SangakDimens.spacing8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          style: SangakTypography.bodyLarge(context),
          textAlign: (widget.keyboardType == TextInputType.phone || 
                      widget.keyboardType == TextInputType.emailAddress ||
                      widget.isPassword) 
              ? TextAlign.left 
              : TextAlign.start,
          textDirection: (widget.keyboardType == TextInputType.phone || 
                          widget.keyboardType == TextInputType.emailAddress ||
                          widget.isPassword) 
              ? TextDirection.ltr 
              : null,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: SangakTypography.bodyMedium(context).copyWith(color: SangakColors.inkLight),
            filled: true,
            fillColor: widget.enabled ? SangakColors.surface : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SangakDimens.spacing16,
              vertical: 16,
            ),
            prefixIcon: widget.leadingIcon != null
                ? Icon(widget.leadingIcon, color: SangakColors.inkLight)
                : null,
            suffixIcon: _buildSuffixIcon(),
            errorText: widget.errorText,
            errorMaxLines: 1,
            errorStyle: SangakTypography.bodySmall(context).copyWith(
              color: SangakColors.error,
              height: 0.8,
              fontSize: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SangakDimens.radiusM),
              borderSide: const BorderSide(color: SangakColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SangakDimens.radiusM),
              borderSide: const BorderSide(color: SangakColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SangakDimens.radiusM),
              borderSide: const BorderSide(color: SangakColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SangakDimens.radiusM),
              borderSide: const BorderSide(color: SangakColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SangakDimens.radiusM),
              borderSide: const BorderSide(color: SangakColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Build the suffix icon (password toggle or custom icon)
  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: SangakColors.inkLight,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }

    if (widget.trailingIcon != null) {
      return IconButton(
        icon: Icon(widget.trailingIcon, color: SangakColors.inkLight),
        onPressed: widget.onTrailingIconPressed,
      );
    }

    return null;
  }
}
