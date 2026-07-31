import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/language_card.dart';
import '../../shared/widgets/app_logo.dart';
import '../../core/localization/locale_provider.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String? _selectedCode;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
    {'code': 'tr', 'label': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'fa', 'label': 'فارسی', 'flag': '🇮🇷'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCode = ref.read(localeProvider).languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SangakDimens.spacing24),
          child: Column(
            children: [
              const SizedBox(height: SangakDimens.spacing48),
              const Center(child: AppLogo.medium()),
              const SizedBox(height: SangakDimens.spacing32),
              Text(
                l10n.welcomeToSangak,
                style: SangakTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SangakDimens.spacing12),
              Text(
                l10n.pleaseSelectLanguage,
                style: SangakTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SangakDimens.spacing48),
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _languages.length,
                  separatorBuilder: (context, index) => const SizedBox(height: SangakDimens.spacing16),
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    return LanguageCard(
                      label: lang['label']!,
                      flag: lang['flag']!,
                      isSelected: _selectedCode == lang['code'],
                      onTap: () {
                        setState(() => _selectedCode = lang['code']);
                        ref.read(localeProvider.notifier).setLocale(lang['code']!);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: SangakDimens.spacing24),
                child: SangakButton.primary(
                  label: l10n.continueButton,
                  width: double.infinity,
                  onPressed: _selectedCode == null
                      ? null
                      : () {
                          context.go('/home');
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
