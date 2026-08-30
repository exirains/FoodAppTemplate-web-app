import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../core/design_system/babka_dimens.dart';
import '../../core/localization/babka_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import '../../shared/widgets/babka_button.dart';
import '../../shared/widgets/babka_dialogs.dart';
import '../../shared/utils/babka_toast.dart';
import '../../services/rating_repository.dart';
import '../../models/order_rating.dart';
import '../../shared/widgets/role_guard.dart';

class ReviewManagementScreen extends ConsumerStatefulWidget {
  const ReviewManagementScreen({super.key});

  @override
  ConsumerState<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends ConsumerState<ReviewManagementScreen> {
  final _ratingsProvider = FutureProvider<List<OrderRating>>((ref) {
    return ref.read(ratingRepositoryProvider).getAllRatings();
  });

  @override
  Widget build(BuildContext context) {
    final ratingsAsync = ref.watch(_ratingsProvider);
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider).languageCode;

    return RoleGuard(
      allowedRoles: const ['admin'],
      child: Scaffold(
        backgroundColor: BabkaColors.background,
        appBar: AppBar(
          title: Text(l10n.reviewManagement),
        ),
        body: ratingsAsync.when(
          data: (ratings) => ratings.isEmpty
              ? Center(child: Text(l10n.noReviewsFound))
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(_ratingsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(BabkaDimens.spacing24),
                    itemCount: ratings.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final rating = ratings[index];
                      return _ReviewCard(
                        rating: rating,
                        lang: lang,
                        onApprove: () => _approveReview(rating.id),
                        onDelete: () => _deleteReview(rating.id),
                      );
                    },
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.errorOccurred)),
        ),
      ),
    );
  }

  Future<void> _approveReview(String ratingId) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(ratingRepositoryProvider).approveRating(ratingId);
      ref.invalidate(_ratingsProvider);
      if (mounted) BabkaToast.show(context, l10n.reviewApproved);
    } catch (e) {
      if (mounted) BabkaToast.show(context, '${l10n.errorOccurred}: $e');
    }
  }

  Future<void> _deleteReview(String ratingId) async {
    final l10n = AppLocalizations.of(context);
    BabkaConfirmDialog.show(
      context,
      title: l10n.deleteReview,
      message: l10n.confirmDeleteReview,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      onConfirm: () async {
        try {
          await ref.read(ratingRepositoryProvider).deleteRating(ratingId);
          ref.invalidate(_ratingsProvider);
          if (mounted) BabkaToast.show(context, l10n.reviewDeleted);
        } catch (e) {
          if (mounted) BabkaToast.show(context, '${l10n.errorOccurred}: $e');
        }
      },
      isDestructive: true,
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final OrderRating rating;
  final String lang;
  final VoidCallback onApprove;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.rating,
    required this.lang,
    required this.onApprove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BabkaColors.surface,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusXL),
        boxShadow: BabkaDimens.shadowMedium,
        border: Border.all(color: BabkaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rating.customer?['full_name'] ?? l10n.guest,
                    style: BabkaTypography.title(context).copyWith(fontSize: 16),
                  ),
                  Text(
                    l10n.orderIdLabel(rating.orderId.substring(0, 5).toUpperCase()),
                    style: BabkaTypography.caption(context),
                  ),
                ],
              ),
              _ApprovalBadge(isApproved: rating.isApproved),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${rating.overallRating}.0',
                style: BabkaTypography.h3(context).copyWith(fontSize: 18),
              ),
              const Spacer(),
              Text(
                BabkaNumberFormatter.format(
                  rating.createdAt.toString().substring(0, 10),
                  lang,
                ),
                style: BabkaTypography.caption(context),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildRatingRow(context, l10n.quality, rating.qualityRating),
          _buildRatingRow(context, l10n.freshness, rating.freshnessRating),
          _buildRatingRow(context, l10n.packaging, rating.packagingRating),
          _buildRatingRow(context, l10n.delivery, rating.deliveryRating),
          if (rating.reviewText != null && rating.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BabkaColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rating.reviewText!,
                style: BabkaTypography.bodySmall(context).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (!rating.isApproved)
                Expanded(
                  child: BabkaButton.primary(
                    label: l10n.approve,
                    onPressed: onApprove,
                  ),
                ),
              if (!rating.isApproved) const SizedBox(width: 12),
              Expanded(
                child: BabkaButton.outlined(
                  label: l10n.delete,
                  onPressed: onDelete,
                  foregroundColor: BabkaColors.error,
                  borderColor: BabkaColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(BuildContext context, String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: BabkaTypography.caption(context)),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: BabkaColors.primary,
                size: 14,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ApprovalBadge extends StatelessWidget {
  final bool isApproved;
  const _ApprovalBadge({required this.isApproved});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = isApproved ? BabkaColors.success : BabkaColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular( BabkaDimens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isApproved ? l10n.statusApprovedCaps : l10n.statusPendingCaps,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

