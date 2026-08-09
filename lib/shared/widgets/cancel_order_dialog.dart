import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../l10n/app_localizations.dart';

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

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: SangakColors.error),
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
                'Slide to unlock cancellation input.', // TODO l10n
                style: SangakTypography.bodyMedium(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildSlider(context, l10n),
            ] else ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      l10n.cancellationReason,
                      style: SangakTypography.title(context).copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Enter reason here...', // TODO l10n
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: SangakColors.error),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                    ),
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
          child: Text(l10n.cancel, style: const TextStyle(color: SangakColors.inkLight)),
        ),
        if (_isUnlocked)
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);
                widget.onConfirm(_reasonController.text);
              }
            },
            style: TextButton.styleFrom(foregroundColor: SangakColors.error),
            child: Text(l10n.confirmButton),
          ),
      ],
    );
  }

  Widget _buildSlider(BuildContext context, AppLocalizations l10n) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: SangakColors.background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SangakColors.border),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              l10n.slidetoReject, // Reusing existing slide text
              style: TextStyle(
                color: SangakColors.inkLight.withValues(alpha: 0.6),
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
                activeTrackColor: SangakColors.error.withValues(alpha: 0.1),
                inactiveTrackColor: Colors.transparent,
                thumbColor: SangakColors.error,
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
