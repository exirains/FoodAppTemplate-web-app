import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_text_field.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/widgets/role_guard.dart';
import '../../services/options_repository.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _minLimitController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _pointsPerCurrencyController = TextEditingController();
  final _pointsPerOrderController = TextEditingController();
  final _streakBonusController = TextEditingController();
  final _streakThresholdController = TextEditingController();
  String _pointsEarningRule = 'total_spent';
  bool _customizationEnabled = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _minLimitController.dispose();
    _deliveryFeeController.dispose();
    _pointsPerCurrencyController.dispose();
    _pointsPerOrderController.dispose();
    _streakBonusController.dispose();
    _streakThresholdController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);

    try {
      final updates = {
        'min_order_limit': int.tryParse(_minLimitController.text) ?? 200,
        'delivery_fee': double.tryParse(_deliveryFeeController.text) ?? 0.0,
        'points_per_currency': int.tryParse(_pointsPerCurrencyController.text) ?? 1,
        'points_per_order': int.tryParse(_pointsPerOrderController.text) ?? 10,
        'streak_bonus': int.tryParse(_streakBonusController.text) ?? 50,
        'streak_threshold': int.tryParse(_streakThresholdController.text) ?? 3,
        'points_earning_rule': _pointsEarningRule,
        'custom_sangak_enabled': _customizationEnabled,
      };

      await ref.read(optionsRepositoryProvider).updateOptions(updates);
      
      if (mounted) {
        SangakToast.show(context, l10n.settingsSaved);
      }
    } catch (e) {
      if (mounted) {
        SangakToast.show(context, '${l10n.errorOccurred}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final optionsAsync = ref.watch(appOptionsProvider);

    return RoleGuard(
      allowedRoles: const ['admin'],
      child: Scaffold(
        backgroundColor: SangakColors.background,
        appBar: AppBar(
          title: Text(l10n.adminSettings),
        ),
        body: optionsAsync.when(
          data: (options) {
            // Only set initial values once or when they change from external source
            if (_minLimitController.text.isEmpty && options.containsKey('min_order_limit')) {
              _minLimitController.text = options['min_order_limit'].toString();
            }
            if (_deliveryFeeController.text.isEmpty && options.containsKey('delivery_fee')) {
              _deliveryFeeController.text = options['delivery_fee'].toString();
            }
            if (_pointsPerCurrencyController.text.isEmpty && options.containsKey('points_per_currency')) {
              _pointsPerCurrencyController.text = options['points_per_currency'].toString();
            }
            if (_pointsPerOrderController.text.isEmpty && options.containsKey('points_per_order')) {
              _pointsPerOrderController.text = options['points_per_order'].toString();
            }
            if (_streakBonusController.text.isEmpty && options.containsKey('streak_bonus')) {
              _streakBonusController.text = options['streak_bonus'].toString();
            }
            if (_streakThresholdController.text.isEmpty && options.containsKey('streak_threshold')) {
              _streakThresholdController.text = options['streak_threshold'].toString();
            }
            if (options.containsKey('points_earning_rule')) {
              _pointsEarningRule = options['points_earning_rule'].toString();
            }
            if (options.containsKey('custom_sangak_enabled')) {
              _customizationEnabled = options['custom_sangak_enabled'] == true || options['custom_sangak_enabled'] == 'true';
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(SangakDimens.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminSettings,
                    style: SangakTypography.h2(context),
                  ),
                  const SizedBox(height: SangakDimens.spacing8),
                  Text(
                    l10n.changeSettingAnytime,
                    style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.inkLight),
                  ),
                  const SizedBox(height: SangakDimens.spacing32),
                  
                  _buildSectionTitle(context, l10n.deliveryFeeLabel),
                  SangakTextField(
                    label: l10n.minOrderLimitLabel,
                    controller: _minLimitController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    leadingIcon: Icons.shopping_cart_checkout_rounded,
                    hintText: '200',
                  ),
                  const SizedBox(height: SangakDimens.spacing24),
                  
                  SangakTextField(
                    label: l10n.deliveryFeeSettingLabel,
                    controller: _deliveryFeeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    leadingIcon: Icons.delivery_dining_rounded,
                    hintText: '0.0',
                  ),
                  
                  const SizedBox(height: SangakDimens.spacing32),
                  _buildSectionTitle(context, l10n.loyaltySettings),
                  
                  // Points Earning Rule Toggle
                  Text(
                    l10n.pointsEarningRule,
                    style: SangakTypography.title(context).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: SangakColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SangakColors.border),
                    ),
                    child: RadioGroup<String>(
                      groupValue: _pointsEarningRule,
                      onChanged: (v) => setState(() => _pointsEarningRule = v!),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Text(l10n.totalSpentRule),
                            subtitle: Text(l10n.totalSpentSubtitle),
                            value: 'total_spent',
                            activeColor: SangakColors.primary,
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: Text(l10n.fixedPointsRule),
                            subtitle: Text(l10n.pointsPerOrderLabel),
                            value: 'fixed',
                            activeColor: SangakColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_pointsEarningRule == 'total_spent')
                    SangakTextField(
                      label: l10n.pointsPerCurrencyLabel,
                      controller: _pointsPerCurrencyController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      leadingIcon: Icons.stars_rounded,
                      hintText: '1',
                    )
                  else
                    SangakTextField(
                      label: l10n.pointsPerOrderLabel,
                      controller: _pointsPerOrderController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      leadingIcon: Icons.add_task_rounded,
                      hintText: '10',
                    ),
                  
                  const SizedBox(height: SangakDimens.spacing24),

                  SangakTextField(
                    label: l10n.streakBonusLabel,
                    controller: _streakBonusController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    leadingIcon: Icons.bolt_rounded,
                    hintText: '50',
                  ),
                  const SizedBox(height: SangakDimens.spacing24),

                  SangakTextField(
                    label: l10n.streakThresholdLabel,
                    controller: _streakThresholdController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    leadingIcon: Icons.timer_rounded,
                    hintText: '3',
                  ),

                  const SizedBox(height: SangakDimens.spacing32),
                  _buildSectionTitle(context, l10n.customization),
                  _buildFeatureToggle(
                    l10n.customSangak,
                    l10n.customSangakDescription,
                    _customizationEnabled,
                    (v) => setState(() => _customizationEnabled = v),
                    context,
                  ),

                  const SizedBox(height: SangakDimens.spacing32),
                  SangakButton.outlined(
                    label: l10n.rewardsManagement,
                    onPressed: () => context.push('/admin/rewards'),
                    width: double.infinity,
                    icon: Icons.card_giftcard_rounded,
                  ),
                  
                  const SizedBox(height: SangakDimens.spacing48),
                  
                  SangakButton.primary(
                    label: l10n.save,
                    onPressed: _saveSettings,
                    isLoading: _isSaving,
                    width: double.infinity,
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.errorOccurred)),
        ),
      ),
    );
  }

  Widget _buildFeatureToggle(String title, String description, bool value, ValueChanged<bool> onChanged, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SangakColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: SangakTypography.title(context).copyWith(fontSize: 16)),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: SangakColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.inkLight)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SangakDimens.spacing16),
      child: Text(
        title.toUpperCase(),
        style: SangakTypography.bodySmall(context).copyWith(
          color: SangakColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
