import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';

/// Sangak Design System TextField (v1.0.0)
///
/// Supports Label, Hint, Error, Leading/Trailing Icons, and Password visibility.
class SangakTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? errorText;
  final bool isPassword;
  final TextEditingController? controller;
  final IconData? leadingIcon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;

  const SangakTextField({
    super.key,
    required this.label,
    this.hintText,
    this.errorText,
    this.isPassword = false,
    this.controller,
    this.leadingIcon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
  });

  @override
  State<SangakTextField> createState() => _SangakTextFieldState();
}

class _SangakTextFieldState extends State<SangakTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: SangakTypography.title.copyWith(fontSize: 14),
        ),
        const SizedBox(height: SangakDimens.spacing8),
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: Container(
            decoration: BoxDecoration(
              color: SangakColors.surface,
              borderRadius: BorderRadius.circular(SangakDimens.radiusM),
              border: Border.all(
                color: widget.errorText != null
                    ? SangakColors.error
                    : _isFocused
                        ? SangakColors.primary
                        : SangakColors.border,
                width: _isFocused || widget.errorText != null ? 1.5 : 1.0,
              ),
              boxShadow: _isFocused ? SangakDimens.shadowLow : null,
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.isPassword && _obscureText,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              validator: widget.validator,
              onChanged: widget.onChanged,
              style: SangakTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: SangakTypography.bodyMedium.copyWith(color: SangakColors.inkLight),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: SangakDimens.spacing16,
                  vertical: 16,
                ),
                prefixIcon: widget.leadingIcon != null
                    ? Icon(widget.leadingIcon, color: SangakColors.inkLight)
                    : null,
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: SangakColors.inkLight,
                        ),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      )
                    : null,
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: SangakDimens.spacing4),
          Text(
            widget.errorText!,
            style: SangakTypography.bodySmall.copyWith(color: SangakColors.error),
          ),
        ],
      ],
    );
  }
}
