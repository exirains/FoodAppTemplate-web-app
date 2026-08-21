import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/sangak_dimens.dart';
import '../../../core/design_system/sangak_colors.dart';
import '../../../core/design_system/sangak_typography.dart';
import '../../../models/bread.dart';
import '../../../models/basket_item.dart';
import '../../../shared/widgets/sangak_button.dart';
import '../../../shared/widgets/sangak_app_bar.dart';
import '../providers/custom_sangak_provider.dart';
import '../widgets/sangak_preview.dart';
import '../widgets/customization_controls.dart';
import '../data/sangak_customization_options.dart';
import '../../../models/sangak_customization.dart';
import '../../basket/basket_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/localization/sangak_number_formatter.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../services/options_repository.dart';

class CustomSangakPage extends ConsumerStatefulWidget {
  final Bread initialBread;

  const CustomSangakPage({
    super.key,
    required this.initialBread,
  });

  @override
  ConsumerState<CustomSangakPage> createState() => _CustomSangakPageState();
}

class _CustomSangakPageState extends ConsumerState<CustomSangakPage> {
  late Bread _currentBaseBread;

  @override
  void initState() {
    super.initState();
    _currentBaseBread = widget.initialBread;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customization = ref.watch(customSangakProvider(_currentBaseBread));
    
    final optionsAsync = ref.watch(appOptionsProvider);
    final isEnabled = optionsAsync.value?['custom_sangak_enabled'] == true || 
                     optionsAsync.value?['custom_sangak_enabled'] == 'true';

    if (!isEnabled) {
      return Scaffold(
        appBar: SangakAppBar(
          title: l10n.appName,
          showBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 64, color: SangakColors.inkLight),
              const SizedBox(height: 16),
              Text(
                l10n.comingSoon,
                style: SangakTypography.h2(context),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  l10n.featureUnavailable,
                  style: SangakTypography.bodyMedium(context).copyWith(color: SangakColors.inkLight),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: SangakAppBar(
        title: l10n.appName,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(SangakDimens.spacing24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.buildYourSangak,
                        style: SangakTypography.h1(context),
                      ),
                      const SizedBox(height: SangakDimens.spacing24),
                      SangakPreview(baseBread: _currentBaseBread),
                      const SizedBox(height: SangakDimens.spacing32),
                      
                      // Base Selection
                      CustomizationSection(
                        title: l10n.base,
                        children: [
                          SizedBox(
                            height: 120,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: SangakDimens.spacing24),
                              children: [
                                BaseSelectionCard(
                                  bread: widget.initialBread,
                                  isSelected: _currentBaseBread.id == widget.initialBread.id,
                                  onTap: () => setState(() => _currentBaseBread = widget.initialBread),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Seeds
                      CustomizationSection(
                        title: l10n.seeds,
                        children: sangakCustomizationOptions
                            .where((o) => o.category == CustomizationCategory.seeds)
                            .map((o) => CustomizationOptionRow(
                                  baseBread: _currentBaseBread,
                                  option: o,
                                ))
                            .toList(),
                      ),

                      // Extras
                      CustomizationSection(
                        title: l10n.extras,
                        children: sangakCustomizationOptions
                            .where((o) => o.category == CustomizationCategory.extras)
                            .map((o) => CustomizationOptionRow(
                                  baseBread: _currentBaseBread,
                                  option: o,
                                ))
                            .toList(),
                      ),
                      
                      const SizedBox(height: 120), // Bottom bar spacer
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Bottom Price Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _PriceBottomBar(
              baseBread: _currentBaseBread,
              customization: customization,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBottomBar extends ConsumerWidget {
  final Bread baseBread;
  final SangakCustomization customization;

  const _PriceBottomBar({
    required this.baseBread,
    required this.customization,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = ref.watch(localeProvider).languageCode;
    
    return Container(
      padding: EdgeInsets.only(
        left: SangakDimens.spacing24,
        right: SangakDimens.spacing24,
        top: SangakDimens.spacing16,
        bottom: SangakDimens.spacing16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        boxShadow: [
          BoxShadow(
            color: SangakColors.ink.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.total,
                style: SangakTypography.bodySmall(context),
              ),
              Text(
                SangakNumberFormatter.formatCurrency(customization.totalPrice, languageCode),
                style: SangakTypography.h2(context).copyWith(color: SangakColors.primary),
              ),
            ],
          ),
          const SizedBox(width: SangakDimens.spacing24),
          Expanded(
            child: SangakButton.primary(
              label: l10n.addToBasket,
              onPressed: () {
                final basketItem = BasketItem(
                  bread: baseBread,
                  quantity: 1,
                  customization: customization,
                );
                
                ref.read(basketProvider.notifier).addItemWithCustomization(basketItem);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.addedCustomSangak)),
                );
                context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
