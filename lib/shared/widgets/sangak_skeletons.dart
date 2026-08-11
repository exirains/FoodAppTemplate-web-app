import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_dimens.dart';

/// Sangak Design System Skeletons (v1.0.0)
class SangakSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SangakSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = SangakDimens.radiusM,
  });

  @override
  State<SangakSkeleton> createState() => _SangakSkeletonState();
}

class _SangakSkeletonState extends State<SangakSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: SangakColors.border,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  final double width;
  final double imageAspectRatio;

  const ProductCardSkeleton({
    super.key,
    this.width = 190,
    this.imageAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowLow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: imageAspectRatio,
            child: SangakSkeleton(
              width: width,
              height: width / imageAspectRatio,
              borderRadius: SangakDimens.radiusXL,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SangakSkeleton(width: 100, height: 16),
                const SizedBox(height: 6),
                const SangakSkeleton(width: 150, height: 10),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SangakSkeleton(width: 50, height: 18),
                    SangakSkeleton(width: 70, height: 32, borderRadius: SangakDimens.radiusM),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
