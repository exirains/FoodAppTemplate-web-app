import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:babka/l10n/app_localizations.dart';
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
import '../../services/options_repository.dart';
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
    final basketItem = basket.where((item) => item.bread.id == widget.bread.id && item.customization == null).firstOrNull;
    final inBasketQuantity = basketItem?.quantity ?? 0;
    
    final isFavorite = ref.watch(isFavoriteProvider(widget.bread.id));
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;

    final displayName = widget.bread.localizedName(languageCode);
    final displayDescription = widget.bread.localizedDescription(languageCode);
    final formattedPrice = BabkaNumberFormatter.formatCurrency(widget.bread.price, languageCode);
    
    final optionsAsync = ref.watch(appOptionsProvider);
    final isCustomSangakEnabled = optionsAsync.value?['custom_sangak_enabled'] == true || 
                                 optionsAsync.value?['custom_sangak_enabled'] == 'true';

    return Scaffold(
      backgroundColor: BabkaColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Image Area
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: BabkaColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: BabkaColors.ink),
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
                      color: isFavorite ? BabkaColors.error : BabkaColors.ink,
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
              padding: const EdgeInsets.all(BabkaDimens.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: BabkaDimens.spacing8,
                    runSpacing: BabkaDimens.spacing8,
                    children: [
                      if (widget.bread.isOrganic)
                        ProductTag(label: l10n.organic, type: ProductTagType.organic),
                      if (widget.bread.tag != null)
                        ProductTag.fromText(widget.bread.tag!, context: context),
                      if (widget.bread.freshness != null)
                        FreshnessBadge(token: widget.bread.freshness!),
                    ],
                  ),
                  const SizedBox(height: BabkaDimens.spacing12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          displayName, 
                          style: BabkaTypography.h1(context).copyWith(fontSize: 24),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        formattedPrice, 
                        style: BabkaTypography.h1(context).copyWith(
                          color: BabkaColors.primary,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BabkaDimens.spacing8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFB800), size: 20),
                      const SizedBox(width: 4),
                      Text(widget.bread.rating.toString(), style: BabkaTypography.title(context).copyWith(fontSize: 14)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: BabkaColors.ink.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
                          border: Border.all(color: BabkaColors.border),
                        ),
                        child: Text(
                          l10n.reviewsCount(widget.bread.reviews),
                          style: BabkaTypography.bodySmall(context).copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: BabkaColors.inkLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BabkaDimens.spacing24),
                  Text(l10n.description, style: BabkaTypography.title(context)),
                  const SizedBox(height: BabkaDimens.spacing8),
                  Text(
                    displayDescription,
                    style: BabkaTypography.bodyLarge(context).copyWith(color: BabkaColors.inkLight),
                  ),
                  const SizedBox(height: BabkaDimens.spacing32),
                  
                  if (isCustomSangakEnabled && widget.bread.name.toLowerCase().contains('sangak'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: BabkaDimens.spacing16),
                      child: BabkaButton.outlined(
                        label: l10n.customizeYourSangak,
                        icon: Icons.auto_awesome_outlined,
                        onPressed: () => context.push('/custom-sangak', extra: widget.bread),
                      ),
                    ),

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
        padding: const EdgeInsets.all(BabkaDimens.spacing24),
        decoration: BoxDecoration(
          color: BabkaColors.surface,
          boxShadow: BabkaDimens.shadowHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(BabkaDimens.radiusXL)),
        ),
        child: inBasketQuantity > 0
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QuantitySelector(
                    quantity: inBasketQuantity,
                    compact: true,
                    onIncrement: () {
                      if (!ActionGuard.check(context, ref)) return;
                      ref.read(basketProvider.notifier).addItem(widget.bread);
                    },
                    onDecrement: () {
                      if (!ActionGuard.check(context, ref)) return;
                      if (basketItem != null) {
                        ref.read(basketProvider.notifier).updateQuantity(basketItem.basketId, -1);
                      }
                    },
                    onDelete: () {
                      if (!ActionGuard.check(context, ref)) return;
                      if (basketItem != null) {
                        ref.read(basketProvider.notifier).removeItem(basketItem.basketId);
                      }
                    },
                  ),
                ],
              )
            : Row(
                children: [
                  QuantitySelector(
                    quantity: _localQuantity,
                    compact: true,
                    onIncrement: () => setState(() => _localQuantity++),
                    onDecrement: _localQuantity > 1 ? () => setState(() => _localQuantity--) : () {},
                  ),
                  const SizedBox(width: BabkaDimens.spacing16),
                  Expanded(
                    child: BabkaButton.primary(
                      label: l10n.addToBasket,
                      onPressed: () {
                        if (!ActionGuard.check(context, ref)) return;
                        AuthGate.run(
                          context,
                          ref,
                          action: () {
                            ref.read(basketProvider.notifier).addItem(widget.bread, quantity: _localQuantity);
                            BabkaToast.show(context, l10n.addedToBasket(displayName));
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
        color: BabkaColors.surface,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
        border: Border.all(color: BabkaColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: BabkaColors.primary),
          const SizedBox(width: 8),
          Text(label, style: BabkaTypography.bodySmall(context).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
