import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_text_field.dart';
import '../../shared/widgets/google_mark.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/referral_repository.dart';
import '../home/tab_provider.dart';
import 'auth_provider.dart';

class SignupChoiceScreen extends ConsumerStatefulWidget {
  const SignupChoiceScreen({super.key});

  @override
  ConsumerState<SignupChoiceScreen> createState() => _SignupChoiceScreenState();
}

class _SignupChoiceScreenState extends ConsumerState<SignupChoiceScreen> {
  final _referralController = TextEditingController();
  bool _isValidating = false;
  bool _showAuthChoices = false;
  String? _referralError;
  bool _isReferralApplied = false;

  @override
  void initState() {
    super.initState();
    final pendingReferral = ref.read(pendingReferralProvider);
    if (pendingReferral != null && pendingReferral.isNotEmpty) {
      _referralController.text = pendingReferral;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleContinue();
      });
    }
  }

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final code = _referralController.text.trim();
    if (code.isEmpty) {
      setState(() => _showAuthChoices = true);
      return;
    }

    setState(() {
      _isValidating = true;
      _referralError = null;
    });

    try {
      final result = await ref.read(referralRepositoryProvider).validateReferralCodeSecurely(code);
      
      if (!mounted) return;

      if (result['valid'] == true) {
        ref.read(pendingReferralProvider.notifier).state = code;
        setState(() {
          _isReferralApplied = true;
          _showAuthChoices = true;
        });
        SangakToast.show(context, AppLocalizations.of(context).invitationCodeApplied);
      } else {
        setState(() {
          _referralError = _getLocalizedError(result['error']);
        });
      }
    } catch (e) {
      if (mounted) {
        SangakToast.show(context, AppLocalizations.of(context).errorOccurred);
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  String _getLocalizedError(String? error) {
    final l10n = AppLocalizations.of(context);
    switch (error) {
      case 'invalid_code':
        return l10n.invalidInvitationCode;
      case 'self_referral':
        return l10n.selfReferralError;
      case 'inactive_code':
        return l10n.inactiveReferralCodeError;
      default:
        return l10n.invalidInvitationCode;
    }
  }

  void _handleGoogleSignup() async {
    final l10n = AppLocalizations.of(context);
    try {
      final user = await ref.read(authProvider.notifier).signInWithGoogle();
      if (user != null && mounted) {
        SangakToast.show(context, l10n.registeredSuccessfully);
        ref.read(tabProvider.notifier).state = 0;
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        SangakToast.show(context, e.toString());
      }
    }
  }

  void _handleEmailSignup() {
    context.push('/register');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLoading = ref.watch(authProvider).isLoading;

    // Listen for external referral code updates (e.g. from deep links)
    ref.listen(pendingReferralProvider, (previous, next) {
      if (next != null && next.isNotEmpty && _referralController.text != next) {
        _referralController.text = next;
        if (!_isReferralApplied && !_isValidating) {
          _handleContinue();
        }
      }
    });
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            SangakDimens.spacing24,
            SangakDimens.spacing24,
            SangakDimens.spacing24,
            SangakDimens.spacing48,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.joinTheFamily, style: SangakTypography.h1(context)),
              const SizedBox(height: 8),
              Text(
                l10n.profileGuestMessage,
                style: SangakTypography.bodyMedium(context).copyWith(color: SangakColors.inkLight),
              ),
              const SizedBox(height: 48),
              
              if (!_showAuthChoices) ...[
                // Step 1: Referral Code
                SangakTextField(
                  label: l10n.invitationCode,
                  hintText: l10n.invitationCodeOptional,
                  controller: _referralController,
                  leadingIcon: Icons.card_giftcard,
                  errorText: _referralError,
                  enabled: !_isValidating,
                ),
                const SizedBox(height: 24),
                SangakButton.primary(
                  label: l10n.continueButton,
                  width: double.infinity,
                  isLoading: _isValidating,
                  onPressed: _handleContinue,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isValidating ? null : () => setState(() => _showAuthChoices = true),
                    child: Text(
                      l10n.skip,
                      style: SangakTypography.button(context).copyWith(color: SangakColors.inkLight),
                    ),
                  ),
                ),
              ] else ...[
                // Step 2: Auth Choices
                if (_isReferralApplied) ...[
                   Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SangakColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(SangakDimens.radiusM),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: SangakColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.invitationCodeApplied,
                            style: SangakTypography.title(context).copyWith(color: SangakColors.primary, fontSize: 14),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(pendingReferralProvider.notifier).state = null;
                            setState(() {
                              _isReferralApplied = false;
                              _showAuthChoices = false;
                              _referralController.clear();
                            });
                          },
                          child: Text(l10n.clear, style: const TextStyle(color: SangakColors.primary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                
                SangakButton.outlined(
                  label: l10n.continueWithGoogle,
                  width: double.infinity,
                  leading: const GoogleMark(),
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handleGoogleSignup,
                ),
                const SizedBox(height: 16),
                SangakButton.primary(
                  label: l10n.email,
                  width: double.infinity,
                  icon: Icons.email_outlined,
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handleEmailSignup,
                ),
                const SizedBox(height: 32),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.alreadyHaveAccount, style: SangakTypography.bodyMedium(context)),
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: Text(
                          l10n.signIn,
                          style: SangakTypography.title(context).copyWith(
                            color: SangakColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: SangakDimens.spacing48),
            ],
          ),
        ),
      ),
    );
  }
}
