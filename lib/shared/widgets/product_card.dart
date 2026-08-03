import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/design_system/sangak_tokens.dart';
import '../../models/bread.dart';
import '../../core/localization/locale_provider.dart';
import '../../features/basket/basket_provider.dart';
import '../../features/home/home_provider.dart';
import '../../core/localization/sangak_number_formatter.dart';
import 'freshness_badge.dart';
import 'quantity_selector.dart';
import 'sangak_dialogs.dart';
import 'product_tag.dart';

/// Sangak Design System Signature Product Card (v1.0.0)
class ProductCard extends ConsumerStatefulWidget {
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final FreshnessToken? freshness;
  final bool isFavorite;
  final VoidCallback onAddToBasket;
  final VoidCallback onFavoriteToggle;
  final Bread? bread;
  final double? width;

  const ProductCard({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.freshness,
    this.isFavorite = false,
    required this.onAddToBasket,
    required this.onFavoriteToggle,
    this.bread,
    this.width,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SangakTokens.animFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basket = ref.watch(basketProvider);
    final l10n = AppLocalizations.of(context);
    final basketItem = basket.where((item) => item.bread.id == widget.bread?.id).firstOrNull;
    final int quantity = basketItem?.quantity ?? 0;
    
    final isFavorite = ref.watch(isFavoriteProvider(widget.bread?.id ?? ''));
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;

    final displayName = widget.bread?.localizedName(languageCode) ?? widget.name;
    final displayDescription = widget.bread?.localizedDescription(languageCode) ?? widget.description;
    final formattedPrice = SangakNumberFormatter.formatCurrency(widget.price, languageCode);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.bread != null ? () => context.push('/product-details', extra: widget.bread) : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width, // Use configurable width
          decoration: BoxDecoration(
            color: SangakColors.surface,
            borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
            boxShadow: SangakDimens.shadowMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photography-first section
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(SangakDimens.radiusXL)),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        memCacheHeight: 400, // Image performance improvement
                        placeholder: (context, url) => Container(
                          color: SangakColors.border,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: SangakColors.border,
                          child: const Icon(Icons.breakfast_dining_outlined, size: 48, color: SangakColors.inkLight),
                        ),
                      ),
                    ),
                  ),
                  // Tag Badge (Top Left)
                  if (widget.bread?.tag != null)
                    Positioned(
                      top: SangakDimens.spacing12,
                      left: SangakDimens.spacing12,
                      child: ProductTag.fromText(widget.bread!.tag!),
                    ),
                  // Favorite Button
                  Positioned(
                    top: SangakDimens.spacing12,
                    right: SangakDimens.spacing12,
                    child: GestureDetector(
                      onTap: widget.onFavoriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedSwitcher(
                          duration: SangakTokens.animMedium,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(isFavorite),
                            size: 20,
                            color: isFavorite ? SangakColors.error : SangakColors.inkLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Freshness Badge
                  if (widget.freshness != null)
                    Positioned(
                      bottom: SangakDimens.spacing12,
                      left: SangakDimens.spacing12,
                      child: FreshnessBadge(token: widget.freshness!),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SangakDimens.spacing12,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 20, // Increased from 18 to give more room
                      child: Text(
                        displayName,
                        style: SangakTypography.title(context).copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4), // Increased from 2 to reduce "smushed" look
                    SizedBox(
                      height: 30, // Increased from 28 to give more room
                      child: Text(
                        displayDescription,
                        style: SangakTypography.bodySmall(context).copyWith(
                          fontSize: 10,
                          height: 1.1,
                          color: SangakColors.inkLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10), // Increased from 8
                    SizedBox(
                      height: 36,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedPrice,
                            style: SangakTypography.price(context).copyWith(fontSize: 17),
                          ),
                          // Add to Basket / Quantity Morph
                          SizedBox(
                            height: 36, // Strict height to avoid jump
                            child: AnimatedSwitcher(
                              duration: SangakTokens.animMedium,
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  alignment: Alignment.centerRight,
                                  children: <Widget>[
                                    ...previousChildren,
                                    currentChild ?? const SizedBox.shrink(),
                                  ],
                                );
                              },
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(scale: animation, child: child),
                                );
                              },
                              child: quantity > 0
                                  ? QuantitySelector(
                                      key: const ValueKey('quantity'),
                                      quantity: quantity,
                                      onIncrement: () => ref.read(basketProvider.notifier).addItem(widget.bread!),
                                      onDecrement: () => ref.read(basketProvider.notifier).updateQuantity(widget.bread!.id, -1),
                                      onDelete: () {
                                        SangakConfirmDialog.show(
                                          context,
                                          title: l10n.remove,
                                          message: l10n.removeItemFromBasket,
                                          confirmLabel: l10n.remove,
                                          cancelLabel: l10n.cancel,
                                          onConfirm: () => ref.read(basketProvider.notifier).removeItem(widget.bread!.id),
                                          isDestructive: true,
                                        );
                                      },
                                    )
                                  : ElevatedButton(
                                      key: const ValueKey('add'),
                                      onPressed: widget.onAddToBasket,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: SangakColors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        minimumSize: const Size(80, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(SangakDimens.radiusM),
                                        ),
                                      ),
                                      child: Text(l10n.add),
                                    ),
                            ),
                          ),
                        ],
                      ),
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
