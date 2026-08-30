import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_dimens.dart';
import '../../shared/widgets/babka_button.dart';
import '../../shared/widgets/babka_text_field.dart';
import '../../shared/utils/babka_toast.dart';
import '../../shared/widgets/role_guard.dart';
import '../../services/reward_repository.dart';
import '../../models/reward.dart';
import 'package:uuid/uuid.dart';

class RewardManagementScreen extends ConsumerStatefulWidget {
  const RewardManagementScreen({super.key});

  @override
  ConsumerState<RewardManagementScreen> createState() => _RewardManagementScreenState();
}

class _RewardManagementScreenState extends ConsumerState<RewardManagementScreen> {
  late Future<List<Reward>> _rewardsFuture;

  @override
  void initState() {
    super.initState();
    _refreshRewards();
  }

  void _refreshRewards() {
    setState(() {
      _rewardsFuture = ref.read(rewardRepositoryProvider).getActiveRewards();
    });
  }

  void _showRewardDialog([Reward? reward]) {
    showDialog(
      context: context,
      builder: (context) => RewardDialog(
        reward: reward,
        onSave: () {
          _refreshRewards();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return RoleGuard(
      allowedRoles: const ['admin'],
      child: Scaffold(
        backgroundColor: BabkaColors.background,
        appBar: AppBar(
          title: Text(l10n.rewardsManagement),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showRewardDialog(),
            ),
          ],
        ),
        body: FutureBuilder<List<Reward>>(
          future: _rewardsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(l10n.errorOccurred));
            }
            final rewards = snapshot.data ?? [];
            if (rewards.isEmpty) {
              return Center(child: Text(l10n.noRewards));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(BabkaDimens.spacing16),
              itemCount: rewards.length,
              separatorBuilder: (_, _) => const SizedBox(height: BabkaDimens.spacing12),
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return Card(
                  child: ListTile(
                    title: Text(reward.title),
                    subtitle: Text('${reward.pointsCost} ${l10n.pts} - ${reward.description}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: BabkaColors.primary),
                          onPressed: () => _showRewardDialog(reward),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: BabkaColors.error),
                          onPressed: () async {
                            await ref.read(rewardRepositoryProvider).deleteReward(reward.id);
                            _refreshRewards();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class RewardDialog extends ConsumerStatefulWidget {
  final Reward? reward;
  final VoidCallback onSave;

  const RewardDialog({super.key, this.reward, required this.onSave});

  @override
  ConsumerState<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends ConsumerState<RewardDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _pointsController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.reward != null) {
      _titleController.text = widget.reward!.title;
      _descController.text = widget.reward!.description;
      _pointsController.text = widget.reward!.pointsCost.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.reward == null ? l10n.addReward : l10n.editReward),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BabkaTextField(
              label: l10n.rewardTitle,
              controller: _titleController,
            ),
            const SizedBox(height: 16),
            BabkaTextField(
              label: l10n.description,
              controller: _descController,
            ),
            const SizedBox(height: 16),
            BabkaTextField(
              label: l10n.pointsCost,
              controller: _pointsController,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        BabkaButton.primary(
          label: l10n.save,
          isLoading: _isSaving,
          onPressed: () async {
            setState(() => _isSaving = true);
            try {
              final reward = Reward(
                id: widget.reward?.id ?? const Uuid().v4(),
                title: _titleController.text,
                description: _descController.text,
                pointsCost: int.parse(_pointsController.text),
                createdAt: widget.reward?.createdAt ?? DateTime.now(),
              );
              if (widget.reward == null) {
                await ref.read(rewardRepositoryProvider).addReward(reward);
              } else {
                await ref.read(rewardRepositoryProvider).updateReward(reward);
              }
              widget.onSave();
            } catch (e) {
              if (mounted && context.mounted) {
                BabkaToast.show(context, '${l10n.errorOccurred}: $e');
              }
            } finally {
              if (mounted) {
                setState(() => _isSaving = false);
              }
            }
          },
        ),
      ],
    );
  }
}

