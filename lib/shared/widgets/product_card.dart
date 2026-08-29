import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/design_system/sangak_tokens.dart';
import '../../models/bread.dart';
import '../../core/localization/locale_provider.dart';
import '../../features/basket/basket_provider.dart';
import '../../features/home/home_provider.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../utils/action_guard.dart';
import 'freshness_badge.dart';
import 'quantity_selector.dart';
import 'sangak_dialogs.dart';
import 'product_tag.dart';

/// Sangak Design System Signature Product Card (v1.1.0)
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
  final double imageAspectRatio;
  final bool compact;

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
    this.imageAspectRatio = 1.1,
    this.compact = false,
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
      duration: BabkaTokens.animFast,
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
    final formattedPrice = BabkaNumberFormatter.formatCurrency(widget.price, languageCode);
    
    final bool isAvailable = widget.bread?.available ?? true;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: isAvailable ? (_) => _controller.forward() : null,
      onTapUp: isAvailable ? (_) => _controller.reverse() : null,
      onTapCancel: isAvailable ? () => _controller.reverse() : null,
      onTap: (widget.bread != null && isAvailable) ? () => context.push('/product-details', extra: widget.bread) : null,
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.6,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: BabkaColors.surface,
              borderRadius: BorderRadius.circular(BabkaDimens.radiusXL),
              boxShadow: BabkaDimens.shadowMedium,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Fix vertical overflow
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(BabkaDimens.radiusXL)),
                      child: ColorFiltered(
                        colorFilter: isAvailable 
                            ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                            : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                        child: AspectRatio(
                          aspectRatio: widget.imageAspectRatio,
                          child: CachedNetworkImage(
                            imageUrl: widget.imageUrl,
                            fit: BoxFit.cover,
                            memCacheHeight: 400,
                            placeholder: (context, url) => Container(
                              color: BabkaColors.border,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: BabkaColors.border,
                              child: const Icon(Icons.breakfast_dining_outlined, size: 48, color: BabkaColors.inkLight),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isAvailable)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(BabkaDimens.radiusXL)),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: BabkaColors.ink.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
                                boxShadow: BabkaDimens.shadowLow,
                              ),
                              child: Text(
                                l10n.outOfStock.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.bread?.tag != null)
                      Positioned(
                        top: BabkaDimens.spacing12,
                        left: BabkaDimens.spacing12,
                        child: ProductTag.fromText(widget.bread!.tag!, context: context),
                      ),
                    Positioned(
                      top: BabkaDimens.spacing8,
                      right: BabkaDimens.spacing8,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque, // FIX: Ensure entire circle is clickable
                        onTap: () {
                          if (!ActionGuard.check(context, ref)) return;
                          widget.onFavoriteToggle();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedSwitcher(
                            duration: BabkaTokens.animMedium,
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey(isFavorite),
                              size: 18,
                              color: isFavorite ? BabkaColors.error : BabkaColors.inkLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.freshness != null)
                      Positioned(
                        bottom: BabkaDimens.spacing8,
                        left: BabkaDimens.spacing8,
                        child: FreshnessBadge(token: widget.freshness!),
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, widget.compact ? 6 : 8, 12, widget.compact ? 8 : 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 18,
                        child: Text(
                          displayName,
                          style: BabkaTypography.title(context).copyWith(
                            fontSize: 14,
                            color: isAvailable ? BabkaColors.ink : BabkaColors.inkLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: widget.compact ? 0 : 14, // Hide description in super compact mode if needed
                        child: widget.compact ? null : Text(
                          displayDescription,
                          style: BabkaTypography.bodySmall(context).copyWith(
                            fontSize: 10,
                            height: 1.1,
                            color: BabkaColors.inkLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: widget.compact ? 4 : 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  alignment: Alignment.centerLeft,
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    formattedPrice,
                                    style: BabkaTypography.price(context).copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isAvailable ? BabkaColors.primary : BabkaColors.inkLight,
                                    ),
                                  ),
                                ),
                                if (widget.bread != null && widget.bread!.reviews > 0) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${BabkaNumberFormatter.format(widget.bread!.rating, languageCode)} (${BabkaNumberFormatter.format(widget.bread!.reviews, languageCode)})',
                                        style: BabkaTypography.caption(context).copyWith(
                                          fontSize: 10,
                                          color: BabkaColors.inkLight,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: BabkaTokens.animMedium,
                            child: quantity > 0
                                ? QuantitySelector(
                                    key: const ValueKey('quantity'),
                                    quantity: quantity,
                                    compact: true,
                                    onIncrement: isAvailable ? () {
                                      if (!ActionGuard.check(context, ref)) return;
                                      ref.read(basketProvider.notifier).addItem(widget.bread!);
                                    } : () {},
                                    onDecrement: () {
                                      if (!ActionGuard.check(context, ref)) return;
                                      ref.read(basketProvider.notifier).updateQuantity(widget.bread!.id, -1);
                                    },
                                    onDelete: () {
                                      if (!ActionGuard.check(context, ref)) return;
                                      BabkaConfirmDialog.show(
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
                                : SizedBox(
                                    height: 34,
                                    child: ElevatedButton(
                                      key: const ValueKey('add'),
                                      onPressed: isAvailable ? () {
                                        if (!ActionGuard.check(context, ref)) return;
                                        widget.onAddToBasket();
                                      } : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isAvailable ? BabkaColors.primary : BabkaColors.border,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
                                        ),
                                      ),
                                      child: Text(l10n.add, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
