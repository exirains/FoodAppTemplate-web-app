import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_empty_states.dart';
import '../../shared/widgets/quantity_selector.dart';
import '../home/tab_provider.dart';
import 'cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final l10n = AppLocalizations.of(context);

    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: SangakColors.background,
        appBar: AppBar(title: Text(l10n.cart)),
        body: SangakEmptyState(
          title: l10n.yourBasketIsWaiting,
          message: l10n.cartGuestMessage,
          icon: Icons.shopping_basket_outlined,
          actionLabel: l10n.explore,
          onAction: () => ref.read(tabProvider.notifier).state = 0,
        ),
      );
    }

    return Scaffold(
      backgroundColor: SangakColors.background,
      appBar: AppBar(
        title: Text(l10n.cart),
        actions: [
          IconButton(
            onPressed: () => ref.read(cartProvider.notifier).clear(),
            icon: const Icon(Icons.delete_outline, color: SangakColors.error),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(SangakDimens.spacing24),
              itemCount: cart.length,
              separatorBuilder: (_, __) => const SizedBox(height: SangakDimens.spacing16),
              itemBuilder: (context, index) {
                final item = cart[index];
                return Container(
                  padding: const EdgeInsets.all(SangakDimens.spacing12),
                  decoration: BoxDecoration(
                    color: SangakColors.surface,
                    borderRadius: BorderRadius.circular(SangakDimens.radiusL),
                    boxShadow: SangakDimens.shadowLow,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(SangakDimens.radiusM),
                        child: Image.network(
                          item.bread.imageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: SangakDimens.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.bread.title, style: SangakTypography.title),
                            const SizedBox(height: 4),
                            Text('₺${item.bread.price.toStringAsFixed(0)}', style: SangakTypography.price.copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                      QuantitySelector(
                        quantity: item.quantity,
                        onIncrement: () => ref.read(cartProvider.notifier).updateQuantity(item.bread.id, 1),
                        onDecrement: () {
                          if (item.quantity == 1) {
                            ref.read(cartProvider.notifier).removeItem(item.bread.id);
                          } else {
                            ref.read(cartProvider.notifier).updateQuantity(item.bread.id, -1);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildSummary(context, total, l10n),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, double total, AppLocalizations l10n) {
    const deliveryFee = 15.0;
    final grandTotal = total + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(SangakDimens.spacing24),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(SangakDimens.radiusXL)),
        boxShadow: SangakDimens.shadowHigh,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: SangakTypography.bodyMedium),
              Text('₺${total.toStringAsFixed(0)}', style: SangakTypography.title),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: SangakTypography.bodyMedium),
              Text('₺${deliveryFee.toStringAsFixed(0)}', style: SangakTypography.title),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: SangakTypography.h3),
              Text('₺${grandTotal.toStringAsFixed(0)}', style: SangakTypography.h2.copyWith(color: SangakColors.primary)),
            ],
          ),
          const SizedBox(height: SangakDimens.spacing24),
          SangakButton.primary(
            label: 'Proceed to Checkout',
            width: double.infinity,
            onPressed: () => context.push('/checkout'),
          ),
        ],
      ),
    );
  }
}
