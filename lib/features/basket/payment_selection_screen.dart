import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/utils/sangak_toast.dart';
import 'checkout_provider.dart';

class PaymentSelectionScreen extends ConsumerWidget {
  final bool fromCheckout;
  const PaymentSelectionScreen({super.key, this.fromCheckout = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedMethod = ref.watch(checkoutProvider).paymentMethod;

    return Scaffold(
      backgroundColor: BabkaColors.background,
      appBar: AppBar(
        title: Text(l10n.paymentMethod),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(BabkaDimens.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.selectPaymentMethod, style: BabkaTypography.h3(context)),
            const SizedBox(height: 16),
            _buildPaymentMethodItem(
              context,
              ref,
              PaymentMethod.cash,
              l10n.cashOnDelivery,
              l10n.cashOnDeliveryDescription,
              Icons.payments_outlined,
              selectedMethod == PaymentMethod.cash,
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodItem(
              context,
              ref,
              PaymentMethod.card,
              l10n.creditCard,
              l10n.payWithCardOnDelivery,
              Icons.credit_card_outlined,
              selectedMethod == PaymentMethod.card,
              isEnabled: false,
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(BabkaDimens.spacing24),
        decoration: BoxDecoration(
          color: BabkaColors.surface,
          boxShadow: BabkaDimens.shadowHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(BabkaDimens.radiusXL)),
        ),
        child: BabkaButton.primary(
          label: l10n.continueButton,
          width: double.infinity,
          onPressed: () {
            if (fromCheckout) {
              context.push('/checkout');
            } else {
              SangakToast.show(context, l10n.profileUpdated);
              context.pop();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem(
    BuildContext context,
    WidgetRef ref,
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
    bool isSelected, {
    bool isEnabled = true,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isEnabled ? () => ref.read(checkoutProvider.notifier).selectPaymentMethod(method) : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BabkaColors.surface,
            borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
            border: Border.all(
              color: isSelected ? BabkaColors.primary : BabkaColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? BabkaColors.primary : BabkaColors.inkLight),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: BabkaTypography.title(context)),
                    Text(subtitle, style: BabkaTypography.bodySmall(context)),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: BabkaColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
