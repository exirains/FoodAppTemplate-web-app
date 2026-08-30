import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../core/design_system/babka_dimens.dart';
import '../../models/order.dart';
import '../../l10n/app_localizations.dart';
import '../../core/localization/babka_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import 'orders_provider.dart';

import 'widgets/order_rating_dialog.dart';
import '../../shared/widgets/babka_button.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider).languageCode;

    ref.listen(orderStatusProvider(widget.orderId), (previous, next) {
      next.whenData((order) {
        if (order?.status == OrderStatus.delivered && !_dialogShown) {
          _dialogShown = true;
          _showDeliverySuccessDialog(context, order!.id);
        }
      });
    });

    final orderAsync = ref.watch(orderStatusProvider(widget.orderId));
    final historyAsync = ref.watch(orderHistoryProvider(widget.orderId));

    return Scaffold(
      backgroundColor: BabkaColors.background,
      appBar: AppBar(
        title: Text(l10n.orderTracking),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, order, l10n, lang),
                // ALWAYS SHOW PIN (Security feature requested)
                _buildPinCard(context, order, l10n),
                historyAsync.when(
                  data: (history) => _buildStepper(context, order, history, l10n),
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  )),
                  error: (e, s) => Center(child: Text(l10n.errorOccurred)),
                ),
                if (order.status == OrderStatus.delivered) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: BabkaButton.primary(
                      label: l10n.rateOrder,
                      icon: Icons.star_outline_rounded,
                      width: double.infinity,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => OrderRatingDialog(orderId: order.id),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 48),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l10n.errorOccurred)),
      ),
    );
  }

  void _showDeliverySuccessDialog(BuildContext context, String orderId) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: BabkaColors.success, size: 64),
            const SizedBox(height: 16),
            Text(l10n.statusDelivered, style: BabkaTypography.h2(context)),
          ],
        ),
        content: Text(
          l10n.deliverySuccessMessage,
          textAlign: TextAlign.center,
          style: BabkaTypography.bodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          BabkaButton.primary(
            label: l10n.rateOrder,
            width: 120,
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => OrderRatingDialog(orderId: orderId),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, OrderModel order, AppLocalizations l10n, String lang) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BabkaColors.surface,
        boxShadow: BabkaDimens.shadowLow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.orderNumber, style: BabkaTypography.h3(context)),
              Text(
                '${order.items?.length ?? 0} items • ${BabkaNumberFormatter.formatCurrency(order.totalPrice, lang)}',
                style: BabkaTypography.bodySmall(context),
              ),
            ],
          ),
          _StatusBadge(status: order.status),
        ],
      ),
    );
  }

  Widget _buildPinCard(BuildContext context, OrderModel order, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BabkaColors.primary, BabkaColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: BabkaColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.givePinToDriver,
                  style: BabkaTypography.bodySmall(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  order.deliveryCode ?? "--",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(BuildContext context, OrderModel order, List<Map<String, dynamic>> history, AppLocalizations l10n) {
    final List<_StepData> steps = [
      _StepData(
        status: OrderStatus.confirmed,
        title: l10n.orderConfirmedStep,
        description: l10n.orderConfirmedDesc,
        icon: Icons.assignment_turned_in_outlined,
      ),
      _StepData(
        status: OrderStatus.preparing,
        title: l10n.preparingStep,
        description: l10n.preparingDesc,
        icon: Icons.bakery_dining_outlined,
      ),
      _StepData(
        status: OrderStatus.ready,
        title: l10n.readyStep,
        description: l10n.readyDesc,
        icon: Icons.shopping_bag_outlined,
      ),
      _StepData(
        status: OrderStatus.outForDelivery,
        title: l10n.outForDeliveryStep,
        description: l10n.outForDeliveryDesc,
        icon: Icons.delivery_dining_outlined,
      ),
      _StepData(
        status: OrderStatus.delivered,
        title: l10n.deliveredStep,
        description: l10n.deliveredDesc,
        icon: Icons.home_outlined,
      ),
    ];

    int currentStatusIndex = steps.indexWhere((s) => s.status == order.status);
    if (order.status == OrderStatus.cancelled) currentStatusIndex = -1;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final historyItem = history.where((h) => h['status'] == step.status.toString()).firstOrNull;
          
          final bool isCompleted = historyItem != null || (currentStatusIndex != -1 && index <= currentStatusIndex);
          final bool isCurrent = index == currentStatusIndex;
          final bool isLast = index == steps.length - 1;

          String? timeStr;
          if (historyItem != null) {
            final dt = DateTime.parse(historyItem['created_at']).toLocal();
            timeStr = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // STEP INDICATOR
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted ? BabkaColors.primary : BabkaColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? BabkaColors.primary : BabkaColors.border,
                          width: 2,
                        ),
                        boxShadow: isCurrent ? [
                          BoxShadow(
                            color: BabkaColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ] : null,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : step.icon,
                        size: 18,
                        color: isCompleted ? Colors.white : BabkaColors.inkLight,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted ? BabkaColors.primary : BabkaColors.border,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                // STEP CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            step.title,
                            style: BabkaTypography.title(context).copyWith(
                              color: isCompleted ? BabkaColors.ink : BabkaColors.inkLight,
                              fontSize: 16,
                              fontWeight: isCurrent ? FontWeight.w900 : (isCompleted ? FontWeight.bold : FontWeight.w500),
                            ),
                          ),
                          if (timeStr != null)
                            Text(
                              timeStr,
                              style: BabkaTypography.caption(context).copyWith(
                                color: BabkaColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        step.description,
                        style: BabkaTypography.bodySmall(context).copyWith(
                          color: isCompleted ? BabkaColors.inkLight : BabkaColors.border,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StepData {
  final OrderStatus status;
  final String title;
  final String description;
  final IconData icon;

  _StepData({
    required this.status,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color color;
    switch (status) {
      case OrderStatus.delivered: color = BabkaColors.success; break;
      case OrderStatus.cancelled: color = BabkaColors.error; break;
      default: color = BabkaColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
      ),
      child: Text(
        status.localizedLabel(l10n),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

