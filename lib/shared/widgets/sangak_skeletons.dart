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
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SangakSkeleton(width: 220, height: 220, borderRadius: SangakDimens.radiusXL),
          Padding(
            padding: const EdgeInsets.all(SangakDimens.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SangakSkeleton(width: 120, height: 20),
                const SizedBox(height: 8),
                const SangakSkeleton(width: 180, height: 14),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SangakSkeleton(width: 60, height: 20),
                    SangakSkeleton(width: 80, height: 36, borderRadius: SangakDimens.radiusM),
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
