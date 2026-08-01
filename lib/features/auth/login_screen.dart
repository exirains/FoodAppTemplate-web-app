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
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _error = null);
    try {
      final user = await ref.read(authProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      
      if (!mounted) return;
      
      if (user != null) {
        SangakToast.show(context, l10n.loginSuccessful);
        context.go('/home');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final l10n = AppLocalizations.of(context);

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
                    style: SangakTypography.h1,
                  ),
                ),
                const SizedBox(height: SangakDimens.spacing48),
                SangakTextField(
                  label: l10n.email,
                  hintText: l10n.enterEmail,
                  controller: _emailController,
                  leadingIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: SangakDimens.spacing24),
                SangakTextField(
                  label: l10n.password,
                  hintText: l10n.enterPassword,
                  controller: _passwordController,
                  isPassword: true,
                  leadingIcon: Icons.lock_outline,
                  errorText: _error,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password too short';
                    return null;
                  },
                ),
                const SizedBox(height: SangakDimens.spacing8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {}, // TODO: Forgot Password
                    child: Text(
                      l10n.forgotPassword,
                      style: SangakTypography.bodySmall.copyWith(color: SangakColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: SangakDimens.spacing32),
                SangakButton.primary(
                  label: l10n.login,
                  width: double.infinity,
                  isLoading: isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: SangakDimens.spacing24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(l10n.or, style: SangakTypography.caption),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: SangakDimens.spacing24),
                SangakButton.outlined(
                  label: l10n.continueWithGoogle,
                  width: double.infinity,
                  icon: Icons.g_mobiledata, // Placeholder for Google icon
                  onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                ),
                const SizedBox(height: SangakDimens.spacing48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.dontHaveAccount, style: SangakTypography.bodyMedium),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text(
                        l10n.createOne,
                        style: SangakTypography.title.copyWith(
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
