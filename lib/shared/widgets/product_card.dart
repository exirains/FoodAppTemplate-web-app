import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/design_system/sangak_tokens.dart';
import 'freshness_badge.dart';
import 'quantity_selector.dart';

/// Sangak Design System Signature Product Card (v1.0.0)
///
/// Immutable rules: Fixed image ratio, consistent padding, photography-first.
class ProductCard extends StatefulWidget {
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final FreshnessToken? freshness;
  final bool isFavorite;
  final int quantity;
  final VoidCallback onAddToCart;
  final VoidCallback onFavoriteToggle;

  const ProductCard({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.freshness,
    this.isFavorite = false,
    this.quantity = 0,
    required this.onAddToCart,
    required this.onFavoriteToggle,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
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
                  aspectRatio: 1, // Strict square ratio for consistency
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: SangakColors.border,
                      child: const Icon(Icons.bakery_dining_outlined, size: 48, color: SangakColors.inkLight),
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
                  widget.title,
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
                    AnimatedSwitcher(
                      duration: SangakTokens.animMedium,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: widget.quantity > 0
                          ? QuantitySelector(
                              key: const ValueKey('quantity'),
                              quantity: widget.quantity,
                              onIncrement: widget.onAddToCart,
                              onDecrement: widget.onAddToCart, // Placeholder for decrement
                            )
                          : ElevatedButton(
                              key: const ValueKey('add'),
                              onPressed: widget.onAddToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SangakColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(SangakDimens.radiusM),
                                ),
                              ),
                              child: const Text('Add'),
                            ),
                    ),
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
