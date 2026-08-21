import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/sangak_dimens.dart';
import '../../../core/design_system/sangak_colors.dart';
import '../../../core/design_system/sangak_typography.dart';
import '../../../models/sangak_customization.dart';
import '../../../models/bread.dart';
import '../../../shared/widgets/quantity_selector.dart';
import '../providers/custom_sangak_provider.dart';
import '../../../core/localization/sangak_number_formatter.dart';
import '../../../core/localization/locale_provider.dart';

class CustomizationSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const CustomizationSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SangakDimens.spacing24),
          child: Text(
            title,
            style: SangakTypography.h3(context).copyWith(color: SangakColors.primary),
          ),
        ),
        const SizedBox(height: SangakDimens.spacing16),
        ...children,
        const SizedBox(height: SangakDimens.spacing32),
      ],
    );
  }
}

class CustomizationOptionRow extends ConsumerWidget {
  final Bread baseBread;
  final SangakCustomizationOption option;

  const CustomizationOptionRow({
    super.key,
    required this.baseBread,
    required this.option,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(customSangakProvider(baseBread));
    final quantity = customization.selectedOptions[option.id] ?? 0;
    final languageCode = ref.watch(localeProvider).languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SangakDimens.spacing24,
        vertical: SangakDimens.spacing8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.name,
                  style: SangakTypography.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (option.price > 0)
                  Text(
                    '+${SangakNumberFormatter.formatCurrency(option.price, languageCode)}',
                    style: SangakTypography.bodySmall(context).copyWith(
                      color: SangakColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          QuantitySelector(
            quantity: quantity,
            maxQuantity: option.maxQuantity,
            onIncrement: () {
              ref.read(customSangakProvider(baseBread).notifier)
                  .updateOption(option.id, quantity + 1);
            },
            onDecrement: () {
              ref.read(customSangakProvider(baseBread).notifier)
                  .updateOption(option.id, quantity - 1);
            },
          ),
        ],
      ),
    );
  }
}

class BaseSelectionCard extends StatelessWidget {
  final Bread bread;
  final bool isSelected;
  final VoidCallback onTap;

  const BaseSelectionCard({
    super.key,
    required this.bread,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: SangakDimens.spacing12),
        padding: const EdgeInsets.all(SangakDimens.spacing12),
        decoration: BoxDecoration(
          color: isSelected ? SangakColors.primary.withValues(alpha: 0.1) : SangakColors.surface,
          borderRadius: BorderRadius.circular(SangakDimens.radiusM),
          border: Border.all(
            color: isSelected ? SangakColors.primary : SangakColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(SangakDimens.radiusS),
              child: Image.network(
                bread.imageUrl,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 60,
                  width: 60,
                  color: SangakColors.border,
                  child: const Icon(Icons.bakery_dining, color: SangakColors.inkLight),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bread.name,
              style: SangakTypography.bodySmall(context).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? SangakColors.primary : SangakColors.ink,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
