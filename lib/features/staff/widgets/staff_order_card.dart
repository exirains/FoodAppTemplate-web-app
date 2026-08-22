import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../../core/design_system/sangak_colors.dart';
import '../../../core/design_system/sangak_typography.dart';
import '../../../core/design_system/sangak_dimens.dart';
import '../../../models/order.dart';
import '../../../shared/widgets/sangak_button.dart';
import '../../../shared/utils/sangak_toast.dart';
import '../../../shared/widgets/cancel_order_dialog.dart';
import '../../auth/auth_provider.dart';
import '../../admin/admin_provider.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/sangak_number_formatter.dart';

class StaffOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final bool isNew;

  const StaffOrderCard({
    super.key,
    required this.order,
    this.isNew = false,
  });

  @override
  ConsumerState<StaffOrderCard> createState() => _StaffOrderCardState();
}

class _StaffOrderCardState extends ConsumerState<StaffOrderCard> {
  bool _isUpdating = false;

  Future<void> _updateStatus(OrderStatus newStatus) async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) return;
    
    // Guardrail: Staff can only set these specific statuses
    final allowedStatuses = [
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.cancelled,
    ];

    if (!allowedStatuses.contains(newStatus)) {
      if (mounted) SangakToast.show(context, 'Unauthorized status change', icon: Icons.error_outline);
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final l10n = AppLocalizations.of(context);
      await ref.read(sangakOrderRepositoryProvider).updateOrderStatus(
            orderId: widget.order.id,
            status: newStatus,
            changedBy: user.id,
            role: 'staff',
          );
      
      if (mounted) {
        SangakToast.show(context, '${l10n.status}: ${newStatus.localizedLabel(l10n)}');
      }
    } catch (e) {
      if (mounted) SangakToast.show(context, 'Error updating status', icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider).languageCode;
    final items = widget.order.items ?? [];
    final isWide = MediaQuery.of(context).size.width > 600;
    
    // Highly Optimized Proportions
    final padding = isWide ? 12.0 : 16.0;
    final actionHeight = isWide ? 40.0 : 48.0;
    final titleSize = isWide ? 14.0 : 16.0;
    final itemTitleSize = isWide ? 12.0 : 14.0;
    final thumbnailSize = isWide ? 28.0 : 32.0;

    Widget card = Container(
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowMedium,
        border: Border.all(
          color: widget.isNew ? SangakColors.warning : SangakColors.border,
          width: widget.isNew ? 3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ALLOW DYNAMIC HEIGHT
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(padding, padding, padding, padding * 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Localizations.override(
                      context: context,
                      locale: const Locale('en', 'US'),
                      child: Text(
                        widget.order.orderNumber,
                        style: SangakTypography.h2(context).copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: titleSize,
                        ),
                      ),
                    ),
                    if (widget.isNew)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: SangakColors.warning,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.newLabel.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(widget.order.createdAt, l10n),
                      style: SangakTypography.h3(context).copyWith(
                        color: SangakColors.primary,
                        fontSize: isWide ? 16 : 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      SangakNumberFormatter.formatCurrency(widget.order.totalPrice, lang),
                      style: SangakTypography.bodySmall(context).copyWith(fontWeight: FontWeight.bold, color: SangakColors.ink),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Items
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: item.imageSnapshot,
                        width: thumbnailSize,
                        height: thumbnailSize,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: thumbnailSize,
                          height: thumbnailSize,
                          color: SangakColors.border, 
                          child: Icon(Icons.breakfast_dining, size: thumbnailSize * 0.5, color: SangakColors.inkLight),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: SangakColors.ink.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: SangakTypography.title(context).copyWith(
                          color: SangakColors.ink,
                          fontWeight: FontWeight.bold,
                          fontSize: isWide ? 12 : 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.localizedName(lang),
                        style: SangakTypography.h3(context).copyWith(
                          fontSize: itemTitleSize,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          
          // Rich Footer
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _FooterBadge(
                      icon: widget.order.addressSnapshot['type'] == 'pickup' ? Icons.store_outlined : Icons.delivery_dining_outlined,
                      label: widget.order.addressSnapshot['type'] == 'pickup' ? 'Pick-up' : 'Delivery',
                      color: SangakColors.primary,
                    ),
                    const SizedBox(width: 4),
                    _FooterBadge(
                      icon: Icons.payments_outlined,
                      label: widget.order.paymentMethod == 'cash' ? 'Cash' : 'Paid',
                      color: widget.order.paymentMethod == 'cash' ? SangakColors.warning : SangakColors.success,
                    ),
                    if (widget.order.deliveryProfile != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: _FooterBadge(
                          icon: Icons.person_outline,
                          label: widget.order.deliveryProfile!['full_name'] ?? 'Courier',
                          color: SangakColors.info,
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.order.addressSnapshot['note']?.toString().isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_outlined, size: 14, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.order.addressSnapshot['note'],
                            style: SangakTypography.caption(context).copyWith(fontStyle: FontStyle.italic, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (widget.order.status != OrderStatus.delivered && widget.order.status != OrderStatus.cancelled) ...[
            const Divider(height: 1),
            
            // Actions
            Padding(
              padding: EdgeInsets.fromLTRB(padding, padding * 0.5, padding, padding),
              child: Row(
                children: [
                  // Quick Cancel
                  SizedBox(
                    width: actionHeight,
                    height: actionHeight,
                    child: SangakButton.outlined(
                      label: '',
                      icon: Icons.close_rounded,
                      foregroundColor: SangakColors.error,
                      borderColor: SangakColors.error,
                      onPressed: () => CancelOrderDialog.show(
                        context,
                        onConfirm: (reason) => _updateStatus(OrderStatus.cancelled),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Primary Action
                  Expanded(
                    child: SizedBox(
                      height: actionHeight,
                      child: _buildActionButton(l10n),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.isNew) {
      return card.animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      ).shimmer(
        duration: 2.seconds,
        // ignore: deprecated_member_use
        color: SangakColors.warning.withOpacity(0.1),
      ).boxShadow(
        begin: BoxShadow(color: SangakColors.warning.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
        end: BoxShadow(color: SangakColors.warning.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5),
        duration: 1.seconds,
        curve: Curves.easeInOut,
      );
    }

    return card;
  }

  Widget _buildActionButton(AppLocalizations l10n) {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return SangakButton.primary(
          label: l10n.acceptOrder.toUpperCase(),
          onPressed: () => _updateStatus(OrderStatus.confirmed),
          isLoading: _isUpdating,
        );
      case OrderStatus.confirmed:
        return SangakButton.primary(
          label: l10n.startPreparing.toUpperCase(),
          backgroundColor: SangakColors.info,
          onPressed: () => _updateStatus(OrderStatus.preparing),
          isLoading: _isUpdating,
        );
      case OrderStatus.preparing:
        return SangakButton.primary(
          label: l10n.markReady.toUpperCase(),
          backgroundColor: SangakColors.success,
          onPressed: () => _updateStatus(OrderStatus.ready),
          isLoading: _isUpdating,
        );
      case OrderStatus.ready:
        return SangakButton.outlined(
          label: l10n.waitingForPickup.toUpperCase(),
          onPressed: null,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatTime(DateTime date, AppLocalizations l10n) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}${l10n.minutesShort} ${l10n.ago}';
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _FooterBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FooterBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: SangakTypography.caption(context).copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
