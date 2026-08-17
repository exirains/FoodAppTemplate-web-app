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
import '../../shared/widgets/google_mark.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../services/supabase_service.dart';
import '../home/tab_provider.dart';
import 'auth_provider.dart';
import 'auth_validators.dart';
import 'auth_error_handler.dart';
import 'auth_rate_limiter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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
    
    if (value.length < 6) {
      return AppLocalizations.of(context).passwordTooShort;
    }
    
    return null;
  }

  /// Attempts login with error handling
  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    
    // Validate form
    if (!_formKey.currentState!.validate()) return;
    
    // Prevent double submission
    if (_isSubmitting) return;
    
    final email = _emailController.text.trim().toLowerCase();
    
    // Check rate limiting
    if (!authRateLimiter.isAllowed(email)) {
      final secondsLeft = authRateLimiter.getSecondsUntilRetry(email);
      setState(() => _error = l10n.tooManyAttempts);
      SangakToast.show(
        context,
        '${l10n.tooManyAttempts} ($secondsLeft${l10n.secondsShort})',
      );
      return;
    }
    
    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    
    try {
      final user = await ref.read(authProvider.notifier).signIn(
            email,
            _passwordController.text,
          );
      
      if (!mounted) return;
      
      if (user != null) {
        // Ensure profile exists after login
        try {
          final profile = await SupabaseService.client.from('profiles').select().eq('id', user.id).maybeSingle();
          if (profile == null) {
            await SupabaseService.client.from('profiles').insert({
              'id': user.id,
              'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
              'email': user.email,
            });
          }
        } catch (e) {
          debugPrint('Non-critical: Error verifying profile after login: $e');
        }

        if (!mounted) return;
        SangakToast.show(context, l10n.loginSuccessful);
        ref.read(tabProvider.notifier).state = 0; // Go to Home tab (User Preference)
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
      
      setState(() => _error = errorMessage);
      
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
      case 'invalidCredentials':
        return l10n.invalidCredentials;
      case 'emailNotVerified':
        return l10n.emailNotVerified;
      case 'networkError':
        return l10n.networkError;
      case 'tooManyAttempts':
        return l10n.tooManyAttempts;
      case 'invalidEmail':
        return l10n.invalidEmail;
      default:
        return l10n.invalidCredentials;
    }
  }

  /// Handle Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isSubmitting = true);
    
    try {
      final user = await ref.read(authProvider.notifier).signInWithGoogle();
      
      if (!mounted) return;
      
      if (user != null) {
        final l10n = AppLocalizations.of(context);
        SangakToast.show(context, l10n.loginSuccessful);
        ref.read(tabProvider.notifier).state = 0; // Go to Home tab (User Preference)
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      
      final l10n = AppLocalizations.of(context);
      final (_, messageKey) = AuthErrorHandler.handleAuthError(e);
      final errorMessage = _getLocalizedError(messageKey, l10n);
      
      SangakToast.show(
        context,
        errorMessage,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final l10n = AppLocalizations.of(context);
    final isFormValid = _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
    final isButtonDisabled = isLoading || _isSubmitting || !isFormValid;

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
          padding: const EdgeInsets.symmetric(horizontal: SangakDimens.spacing24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: SangakDimens.spacing24),
                const Center(
                  child: Hero(
                    tag: 'app_logo',
                    child: AppLogo.medium(),
                  ),
                ),
                const SizedBox(height: SangakDimens.spacing24),
                Center(
                  child: Text(
                    l10n.welcomeBack,
                    style: SangakTypography.h1(context),
                  ),
                ),
                const SizedBox(height: SangakDimens.spacing48),
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
                    FocusScope.of(context).requestFocus(_passwordFocus);
                  },
                  onChanged: (_) {
                    // Clear error when user starts typing
                    setState(() => _error = null);
                  },
                  validator: _validateEmail,
                ),
                const SizedBox(height: SangakDimens.spacing24),
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
                  errorText: _error,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: isLoading || _isSubmitting ? null : _login,
                  onChanged: (_) {
                    // Clear error when user starts typing
                    setState(() => _error = null);
                  },
                  validator: _validatePassword,
                ),
                const SizedBox(height: SangakDimens.spacing8),
                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {}, // TODO: Forgot Password
                    child: Text(
                      l10n.forgotPassword,
                      style: SangakTypography.bodySmall(context).copyWith(
                        color: SangakColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: SangakDimens.spacing32),
                // Login button
                SangakButton.primary(
                  label: l10n.login,
                  width: double.infinity,
                  isLoading: isLoading || _isSubmitting,
                  onPressed: isButtonDisabled ? null : _login,
                ),
                const SizedBox(height: SangakDimens.spacing24),
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l10n.or, style: SangakTypography.caption(context)),
                  ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: SangakDimens.spacing24),
                // Google Sign-In button
                SangakButton.outlined(
                  label: l10n.continueWithGoogle,
                  width: double.infinity,
                  leading: const GoogleMark(),
                  isLoading: isLoading || _isSubmitting,
                  onPressed: (_isSubmitting || isLoading) ? null : _handleGoogleSignIn,
                ),
                const SizedBox(height: SangakDimens.spacing48),
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.dontHaveAccount, style: SangakTypography.bodyMedium(context)),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push('/register'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
