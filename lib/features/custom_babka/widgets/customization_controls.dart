import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/babka_dimens.dart';
import '../../../core/design_system/babka_colors.dart';
import '../../../core/design_system/babka_typography.dart';
import '../../../models/babka_customization.dart';
import '../../../models/bread.dart';
import '../../../shared/widgets/quantity_selector.dart';
import '../providers/custom_babka_provider.dart';
import '../../../core/localization/babka_number_formatter.dart';
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
          padding: const EdgeInsets.symmetric(
            horizontal: BabkaDimens.spacing24,
          ),
          child: Text(
            title,
            style: BabkaTypography.h3(
              context,
            ).copyWith(color: BabkaColors.primary),
          ),
        ),
        const SizedBox(height: BabkaDimens.spacing16),
        ...children,
        const SizedBox(height: BabkaDimens.spacing32),
      ],
    );
  }
}

class CustomizationOptionRow extends ConsumerWidget {
  final Bread baseBread;
  final BabkaCustomizationOption option;

  const CustomizationOptionRow({
    super.key,
    required this.baseBread,
    required this.option,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(customBabkaProvider(baseBread));
    final quantity = customization.selectedOptions[option.id] ?? 0;
    final languageCode = ref.watch(localeProvider).languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BabkaDimens.spacing24,
        vertical: BabkaDimens.spacing8,
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
                  style: BabkaTypography.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                if (option.price > 0)
                  Text(
                    '+${BabkaNumberFormatter.formatCurrency(option.price, languageCode)}',
                    style: BabkaTypography.bodySmall(context).copyWith(
                      color: BabkaColors.primary,
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
              ref
                  .read(customBabkaProvider(baseBread).notifier)
                  .updateOption(option.id, quantity + 1);
            },
            onDecrement: () {
              ref
                  .read(customBabkaProvider(baseBread).notifier)
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
        margin: const EdgeInsets.only(right: BabkaDimens.spacing12),
        padding: const EdgeInsets.all(BabkaDimens.spacing12),
        decoration: BoxDecoration(
          color: isSelected
              ? BabkaColors.primary.withValues(alpha: 0.1)
              : BabkaColors.surface,
          borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
          border: Border.all(
            color: isSelected ? BabkaColors.primary : BabkaColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(BabkaDimens.radiusS),
              child: Image.network(
                bread.imageUrl,
                gaplessPlayback: true,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 60,
                  width: 60,
                  color: BabkaColors.border,
                  child: const Icon(
                    Icons.bakery_dining,
                    color: BabkaColors.inkLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bread.name,
              style: BabkaTypography.bodySmall(context).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? BabkaColors.primary : BabkaColors.ink,
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


