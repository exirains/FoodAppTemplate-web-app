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
      // If we have a code from a link, jump straight to auth choices
      _showAuthChoices = true;
      _isReferralApplied = false; // Will be set to true after validation
      
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
        BabkaToast.show(context, AppLocalizations.of(context).invitationCodeApplied);
      } else {
        setState(() {
          _referralError = _getLocalizedError(result['error']);
          _showAuthChoices = false; // Show referral field to display error
          _isReferralApplied = false;
        });
      }
    } catch (e) {
      if (mounted) {
        BabkaToast.show(context, AppLocalizations.of(context).errorOccurred);
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
        BabkaToast.show(context, l10n.registeredSuccessfully);
        ref.read(tabProvider.notifier).state = 0;
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        BabkaToast.show(context, e.toString());
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
            BabkaDimens.spacing24,
            BabkaDimens.spacing24,
            BabkaDimens.spacing24,
            BabkaDimens.spacing48,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.joinTheFamily, style: BabkaTypography.h1(context)),
              const SizedBox(height: 8),
              Text(
                l10n.profileGuestMessage,
                style: BabkaTypography.bodyMedium(context).copyWith(color: BabkaColors.inkLight),
              ),
              const SizedBox(height: 48),
              
              if (!_showAuthChoices) ...[
                // Step 1: Referral Code
                BabkaTextField(
                  label: l10n.invitationCode,
                  hintText: l10n.invitationCodeOptional,
                  controller: _referralController,
                  leadingIcon: Icons.card_giftcard,
                  errorText: _referralError,
                  enabled: !_isValidating,
                ),
                const SizedBox(height: 24),
                BabkaButton.primary(
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
                      style: BabkaTypography.button(context).copyWith(color: BabkaColors.inkLight),
                    ),
                  ),
                ),
              ] else ...[
                // Step 2: Auth Choices
                if (_isReferralApplied) ...[
                   Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: BabkaColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: BabkaColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.invitationCodeApplied,
                            style: BabkaTypography.title(context).copyWith(color: BabkaColors.primary, fontSize: 14),
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
                          child: Text(l10n.clear, style: const TextStyle(color: BabkaColors.primary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                
                BabkaButton.outlined(
                  label: l10n.continueWithGoogle,
                  width: double.infinity,
                  leading: const GoogleMark(),
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handleGoogleSignup,
                ),
                const SizedBox(height: 16),
                BabkaButton.primary(
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
                      Text(l10n.alreadyHaveAccount, style: BabkaTypography.bodyMedium(context)),
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: Text(
                          l10n.signIn,
                          style: BabkaTypography.title(context).copyWith(
                            color: BabkaColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: BabkaDimens.spacing48),
            ],
          ),
        ),
      ),
    );
  }
}
