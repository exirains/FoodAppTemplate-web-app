import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../models/order.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/widgets/cancel_order_dialog.dart';
import '../../services/options_repository.dart';
import '../auth/auth_provider.dart';
import 'admin_provider.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends ConsumerState<AdminOrderDetailScreen> {
  bool _isUpdating = false;

  Future<void> _updateStatus(OrderStatus newStatus) async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) return;

    setState(() => _isUpdating = true);
    try {
      await ref.read(sangakOrderRepositoryProvider).updateOrderStatus(
        orderId: widget.orderId,
        status: newStatus,
        changedBy: user.id,
      );
      
      // Refresh data
      ref.invalidate(adminOrderDetailProvider(widget.orderId));
      ref.invalidate(adminOrdersProvider);
      
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        BabkaToast.show(context, '${l10n.status}: ${newStatus.localizedLabel(l10n)}');
      }
    } catch (e) {
      if (mounted) {
        BabkaToast.show(context, 'Error updating order: $e');
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _cancelOrder(String reason) async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) return;

    setState(() => _isUpdating = true);
    try {
      await ref.read(sangakOrderRepositoryProvider).updateOrderStatus(
        orderId: widget.orderId,
        status: OrderStatus.cancelled,
        changedBy: user.id,
      );
      
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        BabkaToast.show(context, l10n.orderCancelled);
        ref.invalidate(adminOrderDetailProvider(widget.orderId));
        ref.invalidate(adminOrdersProvider);
      }
    } catch (e) {
      if (mounted) BabkaToast.show(context, 'Error: $e');
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
      if (mounted) {
        BabkaToast.show(context, AppLocalizations.of(context).locationError);
      }
    }
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) {
      if (mounted) BabkaToast.show(context, AppLocalizations.of(context).phoneNumberRequired);
      return;
    }
    
    // Preserve + and digits for international dialing
    final sanitizedPhone = phone.replaceAll(RegExp(r'[^+\d]'), '');
    final url = Uri.parse('tel:$sanitizedPhone');
    
    debugPrint('📱 Admin attempting call: $sanitizedPhone');
    
    try {
      // Force launch to native dialer
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('🚨 Admin call failed: $e');
      if (mounted) BabkaToast.show(context, 'Could not open phone dialer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(adminOrderDetailProvider(widget.orderId));
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider).languageCode;

    return RoleGuard(
      allowedRoles: const ['admin', 'staff'],
      child: Scaffold(
        backgroundColor: BabkaColors.background,
        appBar: AppBar(title: Text(l10n.orderSummary)),
        body: orderAsync.when(
          data: (order) {
            if (order == null) return Center(child: Text(l10n.noProductsFound));
  
            return SingleChildScrollView(
              padding: const EdgeInsets.all(BabkaDimens.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, order, l10n),
                  const SizedBox(height: 32),
                  
                  _buildCustomerSection(context, order, l10n),
                  const SizedBox(height: 32),
                  
                  _buildAddressSection(context, order, l10n),
                  const SizedBox(height: 32),
                  
                  _buildItemsSection(context, order, lang, l10n),
                  const SizedBox(height: 32),
                  
                  _buildSummarySection(context, order, lang, l10n),
                  const SizedBox(height: 120), // Space for bottom actions
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text(l10n.errorOccurred)),
        ),
        bottomSheet: orderAsync.when(
          data: (order) => order != null ? _buildActions(context, order, l10n) : null,
          loading: () => null,
          error: (e, s) => null,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, OrderModel order, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.orderNumber, style: BabkaTypography.h2(context)),
            Text(
              '${l10n.placedAtLabel} ${_formatDateTime(order.createdAt)}',
              style: BabkaTypography.caption(context),
            ),
          ],
        ),
        _StatusBadge(status: order.status),
      ],
    );
  }

  Widget _buildCustomerSection(BuildContext context, OrderModel order, AppLocalizations l10n) {
    final profile = order.userProfile;
    // Robust parsing to ensure we catch the data even if nested differently
    final String fullName = profile?['full_name'] ?? profile?['fullName'] ?? profile?['full_name_snapshot'] ?? l10n.guest;
    final String email = profile?['email'] ?? order.userId;
    final String? phone = profile?['phone'] ?? profile?['phone_number'] ?? profile?['phoneNumber'];
    final String? avatarUrl = profile?['avatar_url'] ?? profile?['avatarUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.customer),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BabkaColors.surface,
            borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
            border: Border.all(color: BabkaColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: BabkaColors.border,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? CachedNetworkImageProvider(avatarUrl) : null,
                child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person, color: BabkaColors.inkLight) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName, style: BabkaTypography.title(context).copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(email, style: BabkaTypography.bodySmall(context).copyWith(color: BabkaColors.inkLight)),
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(phone, style: BabkaTypography.bodySmall(context).copyWith(color: BabkaColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
              if (phone != null && phone.isNotEmpty)
                IconButton(
                  onPressed: () => _callCustomer(phone),
                  icon: const Icon(Icons.phone_outlined, color: BabkaColors.primary),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection(BuildContext context, OrderModel order, AppLocalizations l10n) {
    final addr = order.addressSnapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context, l10n.deliveryAddressLabel),
            TextButton.icon(
              onPressed: () => _openMap(addr),
              icon: const Icon(Icons.map_outlined, size: 16),
              label: Text(l10n.openMap),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BabkaColors.surface,
            borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
            border: Border.all(color: BabkaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(addr['label'] ?? l10n.home, style: BabkaTypography.title(context).copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Text(addr['address'] ?? '', style: BabkaTypography.bodyMedium(context)),
              const SizedBox(height: 8),
              _buildAddressLine(l10n.city, '${addr['city']}, ${addr['district']}'),
              _buildAddressLine(l10n.street, addr['street'] ?? '-'),
              _buildAddressLine(l10n.building, 'No: ${addr['building_number'] ?? '-'} • ${l10n.floor}: ${addr['floor'] ?? '-'} • ${l10n.door}: ${addr['door_number'] ?? '-'}'),
              if (addr['delivery_note'] != null && addr['delivery_note'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BabkaColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note_alt_outlined, size: 16, color: BabkaColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          addr['delivery_note'],
                          style: BabkaTypography.bodySmall(context).copyWith(color: BabkaColors.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text('$label: ', style: BabkaTypography.caption(context)),
          Text(value, style: BabkaTypography.bodySmall(context).copyWith(color: BabkaColors.ink)),
        ],
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, OrderModel order, String lang, AppLocalizations l10n) {
    final items = order.items ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.orderItemsLabel),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
                  child: CachedNetworkImage(
                    imageUrl: item.imageSnapshot,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.localizedName(lang), style: BabkaTypography.title(context).copyWith(fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: BabkaColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: BabkaColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  BabkaNumberFormatter.formatCurrency(item.priceAtPurchase * item.quantity, lang),
                  style: BabkaTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.deliveryFeeLabel, style: BabkaTypography.bodySmall(context)),
            Consumer(builder: (context, ref, _) {
              final options = ref.watch(appOptionsProvider).value ?? {};
              final fee = double.tryParse(options['delivery_fee']?.toString() ?? '0') ?? 0.0;
              return Text(
                BabkaNumberFormatter.formatCurrency(fee, lang),
                style: BabkaTypography.bodySmall(context).copyWith(fontWeight: FontWeight.bold),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, OrderModel order, String lang, AppLocalizations l10n) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.paymentMethod, style: BabkaTypography.bodyMedium(context)),
            Text(order.paymentMethod.toUpperCase(), style: BabkaTypography.title(context).copyWith(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.grandTotal, style: BabkaTypography.h3(context)),
            Text(
              BabkaNumberFormatter.formatCurrency(order.totalPrice, lang),
              style: BabkaTypography.h3(context).copyWith(color: BabkaColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, OrderModel order, AppLocalizations l10n) {
    bool canCancel = order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled;
    
    Widget? mainAction;
    switch (order.status) {
      case OrderStatus.pending:
        mainAction = Expanded(
          child: BabkaButton.primary(
            label: l10n.acceptAndConfirm,
            onPressed: () => _updateStatus(OrderStatus.confirmed),
            isLoading: _isUpdating,
          ),
        );
        break;
      case OrderStatus.confirmed:
        mainAction = Expanded(
          child: BabkaButton.primary(
            label: l10n.startPreparing,
            backgroundColor: BabkaColors.info,
            onPressed: () => _updateStatus(OrderStatus.preparing),
            isLoading: _isUpdating,
          ),
        );
        break;
      case OrderStatus.preparing:
        mainAction = Expanded(
          child: BabkaButton.primary(
            label: l10n.markAsReady,
            backgroundColor: BabkaColors.success,
            onPressed: () => _updateStatus(OrderStatus.ready),
            isLoading: _isUpdating,
          ),
        );
        break;
      case OrderStatus.ready:
        mainAction = Expanded(
          child: BabkaButton.primary(
            label: l10n.assignToDelivery,
            icon: Icons.person_search_rounded,
            backgroundColor: BabkaColors.primary,
            onPressed: () => _showDeliveryPicker(context, l10n),
            isLoading: _isUpdating,
          ),
        );
        break;
      case OrderStatus.outForDelivery:
        mainAction = Expanded(
          child: BabkaButton.outlined(
            label: l10n.outForDelivery,
            onPressed: null,
            foregroundColor: BabkaColors.primary,
          ),
        );
        break;
      case OrderStatus.delivered:
        mainAction = Expanded(
          child: BabkaButton.outlined(
            label: l10n.statusDelivered,
            onPressed: null,
            foregroundColor: BabkaColors.success,
          ),
        );
        break;
      default:
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
            if (canCancel) ...[
              SizedBox(
                width: 56,
                height: 56,
                child: BabkaButton.outlined(
                  label: '',
                  icon: Icons.cancel_outlined,
                  foregroundColor: BabkaColors.error,
                  borderColor: BabkaColors.error,
                  onPressed: () => CancelOrderDialog.show(
                    context, 
                    onConfirm: (reason) => _cancelOrder(reason),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            mainAction,
          ],
        ),
      ),
    );
  }

  void _showDeliveryPicker(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalContext) => Consumer(builder: (context, ref, _) {
        final staffAsync = ref.watch(deliveryStaffProvider);
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.confirmPickup, style: BabkaTypography.h3(context)),
              const SizedBox(height: 24),
              staffAsync.when(
                data: (staff) {
                   if (staff.isEmpty) {
                     return Padding(
                       padding: const EdgeInsets.symmetric(vertical: 32),
                       child: Column(
                         children: [
                           const Icon(Icons.person_off_outlined, size: 48, color: BabkaColors.inkLight),
                           const SizedBox(height: 16),
                           Text(l10n.noDeliveryPersonFound, style: BabkaTypography.bodyMedium(context)),
                         ],
                       ),
                     );
                   }
                   return Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: staff.length,
                      itemBuilder: (context, index) {
                        final s = staff[index];
                        return ListTile(
                          leading: const Icon(Icons.delivery_dining_outlined),
                          title: Text(s['full_name'] ?? l10n.driver),
                          subtitle: Text(s['email'] ?? ''),
                          onTap: () async {
                            setState(() => _isUpdating = true);
                            try {
                              // 1. Assign in database
                              await ref.read(sangakOrderRepositoryProvider).assignDeliveryPerson(widget.orderId, s['id']);
                              
                              // 2. Update status to 'out_for_delivery' (matching existing workflow)
                              await ref.read(sangakOrderRepositoryProvider).updateOrderStatus(
                                orderId: widget.orderId,
                                status: OrderStatus.outForDelivery,
                                changedBy: ref.read(authProvider).asData!.value!.id,
                              );
                              
                              if (mounted && modalContext.mounted) {
                                // 3. Close modal only after success
                                Navigator.pop(modalContext);
                                
                                // 4. Show success toast (using existing keys or newly added if possible)
                                // For now, stick to the clear confirmation requested
                                BabkaToast.show(this.context, l10n.orderAssignedSuccessfully);
                              }
                              ref.invalidate(adminOrderDetailProvider(widget.orderId));
                            } catch (e) {
                              debugPrint('Error assigning delivery person: $e');
                              if (mounted) {
                                BabkaToast.show(
                                  this.context, 
                                  l10n.errorOccurred, 
                                  icon: Icons.error_outline_rounded,
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isUpdating = false);
                            }
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text(l10n.errorLoadingStaff),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: BabkaTypography.caption(context).copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pending:
        color = BabkaColors.warning;
        label = l10n.statusPending.toUpperCase();
        break;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        color = BabkaColors.info;
        label = l10n.statusPreparing.toUpperCase();
        break;
      case OrderStatus.ready:
        color = BabkaColors.accent;
        label = l10n.statusReady.toUpperCase();
        break;
      case OrderStatus.outForDelivery:
        color = BabkaColors.primary;
        label = l10n.outForDelivery.toUpperCase();
        break;
      case OrderStatus.delivered:
        color = BabkaColors.success;
        label = l10n.statusDelivered.toUpperCase();
        break;
      case OrderStatus.cancelled:
        color = BabkaColors.error;
        label = l10n.statusCancelled.toUpperCase();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: BabkaTypography.caption(context).copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
