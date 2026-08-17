import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/promotions_repository.dart';
import '../../../core/design_system/sangak_colors.dart';
import '../../../core/design_system/sangak_dimens.dart';
import '../../../core/design_system/sangak_typography.dart';

class PromotionBanners extends ConsumerWidget {
  const PromotionBanners({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = ref.watch(activePromotionsProvider);

    return promotionsAsync.when(
      data: (promotions) {
        if (promotions.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 160,
          child: PageView.builder(
            itemCount: promotions.length,
            controller: PageController(viewportFraction: 0.9),
            itemBuilder: (context, index) {
              final promo = promotions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
                    image: promo.imageUrl != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(promo.imageUrl!),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
                          )
                        : null,
                    color: SangakColors.ink,
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              promo.title,
                              style: SangakTypography.h3(context).copyWith(color: Colors.white),
                            ),
                            if (promo.description != null)
                              Text(
                                promo.description!,
                                style: SangakTypography.bodySmall(context).copyWith(color: Colors.white70),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: SangakColors.border.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
