import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/language_card.dart';
import '../../shared/widgets/app_logo.dart';
import 'language_provider.dart';

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
    _selectedCode = ref.read(languageProvider);
  }

  @override
  Widget build(BuildContext context) {
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
                'Welcome to Sangak',
                style: SangakTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SangakDimens.spacing12),
              Text(
                'Please select your preferred language to continue.',
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
                      onTap: () => setState(() => _selectedCode = lang['code']),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: SangakDimens.spacing24),
                child: SangakButton.primary(
                  label: 'Continue',
                  width: double.infinity,
                  onPressed: _selectedCode == null
                      ? null
                      : () async {
                          await ref.read(languageProvider.notifier).setLanguage(_selectedCode!);
                          if (mounted) {
                            context.go('/login');
                          }
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
