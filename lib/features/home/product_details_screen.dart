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
import '../../shared/utils/auth_gate.dart';
import '../../shared/utils/sangak_toast.dart';
import '../cart/cart_provider.dart';
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
    final cart = ref.watch(cartProvider);
    final cartItem = cart.where((item) => item.bread.id == widget.bread.id).firstOrNull;
    final inCartQuantity = cartItem?.quantity ?? 0;
    
    final isFavorite = ref.watch(isFavoriteProvider(widget.bread.id));

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
                  if (widget.bread.isOrganic) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(SangakDimens.radiusPill),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.eco_rounded, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            l10n.organic.toUpperCase(),
                            style: SangakTypography.caption.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: SangakDimens.spacing12),
                  ],
                  if (widget.bread.tag != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: SangakColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(SangakDimens.radiusPill),
                        border: Border.all(color: SangakColors.accent.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        widget.bread.tag!.toUpperCase(),
                        style: SangakTypography.caption.copyWith(
                          color: SangakColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: SangakDimens.spacing12),
                  ],
                  if (widget.bread.freshness != null) ...[
                    FreshnessBadge(token: widget.bread.freshness!),
                    const SizedBox(height: SangakDimens.spacing12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(widget.bread.name, style: SangakTypography.h1),
                      ),
                      Text('₺${widget.bread.price.toStringAsFixed(0)}', style: SangakTypography.h1.copyWith(color: SangakColors.primary)),
                    ],
                  ),
                  const SizedBox(height: SangakDimens.spacing8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFB800), size: 20),
                      const SizedBox(width: 4),
                      Text(widget.bread.rating.toString(), style: SangakTypography.title.copyWith(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(l10n.reviewsCount(widget.bread.reviews), style: SangakTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(height: SangakDimens.spacing24),
                  Text(l10n.description, style: SangakTypography.title),
                  const SizedBox(height: SangakDimens.spacing8),
                  Text(
                    widget.bread.description,
                    style: SangakTypography.bodyLarge.copyWith(color: SangakColors.inkLight),
                  ),
                  const SizedBox(height: SangakDimens.spacing32),
                  
                  // Nutrition / Details Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(Icons.timer_outlined, l10n.mins(widget.bread.prepTime)),
                      _buildInfoItem(Icons.local_fire_department_outlined, l10n.kcal(widget.bread.calories)),
                      if (widget.bread.isOrganic) _buildInfoItem(Icons.eco_outlined, l10n.organic),
                    ],
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
        child: Row(
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: SangakColors.background,
                borderRadius: BorderRadius.circular(SangakDimens.radiusM),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _localQuantity > 1 ? () => setState(() => _localQuantity--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$_localQuantity',
                      style: SangakTypography.title,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _localQuantity++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SangakDimens.spacing16),
            Expanded(
              child: SangakButton.primary(
                label: inCartQuantity > 0 ? 'Update Basket' : l10n.addToBasket,
                onPressed: () {
                  AuthGate.run(
                    context,
                    ref,
                    action: () {
                      if (inCartQuantity > 0) {
                        ref.read(cartProvider.notifier).updateQuantity(widget.bread.id, _localQuantity - inCartQuantity);
                      } else {
                        ref.read(cartProvider.notifier).addItem(widget.bread, quantity: _localQuantity);
                      }
                      SangakToast.show(context, l10n.addedToBasket(widget.bread.name));
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
          Text(label, style: SangakTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
