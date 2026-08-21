import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/design_system/sangak_colors.dart';
import '../../../core/design_system/sangak_typography.dart';
import '../../../core/design_system/sangak_dimens.dart';
import '../../../shared/utils/sangak_toast.dart';
import '../../../models/referral.dart';
import '../referral_provider.dart';

class ReferralSection extends ConsumerWidget {
  const ReferralSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final referralCodeAsync = ref.watch(userReferralCodeProvider);
    final statsAsync = ref.watch(referralStatsProvider);

    return referralCodeAsync.when(
      data: (referralCode) {
        if (referralCode == null) return const SizedBox.shrink();
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showReferralDetails(context, referralCode.code, statsAsync, l10n),
            borderRadius: BorderRadius.circular(SangakDimens.radiusM),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SangakColors.surface,
                borderRadius: BorderRadius.circular(SangakDimens.radiusM),
                border: Border.all(color: SangakColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SangakColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard_rounded, color: SangakColors.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.referralSystemTitle, style: SangakTypography.title(context).copyWith(fontSize: 16)),
                        Text(
                          l10n.referralSystemDesc,
                          style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.inkLight),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl 
                        ? Icons.chevron_left 
                        : Icons.chevron_right, 
                    color: SangakColors.inkLight, 
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  void _showReferralDetails(BuildContext context, String code, AsyncValue<Map<String, dynamic>> statsAsync, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ReferralDetailsSheet(code: code),
    );
  }
}

class _ReferralDetailsSheet extends ConsumerWidget {
  final String code;
  const _ReferralDetailsSheet({required this.code});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(referralStatsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: SangakColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: SangakDimens.spacing32,
        right: SangakDimens.spacing32,
        top: SangakDimens.spacing32,
        bottom: MediaQuery.of(context).padding.bottom + SangakDimens.spacing32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: SangakColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(l10n.referralSystemTitle, style: SangakTypography.h2(context)),
            const SizedBox(height: 12),
            Text(l10n.referralSystemDesc, textAlign: TextAlign.center, style: SangakTypography.bodyMedium(context)),
            const SizedBox(height: 32),
            _buildCodeDisplay(context, code, l10n),
            const SizedBox(height: 32),
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  _buildStatsGrid(context, stats, l10n),
                  const SizedBox(height: 32),
                  _buildHistorySection(context, (stats['referrals'] as List<Referral>?) ?? [], l10n),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(),
              ),
              error: (e, s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l10n.errorOccurred),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, List<Referral> referrals, AppLocalizations l10n) {
    if (referrals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.referralStats, style: SangakTypography.title(context)),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: referrals.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final referral = referrals[index];
            final isRewarded = referral.status == ReferralStatus.rewarded;
            
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isRewarded ? Colors.green : SangakColors.inkLight).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRewarded ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
                  color: isRewarded ? Colors.green : SangakColors.inkLight,
                  size: 20,
                ),
              ),
              title: Text(
                referral.referredUserName ?? 'New User',
                style: SangakTypography.title(context).copyWith(fontSize: 14),
              ),
              subtitle: Text(
                '${referral.createdAt.day}/${referral.createdAt.month}/${referral.createdAt.year}',
                style: SangakTypography.caption(context),
              ),
              trailing: Text(
                isRewarded ? l10n.referralStatusRewarded : l10n.referralStatusPending,
                style: SangakTypography.bodySmall(context).copyWith(
                  color: isRewarded ? Colors.green : SangakColors.inkLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCodeDisplay(BuildContext context, String code, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: SangakColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(SangakDimens.radiusM),
        border: Border.all(color: SangakColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(l10n.invitationCodeLabel, style: SangakTypography.caption(context)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(code, style: SangakTypography.h2(context).copyWith(color: SangakColors.primary, letterSpacing: 4)),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: SangakColors.primary),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  SangakToast.show(context, l10n.copySuccess);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            // ignore: deprecated_member_use
            onPressed: () => Share.share(l10n.inviteFriendMessage(code)),
            icon: const Icon(Icons.share_rounded),
            label: Text(l10n.shareCode),
            style: ElevatedButton.styleFrom(
              backgroundColor: SangakColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SangakDimens.radiusM)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatBox(context, stats['totalInvited'].toString(), l10n.friendsInvited),
        _buildStatBox(context, stats['successfulReferrals'].toString(), l10n.successfulReferrals),
        _buildStatBox(context, stats['totalPointsEarned'].toString(), l10n.referralPoints),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: SangakTypography.h3(context)),
        const SizedBox(height: 4),
        Text(label, style: SangakTypography.caption(context), textAlign: TextAlign.center),
      ],
    );
  }
}
