import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_empty_states.dart';
import '../../shared/widgets/sangak_dialogs.dart';
import '../../shared/widgets/quantity_selector.dart';
import '../home/tab_provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/sangak_number_formatter.dart';
import 'basket_provider.dart';
import '../auth/auth_provider.dart';

class BasketScreen extends ConsumerWidget {
  const BasketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basket = ref.watch(basketProvider);
    final total = ref.watch(basketTotalProvider);
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;

    if (basket.isEmpty) {
      return Scaffold(
        backgroundColor: SangakColors.background,
        appBar: AppBar(title: Text(l10n.basket)),
        body: SangakEmptyState(
          title: l10n.yourBasketIsWaiting,
          message: l10n.basketGuestMessage,
          icon: Icons.shopping_basket_outlined,
          actionLabel: l10n.explore,
          onAction: () => ref.read(tabProvider.notifier).state = 0,
        ),
      );
    }

    return Scaffold(
      backgroundColor: SangakColors.background,
      appBar: AppBar(
        title: Text(l10n.basket),
        actions: [
          IconButton(
            onPressed: () => ref.read(basketProvider.notifier).clear(),
            icon: const Icon(Icons.delete_outline, color: SangakColors.error),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(SangakDimens.spacing24),
              itemCount: basket.length,
              separatorBuilder: (context, index) => const SizedBox(height: SangakDimens.spacing16),
              itemBuilder: (context, index) {
                final item = basket[index];
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
                        child: CachedNetworkImage(
                          imageUrl: item.bread.imageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 70,
                            height: 70,
                            color: SangakColors.border,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 70,
                            height: 70,
                            color: SangakColors.border,
                            child: const Icon(Icons.broken_image_outlined, color: SangakColors.inkLight),
                          ),
                        ),
                      ),
                      const SizedBox(width: SangakDimens.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.bread.localizedName(lang), style: SangakTypography.title(context)),
                            const SizedBox(height: 4),
                            Text(
                              SangakNumberFormatter.formatCurrency(item.bread.price, lang),
                              style: SangakTypography.price(context).copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      QuantitySelector(
                        quantity: item.quantity,
                        onIncrement: () => ref.read(basketProvider.notifier).updateQuantity(item.bread.id, 1),
                        onDecrement: () {
                          if (item.quantity == 1) {
                            SangakConfirmDialog.show(
                              context,
                              title: l10n.remove,
                              message: l10n.removeItemFromBasket,
                              confirmLabel: l10n.remove,
                              cancelLabel: l10n.cancel,
                              onConfirm: () => ref.read(basketProvider.notifier).removeItem(item.bread.id),
                              isDestructive: true,
                            );
                          } else {
                            ref.read(basketProvider.notifier).updateQuantity(item.bread.id, -1);
                          }
                        },
                        onDelete: () {
                          SangakConfirmDialog.show(
                            context,
                            title: l10n.remove,
                            message: l10n.removeItemFromBasket,
                            confirmLabel: l10n.remove,
                            cancelLabel: l10n.cancel,
                            onConfirm: () => ref.read(basketProvider.notifier).removeItem(item.bread.id),
                            isDestructive: true,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildSummary(context, ref, total, l10n),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, WidgetRef ref, double total, AppLocalizations l10n) {
    const deliveryFee = 15.0;
    final grandTotal = total + deliveryFee;

    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    final user = ref.watch(authProvider).asData?.value;
    final hasPhone = user?.userMetadata?['phone'] != null && 
                    (user?.userMetadata?['phone'] as String).isNotEmpty && 
                    user?.userMetadata?['phone'] != '+90';

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
          if (!hasPhone)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                l10n.phoneNumberRequired,
                style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.error, fontWeight: FontWeight.bold),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.subtotal, style: SangakTypography.bodyMedium(context)),
              Text(
                SangakNumberFormatter.formatCurrency(total, lang),
                style: SangakTypography.title(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.deliveryFee, style: SangakTypography.bodyMedium(context)),
              Text(
                SangakNumberFormatter.formatCurrency(deliveryFee, lang),
                style: SangakTypography.title(context),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.total, style: SangakTypography.h3(context)),
              Text(
                SangakNumberFormatter.formatCurrency(grandTotal, lang),
                style: SangakTypography.h2(context).copyWith(color: SangakColors.primary),
              ),
            ],
          ),
          const SizedBox(height: SangakDimens.spacing24),
          SangakButton.primary(
            label: l10n.proceedToCheckout,
            width: double.infinity,
            onPressed: hasPhone ? () => context.push('/address-selection?from=checkout') : null,
          ),
        ],
      ),
    );
  }
}
