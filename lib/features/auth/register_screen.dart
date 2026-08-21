import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_text_field.dart';
import '../../shared/utils/sangak_toast.dart';
import 'package:sangak/services/supabase_service.dart';
import '../home/tab_provider.dart';
import '../../core/localization/locale_provider.dart';
import 'auth_provider.dart';
import 'auth_validators.dart';
import 'auth_error_handler.dart';
import 'auth_rate_limiter.dart';
import 'password_strength_indicator.dart';
import 'services/guest_mode_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  
  bool _agreedToTerms = false;
  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+90';
    
    // Pre-fill referral code from provider
    final pendingReferral = ref.read(pendingReferralProvider);
    if (pendingReferral != null) {
      _referralController.text = pendingReferral;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  /// Validate name field
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }

    final error = AuthValidators.validateName(value);
    if (error != null) {
      final l10n = AppLocalizations.of(context);
      if (error == 'required_field') {
        return l10n.requiredField;
      } else if (error == 'name_too_short') {
        return l10n.nameTooShort;
      } else if (error == 'name_too_long') {
        return l10n.nameTooLong;
      }
    }

    return null;
  }

  /// Validate email field
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }

    final error = AuthValidators.validateEmail(value);
    if (error != null) {
      return error == 'required_field'
          ? AppLocalizations.of(context).requiredField
          : AppLocalizations.of(context).invalidEmail;
    }

    return null;
  }

  /// Validate phone field
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }

    final error = AuthValidators.validatePhoneNumber(value);
    if (error != null) {
      return AppLocalizations.of(context).invalidPhoneNumber;
    }

    return null;
  }

  /// Validate password field
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }

    final error = AuthValidators.validatePassword(value);
    if (error != null) {
      final l10n = AppLocalizations.of(context);
      if (error == 'required_field') {
        return l10n.requiredField;
      } else if (error == 'password_too_short') {
        return l10n.passwordTooShort;
      } else if (error == 'password_requirements') {
        return l10n.passwordRequirements;
      }
    }

    return null;
  }

  /// Validate confirm password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }

    final error = AuthValidators.validatePasswordMatch(
      _passwordController.text,
      value,
    );
    if (error != null) {
      return AppLocalizations.of(context).passwordsDoNotMatch;
    }

    return null;
  }

  /// Attempts registration with proper validation and error handling
  Future<void> _register() async {
    final l10n = AppLocalizations.of(context);

    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Check terms agreement
    if (!_agreedToTerms) {
      SangakToast.show(context, l10n.pleaseAgreeToTerms);
      return;
    }

    // Prevent double submission
    if (_isSubmitting) return;

    final email = AuthValidators.sanitizeEmail(_emailController.text);
    final name = AuthValidators.sanitizeName(_nameController.text);
    final phone = AuthValidators.sanitizePhoneNumber(_phoneController.text);
    final referralCode = _referralController.text.trim();

    // Update the provider with whatever is in the text field 
    // to ensure it's picked up by the auth notifier
    if (referralCode.isNotEmpty) {
      ref.read(pendingReferralProvider.notifier).state = referralCode;
    }

    // Check rate limiting
    if (!authRateLimiter.isAllowed(email)) {
      final secondsLeft = authRateLimiter.getSecondsUntilRetry(email);
      SangakToast.show(
        context,
        '${l10n.tooManyAttempts} ($secondsLeft${l10n.secondsShort})',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await ref.read(authProvider.notifier).signUp(
            email,
            _passwordController.text,
            name,
            phone: phone,
          );

      if (!mounted) return;

      if (user != null) {
        // Create profile in Supabase to avoid crashes in other screens
        try {
          final lang = ref.read(localeProvider).languageCode;
          await SupabaseService.client.from('profiles').upsert({
            'id': user.id,
            'full_name': name,
            'email': email,
            'phone': phone,
            'preferred_language': lang,
          });
        } catch (e) {
          debugPrint('Non-critical: Error creating initial profile record: $e');
          // We continue because the user is registered in Auth
        }

        // Clear guest data after successful registration
        await GuestModeService.exitGuestMode();
        
        if (!mounted) return;

        SangakToast.show(context, l10n.registeredSuccessfully);
        ref.read(tabProvider.notifier).state = 0; // Go to Home tab
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;

      // Handle different error types
      String errorMessage = l10n.invalidCredentials;

      if (e is AuthException) {
        if (e.isLocalizedKey) {
          errorMessage = _getLocalizedError(e.message, l10n);
        } else {
          errorMessage = e.message;
        }
      } else {
        final (_, messageKey) = AuthErrorHandler.handleAuthError(e);
        errorMessage = _getLocalizedError(messageKey, l10n);
      }

      SangakToast.show(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Get localized error message from key
  String _getLocalizedError(String key, AppLocalizations l10n) {
    switch (key) {
      case 'invalidEmail':
        return l10n.invalidEmail;
      case 'emailAlreadyInUse':
        return l10n.emailAlreadyInUse;
      case 'networkError':
        return l10n.networkError;
      case 'tooManyAttempts':
        return l10n.tooManyAttempts;
      case 'invalidPhoneNumber':
        return l10n.invalidPhoneNumber;
      default:
        return l10n.invalidCredentials;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final l10n = AppLocalizations.of(context);

    // Listen for external referral code updates
    ref.listen(pendingReferralProvider, (previous, next) {
      if (next != null && next.isNotEmpty && _referralController.text != next) {
        _referralController.text = next;
      }
    });

    // Check if form is valid for button state
    final isFormValid = _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _agreedToTerms;
    final isButtonDisabled = isLoading || _isSubmitting || !isFormValid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.createAccount, style: SangakTypography.h3(context)),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full name field
                SangakTextField(
                  label: l10n.fullName,
                  hintText: l10n.enterFullName,
                  controller: _nameController,
                  leadingIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () {
                    _emailFocus.requestFocus();
                  },
                  validator: _validateName,
                ),
                const SizedBox(height: SangakDimens.spacing16),
                // Email field
                SangakTextField(
                  label: l10n.email,
                  hintText: l10n.enterEmail,
                  controller: _emailController,
                  focusNode: _emailFocus,
                  leadingIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () {
                    _emailFocus.unfocus();
                    FocusScope.of(context).requestFocus(_phoneFocus);
                  },
                  validator: _validateEmail,
                ),
                const SizedBox(height: SangakDimens.spacing16),
                // Phone number field
                SangakTextField(
                  label: l10n.phoneNumber,
                  hintText: '+90 5XX XXX XX XX',
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  leadingIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    _TurkeyPhoneInputFormatter(),
                  ],
                  onEditingComplete: () {
                    _phoneFocus.unfocus();
                    FocusScope.of(context).requestFocus(_passwordFocus);
                  },
                  validator: _validatePhone,
                ),
                const SizedBox(height: SangakDimens.spacing16),
                // Password field
                SangakTextField(
                  label: l10n.password,
                  hintText: l10n.enterPassword,
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  isPassword: !_showPassword,
                  leadingIcon: Icons.lock_outline,
                  trailingIcon: _showPassword ? Icons.visibility_off : Icons.visibility,
                  onTrailingIconPressed: () {
                    setState(() => _showPassword = !_showPassword);
                  },
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () {
                    _passwordFocus.unfocus();
                    FocusScope.of(context).requestFocus(_confirmPasswordFocus);
                  },
                  onChanged: (_) {
                    setState(() {}); // Rebuild to update strength indicator
                  },
                  validator: _validatePassword,
                ),
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: SangakDimens.spacing12),
                  PasswordStrengthIndicator(
                    password: _passwordController.text,
                    showLabel: true,
                    showRequirements: true,
                  ),
                ],
                const SizedBox(height: SangakDimens.spacing16),
                // Confirm password field
                 SangakTextField(
                  label: l10n.confirmPassword,
                  hintText: l10n.reEnterPassword,
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  isPassword: !_showConfirmPassword,
                  leadingIcon: Icons.lock_outline,
                  trailingIcon: _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  onTrailingIconPressed: () {
                    setState(() => _showConfirmPassword = !_showConfirmPassword);
                  },
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () {
                    _confirmPasswordFocus.unfocus();
                  },
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: SangakDimens.spacing16),
                // Referral Code field (Optional)
                SangakTextField(
                  label: l10n.invitationCode,
                  hintText: l10n.invitationCodeOptional,
                  controller: _referralController,
                  leadingIcon: Icons.card_giftcard,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: SangakDimens.spacing16),
                // Terms agreement checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                      activeColor: SangakColors.primary,
                    ),
                    Expanded(
                      child: Text(
                        l10n.iAgreeToTerms,
                        style: SangakTypography.bodySmall(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SangakDimens.spacing32),
                // Create account button
                SangakButton.primary(
                  label: l10n.createAccount,
                  width: double.infinity,
                  isLoading: isLoading || _isSubmitting,
                  onPressed: isButtonDisabled ? null : _register,
                ),
                const SizedBox(height: SangakDimens.spacing24),
                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.alreadyHaveAccount, style: SangakTypography.bodyMedium(context)),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TurkeyPhoneInputFormatter extends TextInputFormatter {
  static const _prefix = '+90 ';
  static const _maxNationalDigits = 10;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only allow digits for the actual number part
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Strip leading 90 or 0 if user manually typed them
    if (digits.startsWith('90')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    
    if (digits.length > _maxNationalDigits) {
      digits = digits.substring(0, _maxNationalDigits);
    }

    // Format: +90 5XX XXX XX XX
    var formatted = _prefix;
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6 || i == 8) {
        formatted += ' ';
      }
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
