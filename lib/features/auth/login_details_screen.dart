import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_text_field.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/utils/sangak_toast.dart';
import '../home/tab_provider.dart';
import 'auth_provider.dart';
import 'auth_validators.dart';
import 'auth_error_handler.dart';
import 'auth_rate_limiter.dart';

class LoginDetailsScreen extends ConsumerStatefulWidget {
  const LoginDetailsScreen({super.key});

  @override
  ConsumerState<LoginDetailsScreen> createState() => _LoginDetailsScreenState();
}

class _LoginDetailsScreenState extends ConsumerState<LoginDetailsScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  String? _error;
  bool _isSubmitting = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Validates email field
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

  /// Validates password field
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }
    return null;
  }

  /// Attempts login with error handling
  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    
    final email = _emailController.text.trim().toLowerCase();
    
    if (!authRateLimiter.isAllowed(email)) {
      final secondsLeft = authRateLimiter.getSecondsUntilRetry(email);
      setState(() => _error = l10n.tooManyAttempts);
      SangakToast.show(context, '${l10n.tooManyAttempts} ($secondsLeft${l10n.secondsShort})');
      return;
    }
    
    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    
    try {
      final user = await ref.read(authProvider.notifier).signIn(email, _passwordController.text);
      if (!mounted) return;
      if (user != null) {
        SangakToast.show(context, l10n.loginSuccessful);
        ref.read(tabProvider.notifier).state = 0;
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      final (_, messageKey) = AuthErrorHandler.handleAuthError(e);
      final errorMessage = _getLocalizedError(messageKey, l10n);
      setState(() => _error = errorMessage);
      SangakToast.show(context, errorMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getLocalizedError(String key, AppLocalizations l10n) {
    switch (key) {
      case 'invalidCredentials': return l10n.invalidCredentials;
      case 'emailNotVerified': return l10n.emailNotVerified;
      case 'networkError': return l10n.networkError;
      default: return l10n.invalidCredentials;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final l10n = AppLocalizations.of(context);
    final isFormValid = _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: AppLogo.medium()),
                const SizedBox(height: 48),
                Text(l10n.welcomeBack, style: SangakTypography.h1(context)),
                const SizedBox(height: 32),
                SangakTextField(
                  label: l10n.email,
                  hintText: l10n.enterEmail,
                  controller: _emailController,
                  focusNode: _emailFocus,
                  leadingIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => FocusScope.of(context).requestFocus(_passwordFocus),
                  onChanged: (_) => setState(() => _error = null),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 24),
                SangakTextField(
                  label: l10n.password,
                  hintText: l10n.enterPassword,
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  isPassword: !_showPassword,
                  leadingIcon: Icons.lock_outline,
                  trailingIcon: _showPassword ? Icons.visibility_off : Icons.visibility,
                  onTrailingIconPressed: () => setState(() => _showPassword = !_showPassword),
                  errorText: _error,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _login,
                  onChanged: (_) => setState(() => _error = null),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 32),
                SangakButton.primary(
                  label: l10n.login,
                  width: double.infinity,
                  isLoading: isLoading || _isSubmitting,
                  onPressed: isFormValid && !isLoading ? _login : null,
                ),
                const SizedBox(height: 32),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.dontHaveAccount, style: SangakTypography.bodyMedium(context)),
                      GestureDetector(
                        onTap: () => context.push('/signup-choice'),
                        child: Text(
                          l10n.createOne,
                          style: SangakTypography.title(context).copyWith(
                            color: SangakColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SangakDimens.spacing48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
