import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/custom_sangak_provider.dart';
import '../../../models/bread.dart';
import '../../../core/design_system/sangak_dimens.dart';
import '../../../core/design_system/sangak_colors.dart';

import '../data/sangak_customization_options.dart';

class SangakPreview extends ConsumerWidget {
  final Bread baseBread;

  const SangakPreview({
    super.key,
    required this.baseBread,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layersMap = ref.watch(sangakLayersProvider(baseBread));

    return Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        color: SangakColors.background,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        boxShadow: [
          BoxShadow(
            color: SangakColors.ink.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            _AnimatedLayer(path: layersMap['base']),
            for (final option in sangakCustomizationOptions)
              _AnimatedLayer(path: layersMap[option.id]),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLayer extends StatelessWidget {
  final String? path;

  const _AnimatedLayer({this.path});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: path != null
          ? Image.asset(
              path!,
              key: ValueKey(path),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
}
