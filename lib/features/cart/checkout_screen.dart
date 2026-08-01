import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../models/cart_item.dart';
import 'cart_provider.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: SangakColors.background,
      appBar: AppBar(
        title: Text(l10n.checkout),
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
            _buildSectionHeader(l10n.deliveryAddress),
            const SizedBox(height: 12),
            _buildAddressCard(),
            const SizedBox(height: 32),
            _buildSectionHeader(l10n.orderSummary),
            const SizedBox(height: 12),
            _buildOrderSummary(cart),
            const SizedBox(height: 32),
            _buildSectionHeader(l10n.paymentMethod),
            const SizedBox(height: 12),
            _buildPaymentCard(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context, total, l10n, ref),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: SangakTypography.h3);
  }

  Widget _buildAddressCard() {
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
                Text('Home', style: SangakTypography.title),
                Text('Atatürk Mah. No: 123, Çankaya, Ankara', style: SangakTypography.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: SangakColors.inkLight),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(List<CartItem> cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        border: Border.all(color: SangakColors.border),
      ),
      child: Column(
        children: [
          for (final item in cart)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.quantity}x ${item.bread.name}', style: SangakTypography.bodyMedium),
                  Text('₺${item.total.toStringAsFixed(0)}', style: SangakTypography.title.copyWith(fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        border: Border.all(color: SangakColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card, color: SangakColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text('**** **** **** 1234', style: SangakTypography.title),
          ),
          const Icon(Icons.chevron_right, color: SangakColors.inkLight),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, double total, AppLocalizations l10n, WidgetRef ref) {
    const deliveryFee = 15.0;
    final grandTotal = total + deliveryFee;

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
              Text(l10n.grandTotal, style: SangakTypography.h3),
              Text('₺${grandTotal.toStringAsFixed(0)}', style: SangakTypography.h2.copyWith(color: SangakColors.primary)),
            ],
          ),
          const SizedBox(height: SangakDimens.spacing24),
          SangakButton.primary(
            label: l10n.placeOrder,
            width: double.infinity,
            onPressed: () {
              // TODO: Implement order placement
              ref.read(cartProvider.notifier).clear();
              SangakToast.show(context, l10n.orderPlacedSuccessfully);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
