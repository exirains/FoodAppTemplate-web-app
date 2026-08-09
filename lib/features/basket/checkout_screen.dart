import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/utils/auth_gate.dart';
import '../../shared/utils/action_guard.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/basket_item.dart';
import '../../models/address.dart';
import '../../core/localization/sangak_number_formatter.dart';
import 'basket_provider.dart';
import 'checkout_provider.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basket = ref.watch(basketProvider);
    final total = ref.watch(basketTotalProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;

    return Scaffold(
      backgroundColor: SangakColors.background,
      appBar: AppBar(
        title: Text(l10n.orderSummary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SangakDimens.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(l10n.deliveryAddress, context),
            const SizedBox(height: 12),
            _buildAddressCard(checkoutState.selectedAddress, context),
            const SizedBox(height: 32),
            _buildSectionHeader(l10n.paymentMethod, context),
            const SizedBox(height: 12),
            _buildPaymentCard(checkoutState.paymentMethod, l10n, context),
            const SizedBox(height: 32),
            _buildSectionHeader(l10n.orderSummary, context),
            const SizedBox(height: 12),
            _buildOrderSummary(basket, lang, context),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context, total, l10n, ref, checkoutState),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Text(title, style: SangakTypography.h3(context));
  }

  Widget _buildAddressCard(Address? address, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        border: Border.all(color: SangakColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: SangakColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address?.title ?? AppLocalizations.of(context).address, style: SangakTypography.title(context)),
                Text(
                  address?.fullAddress ?? AppLocalizations.of(context).noAddressSelected,
                  style: SangakTypography.bodySmall(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(List<BasketItem> basket, String lang, BuildContext context) {
    const deliveryFee = 15.0;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        border: Border.all(color: SangakColors.border),
      ),
      child: Column(
        children: [
          for (final item in basket)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${SangakNumberFormatter.format(item.quantity, lang)}x ${item.bread.localizedName(lang)}',
                    style: SangakTypography.bodyMedium(context),
                  ),
                  Text(
                    SangakNumberFormatter.formatCurrency(item.total, lang),
                    style: SangakTypography.title(context).copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.deliveryFeeLabel,
                style: SangakTypography.bodyMedium(context).copyWith(color: SangakColors.inkLight),
              ),
              Text(
                SangakNumberFormatter.formatCurrency(deliveryFee, lang),
                style: SangakTypography.title(context).copyWith(fontSize: 14, color: SangakColors.inkLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(PaymentMethod method, AppLocalizations l10n, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        border: Border.all(color: SangakColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: SangakColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              method == PaymentMethod.cash ? l10n.cashOnDelivery : l10n.creditCard,
              style: SangakTypography.title(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, double total, AppLocalizations l10n, WidgetRef ref, CheckoutState checkoutState) {
    const deliveryFee = 15.0;
    final grandTotal = total + deliveryFee;
    final basket = ref.read(basketProvider);
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;

    return Container(
      padding: const EdgeInsets.all(SangakDimens.spacing24),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        boxShadow: SangakDimens.shadowHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(SangakDimens.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.total, style: SangakTypography.caption(context)),
                  Text(
                    SangakNumberFormatter.formatCurrency(grandTotal, lang),
                    style: SangakTypography.h2(context).copyWith(color: SangakColors.primary),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SangakButton.primary(
                  label: l10n.confirmOrder,
                  isLoading: checkoutState.isSubmitting,
                  onPressed: () {
                    if (!ActionGuard.check(context, ref)) return;
                    
                    AuthGate.run(
                      context,
                      ref,
                      action: () async {
                        try {
                          final prepMinutes = basket.fold<int>(
                            0,
                            (sum, item) => sum + (item.bread.prepTime * item.quantity),
                          );
                          ref.read(checkoutProvider.notifier).setEstimatedPrepMinutes(prepMinutes + 15);
                          
                          final orderId = await ref.read(checkoutProvider.notifier).placeOrder();
                          
                          if (context.mounted) {
                            SangakToast.show(context, l10n.orderPlacedSuccessfully);
                            context.push('/order-confirmation', extra: orderId);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            SangakToast.show(context, e.toString());
                          }
                        }
                      },
                      title: l10n.confirmOrder,
                      message: l10n.loginToPlaceOrder,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
