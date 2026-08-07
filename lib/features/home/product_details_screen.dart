import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../models/bread.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/freshness_badge.dart';
import '../../shared/widgets/quantity_selector.dart';
import '../../shared/widgets/product_tag.dart';
import '../../shared/utils/auth_gate.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/utils/action_guard.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../basket/basket_provider.dart';
import 'home_provider.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Bread bread;

  const ProductDetailsScreen({
    super.key,
    required this.bread,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _localQuantity = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final basket = ref.watch(basketProvider);
    final basketItem = basket.where((item) => item.bread.id == widget.bread.id).firstOrNull;
    final inBasketQuantity = basketItem?.quantity ?? 0;
    
    final isFavorite = ref.watch(isFavoriteProvider(widget.bread.id));
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;

    final displayName = widget.bread.localizedName(languageCode);
    final displayDescription = widget.bread.localizedDescription(languageCode);
    final formattedPrice = SangakNumberFormatter.formatCurrency(widget.bread.price, languageCode);

    return Scaffold(
      backgroundColor: SangakColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Image Area
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: SangakColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SangakColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isFavorite ? SangakColors.error : SangakColors.ink,
                    ),
                    onPressed: () {
                      if (!ActionGuard.check(context, ref)) return;
                      AuthGate.run(
                        context,
                        ref,
                        action: () => ref.read(favoritesProvider.notifier).toggle(widget.bread.id),
                        title: l10n.saveYourFavorites,
                        message: l10n.saveFavoritesMessage,
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'bread_${widget.bread.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.bread.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(SangakDimens.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: SangakDimens.spacing8,
                    runSpacing: SangakDimens.spacing8,
                    children: [
                      if (widget.bread.isOrganic)
                        ProductTag(label: l10n.organic, type: ProductTagType.organic),
                      if (widget.bread.tag != null)
                        ProductTag.fromText(widget.bread.tag!, context: context),
                      if (widget.bread.freshness != null)
                        FreshnessBadge(token: widget.bread.freshness!),
                    ],
                  ),
                  const SizedBox(height: SangakDimens.spacing12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          displayName, 
                          style: SangakTypography.h1(context).copyWith(fontSize: 24),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        formattedPrice, 
                        style: SangakTypography.h1(context).copyWith(
                          color: SangakColors.primary,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SangakDimens.spacing8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFB800), size: 20),
                      const SizedBox(width: 4),
                      Text(widget.bread.rating.toString(), style: SangakTypography.title(context).copyWith(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(l10n.reviewsCount(widget.bread.reviews), style: SangakTypography.bodySmall(context)),
                    ],
                  ),
                  const SizedBox(height: SangakDimens.spacing24),
                  Text(l10n.description, style: SangakTypography.title(context)),
                  const SizedBox(height: SangakDimens.spacing8),
                  Text(
                    displayDescription,
                    style: SangakTypography.bodyLarge(context).copyWith(color: SangakColors.inkLight),
                  ),
                  const SizedBox(height: SangakDimens.spacing32),
                  
                  // Nutrition / Details Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildInfoItem(Icons.timer_outlined, l10n.mins(widget.bread.prepTime)),
                        const SizedBox(width: 12),
                        _buildInfoItem(Icons.local_fire_department_outlined, l10n.kcal(widget.bread.calories)),
                        if (widget.bread.isOrganic) ...[
                          const SizedBox(width: 12),
                          _buildInfoItem(Icons.eco_outlined, l10n.organic),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 120), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(SangakDimens.spacing24),
        decoration: BoxDecoration(
          color: SangakColors.surface,
          boxShadow: SangakDimens.shadowHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(SangakDimens.radiusXL)),
        ),
        child: inBasketQuantity > 0
            ? Center(
                child: QuantitySelector(
                  quantity: inBasketQuantity,
                  compact: true,
                  onIncrement: () {
                    if (!ActionGuard.check(context, ref)) return;
                    ref.read(basketProvider.notifier).addItem(widget.bread);
                  },
                  onDecrement: () {
                    if (!ActionGuard.check(context, ref)) return;
                    ref.read(basketProvider.notifier).updateQuantity(widget.bread.id, -1);
                  },
                  onDelete: () {
                    if (!ActionGuard.check(context, ref)) return;
                    ref.read(basketProvider.notifier).removeItem(widget.bread.id);
                  },
                ),
              )
            : Row(
                children: [
                  QuantitySelector(
                    quantity: _localQuantity,
                    compact: true,
                    onIncrement: () => setState(() => _localQuantity++),
                    onDecrement: _localQuantity > 1 ? () => setState(() => _localQuantity--) : () {},
                  ),
                  const SizedBox(width: SangakDimens.spacing16),
                  Expanded(
                    child: SangakButton.primary(
                      label: l10n.addToBasket,
                      onPressed: () {
                        if (!ActionGuard.check(context, ref)) return;
                        AuthGate.run(
                          context,
                          ref,
                          action: () {
                            ref.read(basketProvider.notifier).addItem(widget.bread, quantity: _localQuantity);
                            SangakToast.show(context, l10n.addedToBasket(displayName));
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusM),
        border: Border.all(color: SangakColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SangakColors.primary),
          const SizedBox(width: 8),
          Text(label, style: SangakTypography.bodySmall(context).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
