import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../core/design_system/babka_dimens.dart';

/// Babka Design System Hero Banner (v1.0.0)
class HeroBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback? onTap;

  const HeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BabkaDimens.radiusXL),
          boxShadow: BabkaDimens.shadowMedium,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BabkaDimens.radiusXL),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: BabkaColors.border),
                errorWidget: (context, url, error) => Container(color: BabkaColors.border),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.6], // More controlled gradient
                    colors: [
                      BabkaColors.ink.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(BabkaDimens.spacing24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end, // Align to bottom
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BabkaTypography.h2(context).copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: BabkaDimens.spacing4),
                    Text(
                      subtitle,
                      style: BabkaTypography.bodyMedium(context).copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

