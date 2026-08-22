import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../../core/design_system/sangak_colors.dart';
import '../../../core/design_system/sangak_typography.dart';
import '../../../core/design_system/sangak_dimens.dart';
import '../../../core/constants/version_config.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/sangak_number_formatter.dart';
import '../../../shared/widgets/language_card.dart';

class SettingsBottomSheet extends ConsumerWidget {
  const SettingsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);

    final languages = [
      {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
      {'code': 'tr', 'label': 'Türkçe', 'flag': '🇹🇷'},
      {'code': 'fa', 'label': 'فارسی', 'flag': '🇮🇷'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(SangakDimens.radiusXL)),
      ),
      padding: const EdgeInsets.fromLTRB(
        SangakDimens.spacing24,
        SangakDimens.spacing16,
        SangakDimens.spacing24,
        SangakDimens.spacing48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SangakColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: SangakDimens.spacing32),
          Text(
            l10n.settings,
            style: SangakTypography.h2(context),
          ),
          const SizedBox(height: SangakDimens.spacing32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.language,
              style: SangakTypography.title(context),
            ),
          ),
          const SizedBox(height: SangakDimens.spacing16),
          ...languages.map((lang) => Padding(
                padding: const EdgeInsets.only(bottom: SangakDimens.spacing12),
                child: LanguageCard(
                  label: lang['label']!,
                  flag: lang['flag']!,
                  isSelected: currentLocale.languageCode == lang['code'],
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(lang['code']!);
                  },
                ),
              )),
          const SizedBox(height: SangakDimens.spacing32),
          const Divider(),
          const SizedBox(height: SangakDimens.spacing16),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? VersionConfig.version;
              final formattedVersion = SangakNumberFormatter.format(version, currentLocale.languageCode);
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.appDomain ?? 'App Domain', style: SangakTypography.bodyMedium(context)),
                      Text(
                        'www.sangak.tr',
                        style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: SangakDimens.spacing16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.appVersion, style: SangakTypography.bodyMedium(context)),
                      Text(
                        'Sangak v$formattedVersion',
                        style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.inkLight),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
