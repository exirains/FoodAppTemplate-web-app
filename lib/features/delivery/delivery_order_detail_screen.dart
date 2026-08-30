import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../core/design_system/babka_dimens.dart';
import '../../models/order.dart';
import '../../shared/widgets/babka_button.dart';
import '../../shared/utils/babka_toast.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/babka_number_formatter.dart';
import '../../services/order_repository.dart';
import '../../services/analytics_service.dart';
import '../auth/auth_provider.dart';
import 'delivery_provider.dart';

class DeliveryOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const DeliveryOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<DeliveryOrderDetailScreen> createState() => _DeliveryOrderDetailScreenState();
}

class _DeliveryOrderDetailScreenState extends ConsumerState<DeliveryOrderDetailScreen> {
  bool _isUpdating = false;

  Future<void> _updateStatus(OrderModel order, OrderStatus newStatus) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isUpdating = true);
    try {
      await ref.read(deliveryDashboardProvider.notifier).pickupOrder(order.id);
      if (mounted) {
        BabkaToast.show(context, '${l10n.status}: ${newStatus.localizedLabel(l10n)}');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('orderAlreadyAssigned')) {
          msg = l10n.orderAlreadyAssigned;
        }
        BabkaToast.show(context, msg);
      }
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
        if (mounted) BabkaToast.show(context, AppLocalizations.of(context).locationError);
      }
    } else {
      if (mounted) BabkaToast.show(context, AppLocalizations.of(context).locationError);
    }
  }

  Future<void> _callCustomer(String? phone) async {
    final l10n = AppLocalizations.of(context);
    if (phone == null || phone.isEmpty) {
      if (mounted) BabkaToast.show(context, l10n.noPhoneNumberAvailable);
      return;
    }
    
    final sanitizedPhone = phone.replaceAll(RegExp(r'[^+\d]'), '');
    final url = Uri.parse('tel:$sanitizedPhone');
    
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) BabkaToast.show(context, l10n.couldNotOpenPhoneDialer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryDashboardProvider);
    final order = [...state.availableOrders, ...state.myTasks].firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => OrderModel(
        id: widget.orderId,
        userId: '',
        status: OrderStatus.pending,
        addressSnapshot: {},
        paymentMethod: '',
        totalPrice: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider).languageCode;

    if (order.userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: BabkaColors.background,
      appBar: AppBar(
        title: Text(l10n.deliveryDetails),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStatusBanner(context, order),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(BabkaDimens.spacing24),
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
                    child: _buildItemsCard(context, order, lang, l10n),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildActions(context, order, l10n),
    );
  }

  Widget _buildStatusBanner(BuildContext context, OrderModel order) {
    final l10n = AppLocalizations.of(context);
    Color bgColor;
    IconData icon;
    String statusText = order.status.localizedLabel(l10n).toUpperCase();
    
    switch (order.status) {
      case OrderStatus.ready:
        bgColor = BabkaColors.info;
        icon = Icons.inventory_2_outlined;
        break;
      case OrderStatus.outForDelivery:
        bgColor = BabkaColors.primary;
        icon = Icons.delivery_dining;
        break;
      case OrderStatus.delivered:
        bgColor = BabkaColors.success;
        icon = Icons.check_circle_outline;
        break;
      default:
        bgColor = BabkaColors.inkLight;
        icon = Icons.help_outline;
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
            style: BabkaTypography.title(context).copyWith(
              color: bgColor,
              fontSize: 14,
              letterSpacing: 1.1,
            ),
          ),
          const Spacer(),
          Text(
            order.orderNumber,
            style: BabkaTypography.caption(context).copyWith(fontWeight: FontWeight.bold),
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
            Icon(icon, size: 18, color: BabkaColors.inkLight),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: BabkaTypography.caption(context).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: BabkaColors.inkLight,
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
    final l10n = AppLocalizations.of(context);
    final profile = order.userProfile;
    final fullName = profile?['full_name'] ?? profile?['fullName'] ?? profile?['full_name_snapshot'] ?? l10n.guest;
    final phone = profile?['phone_number'] ?? profile?['phone'] ?? profile?['phoneNumber'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BabkaColors.surface,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
        border: Border.all(color: BabkaColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName, style: BabkaTypography.h3(context).copyWith(fontSize: 18)),
                if (phone != null)
                  Text(phone, style: BabkaTypography.bodyMedium(context).copyWith(color: BabkaColors.inkLight)),
              ],
            ),
          ),
          if (phone != null)
            Material(
              color: BabkaColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _callCustomer(phone),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.phone_forwarded_rounded, color: BabkaColors.primary),
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
        color: BabkaColors.surface,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
        border: Border.all(color: BabkaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(addr['address'] ?? '', style: BabkaTypography.bodyLarge(context)),
          const SizedBox(height: 8),
          Text(
            '${addr['district']}, ${addr['city']}',
            style: BabkaTypography.bodyMedium(context).copyWith(color: BabkaColors.inkLight),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.building}: ${addr['building_number'] ?? '-'} • ${l10n.floor}: ${addr['floor'] ?? '-'} • ${l10n.door}: ${addr['door_number'] ?? '-'}',
            style: BabkaTypography.bodySmall(context),
          ),
          if (deliveryNote != null && deliveryNote.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BabkaColors.warning.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BabkaColors.warning.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: BabkaColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deliveryNote,
                      style: BabkaTypography.bodyMedium(context).copyWith(color: BabkaColors.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          BabkaButton.outlined(
            label: l10n.openMap,
            icon: Icons.directions_rounded,
            width: double.infinity,
            onPressed: () => _openMap(addr),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, OrderModel order, String lang, AppLocalizations l10n) {
    final items = order.items ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BabkaColors.surface,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
        border: Border.all(color: BabkaColors.border),
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
                    color: BabkaColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.quantity}x',
                    style: BabkaTypography.title(context).copyWith(fontSize: 14, color: BabkaColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.localizedName(lang), style: BabkaTypography.bodyMedium(context))),
                Text(BabkaNumberFormatter.formatCurrency(item.priceAtPurchase * item.quantity, lang), 
                  style: BabkaTypography.bodySmall(context)),
              ],
            ),
          )),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.totalToCollect.toUpperCase(), 
                style: BabkaTypography.caption(context).copyWith(fontWeight: FontWeight.bold, color: BabkaColors.primary),
              ),
              Text(
                BabkaNumberFormatter.formatCurrency(order.totalPrice, lang),
                style: BabkaTypography.h3(context).copyWith(color: BabkaColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showVerificationDialog(OrderModel order) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            const Icon(Icons.verified_user_outlined, color: BabkaColors.primary, size: 48),
            const SizedBox(height: 16),
            Text(l10n.deliveryVerification, textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.enterVerificationCode, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: 150,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 2,
                textAlign: TextAlign.center,
                style: BabkaTypography.h1(context).copyWith(
                  fontSize: 48, 
                  letterSpacing: 16,
                  color: BabkaColors.primary,
                ),
                decoration: InputDecoration(
                  hintText: "00",
                  hintStyle: TextStyle(color: BabkaColors.border.withValues(alpha: 0.5)),
                  counterText: "",
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: BabkaColors.primary, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: BabkaColors.primary, width: 3),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text(l10n.cancel, style: const TextStyle(color: BabkaColors.inkLight)),
          ),
          BabkaButton.primary(
            label: l10n.confirmButton,
            width: 120,
            onPressed: () {
              if (controller.text == (order.deliveryCode ?? "00")) {
                Navigator.pop(context, true);
              } else {
                BabkaToast.show(context, l10n.invalidVerificationCode);
              }
            },
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );

    if (result == true) {
      final pin = controller.text;
      setState(() => _isUpdating = true);
      try {
        await ref.read(babkaOrderRepositoryProvider).confirmDelivery(
          orderId: order.id,
          pin: pin,
        );
        
        // Log delivery completion
        ref.read(analyticsServiceProvider).logDeliveryCompleted(orderId: order.id);

        if (mounted) {
          BabkaToast.show(context, l10n.deliveredStep);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          BabkaToast.show(context, l10n.errorOccurred);
        }
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    }
  }

  Widget _buildActions(BuildContext context, OrderModel order, AppLocalizations l10n) {
    Widget? mainAction;
    final currentUser = ref.read(authProvider).asData?.value;
    final bool isAssignedToMe = order.assignedDeliveryPerson == currentUser?.id;

    if (order.status == OrderStatus.outForDelivery && isAssignedToMe) {
      mainAction = Expanded(
        child: BabkaButton.primary(
          label: l10n.markDelivered,
          onPressed: () => _showVerificationDialog(order),
          isLoading: _isUpdating,
        ),
      );
    } else if (order.status == OrderStatus.ready) {
      mainAction = Expanded(
        child: BabkaButton.primary(
          label: l10n.pickupOrder,
          onPressed: () => _updateStatus(order, OrderStatus.outForDelivery),
          isLoading: _isUpdating,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(BabkaDimens.spacing24),
      decoration: BoxDecoration(
        color: BabkaColors.surface,
        boxShadow: BabkaDimens.shadowHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(BabkaDimens.radiusXL)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            mainAction,
          ],
        ),
      ),
    );
  }
}

