import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../../core/design_system/sangak_colors.dart';
import '../../../core/design_system/sangak_typography.dart';
import '../../../shared/widgets/sangak_button.dart';
import '../../../shared/widgets/sangak_text_field.dart';
import '../../../shared/utils/sangak_toast.dart';
import '../../../services/rating_repository.dart';
import '../../../models/order_rating.dart';
import '../../../services/loyalty_repository.dart';
import '../../../services/options_repository.dart';
import '../../auth/auth_provider.dart';
import '../../loyalty/loyalty_provider.dart';
import '../orders_provider.dart';

class OrderRatingDialog extends ConsumerStatefulWidget {
  final String orderId;
  const OrderRatingDialog({super.key, required this.orderId});

  @override
  ConsumerState<OrderRatingDialog> createState() => _OrderRatingDialogState();
}

class _OrderRatingDialogState extends ConsumerState<OrderRatingDialog> {
  int _quality = 5;
  int _freshness = 5;
  int _packaging = 5;
  int _delivery = 5;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final int overallRating = ((_quality + _freshness + _packaging + _delivery) / 4).round();

      final rating = OrderRating(
        id: '', 
        userId: user.id,
        orderId: widget.orderId,
        overallRating: overallRating,
        qualityRating: _quality,
        freshnessRating: _freshness,
        packagingRating: _packaging,
        deliveryRating: _delivery,
        reviewText: _reviewController.text,
        createdAt: DateTime.now(),
      );

      await ref.read(ratingRepositoryProvider).submitRating(rating);
      
      final options = await ref.read(optionsRepositoryProvider).getOptions();
      final pointsForReview = int.tryParse(options['points_per_review']?.toString() ?? '10') ?? 10;
      
      await ref.read(loyaltyRepositoryProvider).awardPoints(
        userId: user.id,
        amount: pointsForReview,
        reason: 'Order Review',
        type: 'earn',
        relatedId: widget.orderId,
      );

      ref.invalidate(userLoyaltyProvider);
      ref.invalidate(pointsHistoryProvider);
      ref.invalidate(isOrderRatedProvider(widget.orderId));

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.pop(context);
        BabkaToast.show(context, l10n.feedbackThankYou(pointsForReview));
      }
    } catch (e) {
      if (mounted) BabkaToast.show(context, '${AppLocalizations.of(context).errorOccurred}: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.rateExperience, style: BabkaTypography.h2(context)),
              const SizedBox(height: 8),
              Text(l10n.rateOrderMessage, style: BabkaTypography.bodySmall(context)),
              const SizedBox(height: 24),
              
              _buildStarRating(l10n.breadQuality, _quality, (v) => setState(() => _quality = v)),
              _buildStarRating(l10n.freshness, _freshness, (v) => setState(() => _freshness = v)),
              _buildStarRating(l10n.packaging, _packaging, (v) => setState(() => _packaging = v)),
              _buildStarRating(l10n.deliveryService, _delivery, (v) => setState(() => _delivery = v)),
              
              const SizedBox(height: 24),
              BabkaTextField(
                label: l10n.writtenReview,
                controller: _reviewController,
                maxLines: 3,
                hintText: l10n.reviewHint,
              ),
              const SizedBox(height: 32),
              BabkaButton.primary(
                label: l10n.confirmButton,
                onPressed: _submit,
                isLoading: _isSubmitting,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: BabkaTypography.bodyMedium(context)),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => onChanged(index + 1),
                child: Icon(
                  index < value ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: BabkaColors.primary,
                  size: 28,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
