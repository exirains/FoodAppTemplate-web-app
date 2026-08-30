import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../../core/design_system/babka_colors.dart';
import '../../../core/design_system/babka_typography.dart';
import '../../../core/design_system/babka_dimens.dart';
import '../../../core/constants/version_config.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/babka_number_formatter.dart';
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
        color: BabkaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(BabkaDimens.radiusXL)),
      ),
      padding: const EdgeInsets.fromLTRB(
        BabkaDimens.spacing24,
        BabkaDimens.spacing16,
        BabkaDimens.spacing24,
        BabkaDimens.spacing48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: BabkaColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: BabkaDimens.spacing32),
          Text(
            l10n.settings,
            style: BabkaTypography.h2(context),
          ),
          const SizedBox(height: BabkaDimens.spacing32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.language,
              style: BabkaTypography.title(context),
            ),
          ),
          const SizedBox(height: BabkaDimens.spacing16),
          ...languages.map((lang) => Padding(
                padding: const EdgeInsets.only(bottom: BabkaDimens.spacing12),
                child: LanguageCard(
                  label: lang['label']!,
                  flag: lang['flag']!,
                  isSelected: currentLocale.languageCode == lang['code'],
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(lang['code']!);
                  },
                ),
              )),
          const SizedBox(height: BabkaDimens.spacing32),
          const Divider(),
          const SizedBox(height: BabkaDimens.spacing16),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? VersionConfig.version;
              final formattedVersion = BabkaNumberFormatter.format(version, currentLocale.languageCode);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'v$formattedVersion',
                    style: BabkaTypography.caption(context).copyWith(color: BabkaColors.inkLight),
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse('https://www.Babka.tr'), mode: LaunchMode.externalApplication),
                    child: Text(
                      'www.Babka.tr',
                      style: BabkaTypography.caption(context).copyWith(
                        color: BabkaColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: BabkaColors.primary,
                      ),
                    ),
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

