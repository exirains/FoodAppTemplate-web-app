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
import '../../features/cart/cart_provider.dart';
import 'freshness_badge.dart';
import 'quantity_selector.dart';
import 'sangak_dialogs.dart';

/// Sangak Design System Signature Product Card (v1.0.0)
class ProductCard extends ConsumerStatefulWidget {
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final FreshnessToken? freshness;
  final bool isFavorite;
  final VoidCallback onAddToCart;
  final VoidCallback onFavoriteToggle;
  final Bread? bread;

  const ProductCard({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.freshness,
    this.isFavorite = false,
    required this.onAddToCart,
    required this.onFavoriteToggle,
    this.bread,
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
    final cart = ref.watch(cartProvider);
    final cartItem = cart.where((item) => item.bread.id == widget.bread?.id).firstOrNull;
    final int quantity = cartItem?.quantity ?? 0;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.bread != null ? () => context.push('/product-details', extra: widget.bread) : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: SangakColors.accent.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(SangakDimens.radiusPill),
                          boxShadow: SangakDimens.shadowLow,
                        ),
                        child: Text(
                          widget.bread!.tag!.toUpperCase(),
                          style: SangakTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            fontSize: 10,
                          ),
                        ),
                      ),
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
                            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(widget.isFavorite),
                            size: 20,
                            color: widget.isFavorite ? SangakColors.error : SangakColors.inkLight,
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
                padding: const EdgeInsets.all(SangakDimens.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: SangakTypography.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SangakDimens.spacing4),
                    Text(
                      widget.description,
                      style: SangakTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SangakDimens.spacing16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₺${widget.price.toStringAsFixed(0)}',
                          style: SangakTypography.price,
                        ),
                        // Add to Cart / Quantity Morph
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
                                    onIncrement: () => ref.read(cartProvider.notifier).addItem(widget.bread!),
                                    onDecrement: () => ref.read(cartProvider.notifier).updateQuantity(widget.bread!.id, -1),
                                    onDelete: () {
                                      SangakConfirmDialog.show(
                                        context,
                                        title: 'Remove item',
                                        message: 'Are you sure you want to remove this item from your basket?',
                                        confirmLabel: 'Remove',
                                        cancelLabel: 'Cancel',
                                        onConfirm: () => ref.read(cartProvider.notifier).removeItem(widget.bread!.id),
                                        isDestructive: true,
                                      );
                                    },
                                  )
                                : ElevatedButton(
                                    key: const ValueKey('add'),
                                    onPressed: widget.onAddToCart,
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
                                    child: Text(AppLocalizations.of(context).add),
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
    );
  }
}
