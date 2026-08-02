import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import 'checkout_provider.dart';

class PaymentSelectionScreen extends ConsumerWidget {
  const PaymentSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedMethod = ref.watch(checkoutProvider).paymentMethod;

    return Scaffold(
      backgroundColor: SangakColors.background,
      appBar: AppBar(
        title: Text(l10n.paymentMethod),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(SangakDimens.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.selectPaymentMethod, style: SangakTypography.h3(context)),
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
        padding: const EdgeInsets.all(SangakDimens.spacing24),
        decoration: BoxDecoration(
          color: SangakColors.surface,
          boxShadow: SangakDimens.shadowHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(SangakDimens.radiusXL)),
        ),
        child: SangakButton.primary(
          label: l10n.continueButton,
          width: double.infinity,
          onPressed: () => context.push('/checkout'),
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
        onTap: isEnabled ? () => ref.read(checkoutProvider.notifier).selectPaymentMethod(method) : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SangakColors.surface,
            borderRadius: BorderRadius.circular(SangakDimens.radiusL),
            border: Border.all(
              color: isSelected ? SangakColors.primary : SangakColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? SangakColors.primary : SangakColors.inkLight),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SangakTypography.title(context)),
                    Text(subtitle, style: SangakTypography.bodySmall(context)),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: SangakColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
