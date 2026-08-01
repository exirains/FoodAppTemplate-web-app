import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_typography.dart';
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
    {'code': 'tr', 'label': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'label': 'English', 'flag': '🇺🇸'},
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const AppLogo.large(),
              const SizedBox(height: 24),
              Text(
                l10n.chooseLanguage,
                style: SangakTypography.h2.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Lütfen bir dil seçin / Please choose a language / لطفا یک زبان را انتخاب کنید",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 48),
              ..._languages.map((lang) => LanguageCard(
                    label: lang['label']!,
                    flag: lang['flag']!,
                    isSelected: _selectedCode == lang['code'],
                    onTap: () {
                      setState(() => _selectedCode = lang['code']);
                      ref.read(localeProvider.notifier).setLocale(lang['code']!);
                    },
                  )),
              const Spacer(),
              const Text(
                "You can change this anytime in settings\nBu seçeneği dilediğiniz zaman ayarlardan değiştirebilirsiniz\nمی‌توانید این را هر زمان در تنظیمات تغییر دهید",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              SangakButton.primary(
                label: l10n.continueButton,
                width: double.infinity,
                onPressed: _selectedCode == null
                    ? null
                    : () {
                        context.go('/home');
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
