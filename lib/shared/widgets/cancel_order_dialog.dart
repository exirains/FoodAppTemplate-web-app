import 'package:flutter/material.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../l10n/app_localizations.dart';
import '../utils/babka_toast.dart';

class CancelOrderDialog extends StatefulWidget {
  final Function(String reason) onConfirm;
  
  const CancelOrderDialog({super.key, required this.onConfirm});

  static Future<void> show(BuildContext context, {required Function(String reason) onConfirm}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CancelOrderDialog(onConfirm: onConfirm),
    );
  }

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _sliderValue = 0.0;
  bool _isUnlocked = false;
  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: BabkaColors.error),
          const SizedBox(width: 12),
          Text(l10n.cancelOrder),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isUnlocked) ...[
              Text(
                l10n.unlockCancellation,
                style: BabkaTypography.bodyMedium(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildSlider(context, l10n),
            ] else ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cancellationReason,
                      style: BabkaTypography.title(context).copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildReasonOption(l10n.cancelReasonBusy),
                    _buildReasonOption(l10n.cancelReasonStock),
                    _buildReasonOption(l10n.cancelReasonCourier),
                    _buildReasonOption(l10n.cancelReasonTechnical),
                    _buildReasonOption(l10n.cancelReasonOther),
                    
                    if (_selectedReason == l10n.cancelReasonOther) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 3,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: l10n.enterReason,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: BabkaColors.error),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text(l10n.cancel, style: const TextStyle(color: BabkaColors.inkLight)),
        ),
        if (_isUnlocked)
          TextButton(
            onPressed: () {
              if (_selectedReason == null) {
                BabkaToast.show(context, 'Please select a reason');
                return;
              }
              
              String finalReason = _selectedReason!;
              if (_selectedReason == l10n.cancelReasonOther) {
                if (!_formKey.currentState!.validate()) return;
                finalReason = _reasonController.text.trim();
              }
              
              Navigator.pop(context);
              widget.onConfirm(finalReason);
            },
            style: TextButton.styleFrom(foregroundColor: BabkaColors.error),
            child: Text(l10n.confirmButton),
          ),
      ],
    );
  }

  Widget _buildReasonOption(String reason) {
    final isSelected = _selectedReason == reason;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedReason = reason),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? BabkaColors.error.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? BabkaColors.error : BabkaColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? BabkaColors.error : BabkaColors.inkLight,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                reason,
                style: BabkaTypography.bodyMedium(context).copyWith(
                  color: isSelected ? BabkaColors.ink : BabkaColors.inkLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(BuildContext context, AppLocalizations l10n) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: BabkaColors.background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: BabkaColors.border),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              l10n.slidetoReject,
              style: TextStyle(
                color: BabkaColors.inkLight.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Positioned.fill(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 56,
                trackShape: _FullWidthTrackShape(),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 24, elevation: 4),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: BabkaColors.error.withValues(alpha: 0.1),
                inactiveTrackColor: Colors.transparent,
                thumbColor: BabkaColors.error,
              ),
              child: Slider(
                value: _sliderValue,
                onChanged: (v) {
                  setState(() {
                    _sliderValue = v;
                    if (v > 0.95) {
                      _sliderValue = 1.0;
                      _isUnlocked = true;
                    }
                  });
                },
                onChangeEnd: (v) {
                  if (v < 0.95) {
                    setState(() => _sliderValue = 0.0);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullWidthTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

