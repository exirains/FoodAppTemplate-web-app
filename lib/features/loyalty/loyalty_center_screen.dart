import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../core/design_system/babka_dimens.dart';
import '../../shared/widgets/babka_button.dart';
import '../../shared/utils/babka_toast.dart';
import '../../shared/widgets/babka_dialogs.dart';
import '../auth/profile_provider.dart';
import 'loyalty_provider.dart';
import '../../models/reward.dart';
import '../../services/loyalty_repository.dart';
import '../profile/widgets/referral_section.dart';

class LoyaltyCenterScreen extends ConsumerWidget {
  const LoyaltyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final loyaltyAsync = ref.watch(userLoyaltyProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final rewardsAsync = ref.watch(availableRewardsProvider);
    final historyAsync = ref.watch(pointsHistoryProvider);

    return Scaffold(
      backgroundColor: BabkaColors.background,
      appBar: AppBar(
        title: Text(l10n.loyaltyCenter),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userLoyaltyProvider);
          ref.invalidate(pointsHistoryProvider);
          ref.invalidate(availableRewardsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(BabkaDimens.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPointsHeader(context, loyaltyAsync, profileAsync, l10n),
              const SizedBox(height: 16),
              _buildDisclaimer(context, l10n),
              const SizedBox(height: 24),
              
              _buildProgressSection(context, loyaltyAsync, l10n),
              const SizedBox(height: 40),

              const ReferralSection(),
              const SizedBox(height: 40),

              Text(l10n.rewards, style: BabkaTypography.h3(context)),
              const SizedBox(height: 16),
              _buildRewardsGrid(context, ref, rewardsAsync, loyaltyAsync, l10n),
              
              const SizedBox(height: 40),
              Text(l10n.activity, style: BabkaTypography.h3(context)),
              const SizedBox(height: 16),
              _buildHistoryList(context, historyAsync, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsHeader(BuildContext context, AsyncValue loyaltyAsync, AsyncValue profileAsync, AppLocalizations l10n) {
    return loyaltyAsync.when(
      data: (loyalty) {
        final profile = profileAsync.asData?.value;
        final points = loyalty?.currentPoints ?? 0;
        final streak = profile?.currentStreak ?? 0;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [BabkaColors.ink, BabkaColors.ink.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: BabkaDimens.shadowMedium,
          ),
          child: Column(
            children: [
              Text(
                '🥖 ${l10n.loyaltyCenter}'.toUpperCase(),
                style: BabkaTypography.caption(context).copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '$points',
                style: BabkaTypography.display(context).copyWith(color: Colors.white, fontSize: 48),
              ),
              Text(
                l10n.points,
                style: BabkaTypography.bodySmall(context).copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeaderBadge(context, '🔥 ${l10n.streakDay(streak)}'),
                  const SizedBox(width: 12),
                  _buildHeaderBadge(context, '🏅 ${l10n.memberLevel(loyalty?.loyaltyLevel ?? "Bronze")}'),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildHeaderBadge(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: BabkaTypography.caption(context).copyWith(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, AsyncValue loyaltyAsync, AppLocalizations l10n) {
    return loyaltyAsync.when(
      data: (loyalty) {
        final points = loyalty?.currentPoints ?? 0;
        final level = loyalty?.loyaltyLevel ?? 'Bronze';
        
        int nextLevelPoints = 500;
        String nextLevel = 'Silver';
        
        if (level == 'Silver') {
          nextLevelPoints = 1500;
          nextLevel = 'Gold';
        } else if (level == 'Gold') {
          return const SizedBox.shrink(); // Max level
        }
        
        final progress = (points / nextLevelPoints).clamp(0.0, 1.0);
        final remaining = nextLevelPoints - points;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.memberLevel(level), style: BabkaTypography.title(context)),
                Text('$points / $nextLevelPoints', style: BabkaTypography.bodySmall(context)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: BabkaColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(BabkaColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.pointsUntilLevel(remaining, nextLevel),
              style: BabkaTypography.caption(context).copyWith(color: BabkaColors.inkLight),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildRewardsGrid(BuildContext context, WidgetRef ref, AsyncValue rewardsAsync, AsyncValue loyaltyAsync, AppLocalizations l10n) {
    return rewardsAsync.when(
      data: (rewards) {
        if (rewards.isEmpty) return Center(child: Text(l10n.noProductsFound));
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            final reward = rewards[index];
            final userPoints = loyaltyAsync.asData?.value?.currentPoints ?? 0;
            final canAfford = userPoints >= reward.pointsCost;
            
            return _RewardCard(reward: reward, canAfford: canAfford);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildDisclaimer(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BabkaColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BabkaColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: BabkaColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.loyaltySystemDisclaimer,
              style: BabkaTypography.bodySmall(context).copyWith(
                color: BabkaColors.ink,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, AsyncValue historyAsync, AppLocalizations l10n) {
    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) return Center(child: Text(l10n.noOrdersYet));
        
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final tx = history[index];
            final isEarn = tx.type == 'earn';
            
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isEarn ? Colors.green : BabkaColors.error).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEarn ? Icons.add_rounded : Icons.remove_rounded,
                  color: isEarn ? Colors.green : BabkaColors.error,
                  size: 20,
                ),
              ),
              title: Text(tx.reason, style: BabkaTypography.title(context).copyWith(fontSize: 14)),
              subtitle: Text(
                '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                style: BabkaTypography.caption(context),
              ),
              trailing: Text(
                '${isEarn ? "+" : ""}${tx.amount}',
                style: BabkaTypography.title(context).copyWith(
                  color: isEarn ? Colors.green : BabkaColors.error,
                ),
              ),
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _RewardCard extends ConsumerWidget {
  final Reward reward;
  final bool canAfford;

  const _RewardCard({required this.reward, required this.canAfford});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: BabkaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BabkaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: BabkaColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Icon(Icons.card_giftcard_rounded, size: 40, color: BabkaColors.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: BabkaTypography.title(context).copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${reward.pointsCost} ${l10n.pts}', style: BabkaTypography.caption(context).copyWith(color: BabkaColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                BabkaButton.primary(
                  label: l10n.redeem,
                  onPressed: canAfford ? () => _redeem(context, ref, l10n) : null,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _redeem(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final user = ref.read(userProfileProvider).asData?.value;
    if (user == null) return;

    BabkaConfirmDialog.show(
      context,
      title: l10n.redeemReward,
      message: l10n.confirmRedeem(reward.pointsCost, reward.title),
      confirmLabel: l10n.redeem,
      cancelLabel: l10n.cancel,
      onConfirm: () async {
        try {
          await ref.read(loyaltyRepositoryProvider).redeemReward(
            userId: user.id,
            rewardId: reward.id,
            cost: reward.pointsCost,
            rewardTitle: reward.title,
          );
          ref.invalidate(userLoyaltyProvider);
          ref.invalidate(pointsHistoryProvider);
          if (context.mounted) BabkaToast.show(context, l10n.rewardRedeemed);
        } catch (e) {
          if (context.mounted) BabkaToast.show(context, '${l10n.errorOccurred}: $e');
        }
      },
    );
  }
}

