import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../features/home/widgets/exit_prompt.dart';

class SangakBackHandler extends ConsumerStatefulWidget {
  final Widget child;
  final bool forceDoubleTap;

  const SangakBackHandler({
    super.key,
    required this.child,
    this.forceDoubleTap = true,
  });

  @override
  ConsumerState<SangakBackHandler> createState() => _SangakBackHandlerState();
}

class _SangakBackHandlerState extends ConsumerState<SangakBackHandler> {
  DateTime? _lastPressedAt;
  bool _showExitPrompt = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // We only want to intercept if there's nothing to pop in the local navigator
    // AND it's a top-level route (which we assume if forceDoubleTap is true)
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. Check if we can actually go back in the current navigator
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }

        // 2. Double-tap check for exit
        if (!widget.forceDoubleTap) {
          SystemNavigator.pop();
          return;
        }

        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrHasTimedOut =
            _lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrHasTimedOut) {
          _lastPressedAt = now;
          
          setState(() => _showExitPrompt = true);
          
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showExitPrompt = false);
          });
          return;
        }

        SystemNavigator.pop();
      },
      child: Stack(
        children: [
          widget.child,
          ExitPrompt(
            visible: _showExitPrompt,
            message: l10n.appName == 'Sangak' ? 'Tap back again to exit' : 'برای خروج دوباره دکمه بازگشت را بزنید',
          ),
        ],
      ),
    );
  }
}
