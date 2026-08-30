import 'package:flutter/material.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_dimens.dart';

/// Babka Design System Skeletons (v1.0.0)
class BabkaSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const BabkaSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = BabkaDimens.radiusM,
  });

  @override
  State<BabkaSkeleton> createState() => _BabkaSkeletonState();
}

class _BabkaSkeletonState extends State<BabkaSkeleton>
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
          color: BabkaColors.border,
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
        color: BabkaColors.surface,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusXL),
        boxShadow: BabkaDimens.shadowLow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: imageAspectRatio,
            child: BabkaSkeleton(
              width: width,
              height: width / imageAspectRatio,
              borderRadius: BabkaDimens.radiusXL,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const BabkaSkeleton(width: 100, height: 16),
                const SizedBox(height: 6),
                const BabkaSkeleton(width: 150, height: 10),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    BabkaSkeleton(width: 50, height: 18),
                    BabkaSkeleton(width: 70, height: 32, borderRadius: BabkaDimens.radiusM),
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


