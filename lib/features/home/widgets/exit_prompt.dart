import 'package:flutter/material.dart';
import '../../../core/design_system/babka_colors.dart';
import '../../../core/design_system/babka_typography.dart';
import '../../../core/design_system/babka_dimens.dart';

class ExitPrompt extends StatefulWidget {
  final bool visible;
  final String message;
  const ExitPrompt({super.key, required this.visible, required this.message});

  @override
  State<ExitPrompt> createState() => _ExitPromptState();
}

class _ExitPromptState extends State<ExitPrompt> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  @override
  void didUpdateWidget(ExitPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _controller.forward();
    } else if (!widget.visible && oldWidget.visible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_scaleAnimation.value * 0.2),
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: BabkaColors.ink.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: BabkaColors.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.exit_to_app_rounded, color: BabkaColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          widget.message,
                          style: BabkaTypography.title(context).copyWith(
                            color: Colors.white,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

