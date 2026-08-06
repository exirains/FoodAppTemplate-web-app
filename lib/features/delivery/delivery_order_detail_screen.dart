import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../models/order.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../auth/auth_provider.dart';
import '../admin/admin_provider.dart';
import 'delivery_dashboard_screen.dart';

class DeliveryOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const DeliveryOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<DeliveryOrderDetailScreen> createState() => _DeliveryOrderDetailScreenState();
}

class _DeliveryOrderDetailScreenState extends ConsumerState<DeliveryOrderDetailScreen> {
  bool _isUpdating = false;

  Future<void> _updateStatus(OrderModel order, OrderStatus newStatus) async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) return;

    setState(() => _isUpdating = true);
    try {
      if (order.assignedDeliveryPerson == null) {
         await ref.read(orderRepositoryProvider).assignDeliveryPerson(order.id, user.id);
      }

      await ref.read(orderRepositoryProvider).updateOrderStatus(
        orderId: widget.orderId,
        status: newStatus,
        changedBy: user.id,
      );
      
      ref.invalidate(availableOrdersProvider);
      ref.invalidate(myActiveDeliveriesProvider);
      ref.invalidate(deliveryOrderDetailProvider(widget.orderId));
      
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SangakToast.show(context, '${l10n.status}: ${newStatus.label}');
        if (newStatus == OrderStatus.delivered) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) SangakToast.show(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _openMap(Map<String, dynamic> address) async {
    final double? lat = address['latitude'];
    final double? lon = address['longitude'];

    if (lat != null && lon != null) {
      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) SangakToast.show(context, AppLocalizations.of(context).locationError);
      }
    } else {
      if (mounted) SangakToast.show(context, AppLocalizations.of(context).locationError);
    }
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(deliveryOrderDetailProvider(widget.orderId));
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: SangakColors.background,
      appBar: AppBar(
        title: Text(l10n.deliveryDetails),
        elevation: 0,
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) return Center(child: Text(l10n.noProductsFound));

          return Column(
            children: [
              _buildStatusBanner(context, order),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(SangakDimens.spacing24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(
                        context,
                        title: l10n.customer,
                        icon: Icons.person_outline,
                        child: _buildCustomerCard(context, order),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoSection(
                        context,
                        title: l10n.deliveryAddressLabel,
                        icon: Icons.location_on_outlined,
                        child: _buildAddressCard(context, order, l10n),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoSection(
                        context,
                        title: l10n.orderItemsLabel,
                        icon: Icons.shopping_basket_outlined,
                        child: _buildItemsCard(context, order, lang),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
      bottomSheet: orderAsync.when(
        data: (order) => order != null ? _buildActions(context, order, l10n) : null,
        loading: () => null,
        error: (error, stack) => null,
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, OrderModel order) {
    Color bgColor;
    IconData icon;
    String statusText;
    
    switch (order.status) {
      case OrderStatus.ready:
        bgColor = SangakColors.info;
        icon = Icons.inventory_2_outlined;
        statusText = 'READY';
        break;
      case OrderStatus.outForDelivery:
        bgColor = SangakColors.primary;
        icon = Icons.delivery_dining;
        statusText = 'OUT FOR DELIVERY';
        break;
      case OrderStatus.delivered:
        bgColor = SangakColors.success;
        icon = Icons.check_circle_outline;
        statusText = 'DELIVERED';
        break;
      default:
        bgColor = SangakColors.inkLight;
        icon = Icons.help_outline;
        statusText = order.status.name.toUpperCase();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      color: bgColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(icon, color: bgColor, size: 20),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: SangakTypography.title(context).copyWith(
              color: bgColor,
              fontSize: 14,
              letterSpacing: 1.1,
            ),
          ),
          const Spacer(),
          Text(
            order.orderNumber,
            style: SangakTypography.caption(context).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, {required String title, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: SangakColors.inkLight),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: SangakTypography.caption(context).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: SangakColors.inkLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildCustomerCard(BuildContext context, OrderModel order) {
    final profile = order.userProfile;
    final fullName = profile?['full_name'] ?? profile?['fullName'] ?? profile?['full_name_snapshot'] ?? 'Guest';
    final phone = profile?['phone_number'] ?? profile?['phone'] ?? profile?['phoneNumber'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        border: Border.all(color: SangakColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName, style: SangakTypography.h3(context).copyWith(fontSize: 18)),
                if (phone != null)
                  Text(phone, style: SangakTypography.bodyMedium(context).copyWith(color: SangakColors.inkLight)),
              ],
            ),
          ),
          if (phone != null)
            Material(
              color: SangakColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _callCustomer(phone),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.phone_forwarded_rounded, color: SangakColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, OrderModel order, AppLocalizations l10n) {
    final addr = order.addressSnapshot;
    final deliveryNote = addr['delivery_note']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        border: Border.all(color: SangakColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(addr['address'] ?? '', style: SangakTypography.bodyLarge(context)),
          const SizedBox(height: 8),
          Text(
            '${addr['district']}, ${addr['city']}',
            style: SangakTypography.bodyMedium(context).copyWith(color: SangakColors.inkLight),
          ),
          const SizedBox(height: 4),
          Text(
            'Building: ${addr['building_number']} • Floor: ${addr['floor']} • Door: ${addr['door_number']}',
            style: SangakTypography.bodySmall(context),
          ),
          if (deliveryNote != null && deliveryNote.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SangakColors.warning.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SangakColors.warning.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: SangakColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deliveryNote,
                      style: SangakTypography.bodyMedium(context).copyWith(color: SangakColors.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SangakButton.outlined(
            label: l10n.openMap,
            icon: Icons.directions_rounded,
            width: double.infinity,
            onPressed: () => _openMap(addr),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, OrderModel order, String lang) {
    final items = order.items ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        border: Border.all(color: SangakColors.border),
      ),
      child: Column(
        children: [
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SangakColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.quantity}x',
                    style: SangakTypography.title(context).copyWith(fontSize: 14, color: SangakColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.nameSnapshot, style: SangakTypography.bodyMedium(context))),
              ],
            ),
          )),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL TO COLLECT', 
                style: SangakTypography.caption(context).copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                SangakNumberFormatter.formatCurrency(order.totalPrice, lang),
                style: SangakTypography.h3(context).copyWith(color: SangakColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, OrderModel order, AppLocalizations l10n) {
    Widget action;
    if (order.status == OrderStatus.outForDelivery) {
      action = SangakButton.primary(
        label: l10n.markDelivered,
        backgroundColor: SangakColors.success,
        onPressed: () => _updateStatus(order, OrderStatus.delivered),
        isLoading: _isUpdating,
      );
    } else if (order.status == OrderStatus.ready) {
      action = SangakButton.primary(
        label: l10n.pickupOrder,
        onPressed: () => _updateStatus(order, OrderStatus.outForDelivery),
        isLoading: _isUpdating,
      );
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(SangakDimens.spacing24),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        boxShadow: SangakDimens.shadowHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(SangakDimens.radiusXL)),
      ),
      child: SafeArea(child: action),
    );
  }
}
