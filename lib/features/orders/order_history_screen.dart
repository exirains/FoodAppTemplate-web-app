import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/order.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/sangak_button.dart';
import 'orders_provider.dart';
import 'widgets/order_rating_dialog.dart';
import '../../services/options_repository.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: BabkaColors.background,
      appBar: AppBar(
        title: Text(l10n.orders),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 64, color: BabkaColors.inkLight),
                  const SizedBox(height: 16),
                  Text(l10n.noOrdersYet, style: BabkaTypography.title(context)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(BabkaDimens.spacing24),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _OrderCard(order: orders[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorOccurred)),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider).languageCode;
    final dateStr = DateFormat('MMM dd, yyyy • HH:mm').format(order.createdAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BabkaColors.surface,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
        boxShadow: BabkaDimens.shadowLow,
        border: Border.all(color: BabkaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(BabkaNumberFormatter.format(order.orderNumber, lang), style: BabkaTypography.title(context).copyWith(fontSize: 16)),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(BabkaNumberFormatter.format(dateStr, lang), style: BabkaTypography.bodySmall(context).copyWith(color: BabkaColors.inkLight)),
          const Divider(height: 24),
          if (order.items != null)
            ...order.items!.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${BabkaNumberFormatter.format(item.quantity, lang)}x ${item.localizedName(lang)}', style: BabkaTypography.bodyMedium(context)),
                  Text(BabkaNumberFormatter.formatCurrency(item.total, lang), style: BabkaTypography.title(context).copyWith(fontSize: 14)),
                ],
              ),
            )),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.deliveryFeeLabel, style: BabkaTypography.bodyMedium(context).copyWith(color: BabkaColors.inkLight)),
              Consumer(builder: (context, ref, child) {
                final options = ref.watch(appOptionsProvider).value ?? {};
                final fee = double.tryParse(options['delivery_fee']?.toString() ?? '0') ?? 0.0;
                return Text(BabkaNumberFormatter.formatCurrency(fee, lang), style: BabkaTypography.title(context).copyWith(fontSize: 14, color: BabkaColors.inkLight));
              }),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.total, style: BabkaTypography.title(context)),
              Text(BabkaNumberFormatter.formatCurrency(order.totalPrice, lang), style: BabkaTypography.h3(context).copyWith(color: BabkaColors.primary)),
            ],
          ),
          
          // ACTIONS
          if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) ...[
            const SizedBox(height: 16),
            BabkaButton.primary(
              label: l10n.trackOrder,
              icon: Icons.map_outlined,
              width: double.infinity,
              onPressed: () => context.push('/tracking/${order.id}'),
            ),
          ],
          
          if (order.status == OrderStatus.delivered) ...[
            const SizedBox(height: 16),
            Consumer(builder: (context, ref, child) {
              final isRatedAsync = ref.watch(isOrderRatedProvider(order.id));
              return isRatedAsync.when(
                data: (isRated) => isRated 
                    ? BabkaButton.primary(
                        label: l10n.orderInformation,
                        icon: Icons.receipt_long_rounded,
                        width: double.infinity,
                        onPressed: () => context.push('/tracking/${order.id}'),
                      )
                    : BabkaButton.outlined(
                        label: l10n.rateOrder,
                        icon: Icons.star_outline_rounded,
                        width: double.infinity,
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => OrderRatingDialog(orderId: order.id),
                        ),
                      ),
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))),
                error: (error, stack) => BabkaButton.outlined(
                  label: l10n.rateOrder,
                  icon: Icons.star_outline_rounded,
                  width: double.infinity,
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => OrderRatingDialog(orderId: order.id),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color color;
    switch (status) {
      case OrderStatus.pending: color = Colors.orange; break;
      case OrderStatus.confirmed: color = Colors.cyan; break;
      case OrderStatus.preparing: color = Colors.blue; break;
      case OrderStatus.ready: color = Colors.teal; break;
      case OrderStatus.outForDelivery: color = Colors.purple; break;
      case OrderStatus.delivered: color = Colors.green; break;
      case OrderStatus.cancelled: color = Colors.red; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BabkaDimens.radiusPill), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(status.localizedLabel(l10n), style: BabkaTypography.caption(context).copyWith(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
