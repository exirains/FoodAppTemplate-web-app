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
import '../../shared/utils/sangak_toast.dart';
import '../../shared/utils/action_guard.dart';
import 'basket_provider.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_validators.dart';
import '../auth/profile_provider.dart';
import '../auth/models/user_profile.dart';
import '../../models/sangak_customization.dart';
import '../custom_sangak/data/sangak_customization_options.dart';

import '../../services/options_repository.dart';

class BasketScreen extends ConsumerWidget {
  const BasketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basket = ref.watch(basketProvider);
    final total = ref.watch(basketTotalProvider);
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    final profileAsync = ref.watch(userProfileProvider);
    final authUser = ref.watch(authProvider).value;
    final optionsAsync = ref.watch(appOptionsProvider);

    final hasPhone = AuthValidators.hasValidPhoneNumber(profileAsync.value?.phoneNumber) ||
                     AuthValidators.hasValidPhoneNumber(authUser?.userMetadata?['phone'] as String?);

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
            onPressed: () {
              if (!ActionGuard.check(context, ref)) return;
              SangakConfirmDialog.show(
                context,
                title: l10n.clearBasket,
                message: l10n.confirmClearBasket,
                confirmLabel: l10n.clear,
                cancelLabel: l10n.cancel,
                onConfirm: () => ref.read(basketProvider.notifier).clear(),
                isDestructive: true,
              );
            },
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
                  padding: const EdgeInsets.all(16),
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
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 64,
                            height: 64,
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
                            width: 64,
                            height: 64,
                            color: SangakColors.border,
                            child: const Icon(Icons.broken_image_outlined, color: SangakColors.inkLight),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.bread.localizedName(lang), 
                              style: SangakTypography.title(context).copyWith(fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.customization != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  _getCustomizationSummary(item.customization!),
                                  style: SangakTypography.bodySmall(context).copyWith(
                                    fontSize: 12,
                                    color: SangakColors.primary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              SangakNumberFormatter.formatCurrency(item.bread.price, lang),
                              style: SangakTypography.price(context).copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        child: QuantitySelector(
                          quantity: item.quantity,
                          compact: true,
                          onIncrement: () {
                            if (!ActionGuard.check(context, ref)) return;
                            ref.read(basketProvider.notifier).updateQuantity(item.basketId, 1);
                          },
                          onDecrement: () {
                            if (!ActionGuard.check(context, ref)) return;
                            if (item.quantity == 1) {
                              SangakConfirmDialog.show(
                                context,
                                title: l10n.remove,
                                message: l10n.removeItemFromBasket,
                                confirmLabel: l10n.remove,
                                cancelLabel: l10n.cancel,
                                onConfirm: () => ref.read(basketProvider.notifier).removeItem(item.basketId),
                                isDestructive: true,
                              );
                            } else {
                              ref.read(basketProvider.notifier).updateQuantity(item.basketId, -1);
                            }
                          },
                          onDelete: () {
                            if (!ActionGuard.check(context, ref)) return;
                            SangakConfirmDialog.show(
                              context,
                              title: l10n.remove,
                              message: l10n.removeItemFromBasket,
                              confirmLabel: l10n.remove,
                              cancelLabel: l10n.cancel,
                              onConfirm: () => ref.read(basketProvider.notifier).removeItem(item.basketId),
                              isDestructive: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildSummary(context, ref, total, l10n, profileAsync.value, hasPhone, optionsAsync),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, WidgetRef ref, double total, AppLocalizations l10n, UserProfile? profile, bool hasPhone, AsyncValue<Map<String, dynamic>> optionsAsync) {
    // Get values from DB. Use 0 fallback while loading to avoid "200" flickering.
    // Once loaded, if key is missing, THEN we use the business fallback of 200.
    final Map<String, dynamic> dbOptions = optionsAsync.value ?? {};
    
    final dynamic rawDeliveryFee = dbOptions['delivery_fee'];
    final double deliveryFee = (rawDeliveryFee != null)
        ? (double.tryParse(rawDeliveryFee.toString()) ?? 0.0)
        : 0.0;

    final dynamic rawLimit = dbOptions['min_order_limit'];
    final int minLimit = (rawLimit != null) 
        ? (int.tryParse(rawLimit.toString()) ?? 0) 
        : 0;

    final grandTotal = total + deliveryFee;

    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    
    final isAccountDisabled = profile != null && !profile.isActive;
    
    final bool isBelowLimit = total < minLimit;

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
          // 1. Account Disabled Check (Highest Priority)
          if (isAccountDisabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SangakColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SangakColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_person_outlined, color: SangakColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.accountDisabledTitle,
                        style: SangakTypography.bodySmall(context).copyWith(
                          color: SangakColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Minimum Order Limit Check (Show only if account is NOT disabled)
          if (!isAccountDisabled && isBelowLimit && minLimit > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: SangakColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SangakColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: SangakColors.error, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.minOrderLimitError(minLimit),
                        style: SangakTypography.caption(context).copyWith(
                          color: SangakColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Phone Number Check (Show only if above limit and not disabled)
          if (!isAccountDisabled && !isBelowLimit && !hasPhone)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
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
              Text(l10n.deliveryFeeLabel, style: SangakTypography.bodyMedium(context)),
              if (deliveryFee == 0)
                Text(
                  l10n.freeDelivery,
                  style: SangakTypography.title(context).copyWith(color: Colors.green.shade700),
                )
              else
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
            isLoading: optionsAsync.isLoading,
            onPressed: (optionsAsync.isLoading) ? null : () {
              // Priority 1: Check Account Status
              if (!ActionGuard.check(context, ref)) return;
              
              // Priority 2: Check Minimum Order Limit
              if (isBelowLimit) {
                SangakToast.show(context, l10n.minOrderLimitError(minLimit));
                return;
              }

              // Priority 3: Check Phone Number
              if (hasPhone) {
                context.push('/address-selection?from=checkout');
              } else {
                SangakToast.show(context, l10n.addPhoneToOrder);
                ref.read(tabProvider.notifier).state = 3;
              }
            },
          ),
        ],
      ),
    );
  }

  String _getCustomizationSummary(SangakCustomization customization) {
    if (customization.selectedOptions.isEmpty) return 'Plain';
    
    final List<String> parts = [];
    for (final entry in customization.selectedOptions.entries) {
      final option = sangakCustomizationOptions.cast<SangakCustomizationOption?>().firstWhere(
        (o) => o?.id == entry.key,
        orElse: () => null,
      );
      if (option != null) {
        final name = option.name;
        final qty = entry.value;
        parts.add(qty > 1 ? '$name (x$qty)' : name);
      }
    }
    return parts.isEmpty ? 'Custom' : parts.join(', ');
  }
}
