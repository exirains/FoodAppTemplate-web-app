import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import '../../shared/widgets/sangak_button.dart';
import 'checkout_provider.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final checkoutState = ref.watch(checkoutProvider);
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    
    final orderNumber = 'SNK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final formattedOrderNumber = SangakNumberFormatter.format(orderNumber, lang);
    
    final prepMinutes = checkoutState.estimatedPrepMinutes == 0
        ? 25
        : checkoutState.estimatedPrepMinutes;

    return Scaffold(
      backgroundColor: SangakColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SangakDimens.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: SangakColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.orderReceived,
                style: SangakTypography.h1(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.thankYouSangak,
                style: SangakTypography.bodyLarge(context).copyWith(color: SangakColors.inkLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildInfoRow(l10n.orderNumber, formattedOrderNumber, context),
              const Divider(height: 32),
              _buildInfoRow(l10n.estimatedTime, l10n.mins(prepMinutes), context),
              const Divider(height: 32),
              _buildInfoRow(l10n.estimatedDeliveryTime, '${l10n.mins(10)} - ${l10n.mins(15)}', context),
              const Divider(height: 32),
              _buildInfoRow(l10n.deliveryAddress, checkoutState.selectedAddress?.fullAddress ?? '-', context),
              const Divider(height: 32),
              _buildInfoRow(l10n.paymentMethod, l10n.cashOnDelivery, context),
              const Spacer(),
              SangakButton.primary(
                label: l10n.backToHome,
                width: double.infinity,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: SangakTypography.bodyMedium(context)),
        const SizedBox(width: 24),
        Expanded(
          child: Text(
            value,
            style: SangakTypography.title(context).copyWith(fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
