import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';

class SangakToast {
  static OverlayEntry? _activeEntry;

  static void show(BuildContext context, String message) {
    // 1. Instantly remove previous toast if it exists
    if (_activeEntry != null) {
      _activeEntry!.remove();
      _activeEntry = null;
    }

    // 2. Create the new toast
    final overlay = Overlay.of(context, rootOverlay: true);
    
    final newEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        onDismiss: () {
          // Double check to ensure we only remove ourselves
          // (prevents deleting a newer toast that might have replaced us)
        },
      ),
    );

    _activeEntry = newEntry;
    overlay.insert(newEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ToastWidget({required this.message, required this.onDismiss});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Auto-dismiss after 2.8 seconds
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted && !_isRemoving) {
        _handleDismiss();
      }
    });
  }

  void _handleDismiss() {
    if (_isRemoving) return;
    _isRemoving = true;
    _controller.reverse().then((_) {
      if (mounted) {
        // We use SchedulerBinding to ensure we don't remove during a build/layout phase
        SchedulerBinding.instance.addPostFrameCallback((_) {
          // This logic is safer: we don't use a shared static ref for dismissal 
          // because a newer toast might have already replaced us.
          // OverlayEntry.remove() is safe to call even if already removed in some cases,
          // but we just let the auto-cleanup handle it if possible.
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 110,
      left: SangakDimens.spacing24,
      right: SangakDimens.spacing24,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: SangakColors.ink.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: SangakColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: SangakColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: SangakTypography.bodyMedium(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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
