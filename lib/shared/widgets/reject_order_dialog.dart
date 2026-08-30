import 'package:flutter/material.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../l10n/app_localizations.dart';

class RejectOrderDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  
  const RejectOrderDialog({super.key, required this.onConfirm});

  static Future<void> show(BuildContext context, {required VoidCallback onConfirm}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RejectOrderDialog(onConfirm: onConfirm),
    );
  }

  @override
  State<RejectOrderDialog> createState() => _RejectOrderDialogState();
}

class _RejectOrderDialogState extends State<RejectOrderDialog> {
  double _sliderValue = 0.0;
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: BabkaColors.error),
          const SizedBox(width: 12),
          Text(l10n.rejectOrder),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.confirmRejectMessage,
            style: BabkaTypography.bodyMedium(context),
          ),
          const SizedBox(height: 32),
          // SLIDE TO REJECT MECHANISM
          Container(
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              color: BabkaColors.background,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: BabkaColors.border),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    _isConfirmed ? l10n.rejected : l10n.slidetoReject,
                    style: TextStyle(
                      color: _isConfirmed ? BabkaColors.error : BabkaColors.inkLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 64,
                      trackShape: _FullWidthTrackShape(),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 28, elevation: 4),
                      overlayShape: SliderComponentShape.noOverlay,
                      activeTrackColor: BabkaColors.error.withValues(alpha: 0.2),
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: BabkaColors.error,
                    ),
                    child: Slider(
                      value: _sliderValue,
                      onChanged: _isConfirmed ? null : (v) {
                        setState(() {
                          _sliderValue = v;
                          if (v > 0.9) {
                            _sliderValue = 1.0;
                            _isConfirmed = true;
                            
                            // Capture navigator before async gap to avoid warning
                            final navigator = Navigator.of(context);
                            
                            // Execute confirmation after brief delay
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) {
                                navigator.pop();
                                widget.onConfirm();
                              }
                            });
                          }
                        });
                      },
                      onChangeEnd: (v) {
                        if (v < 0.9) {
                          setState(() => _sliderValue = 0.0);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
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

