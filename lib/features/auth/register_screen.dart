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
import 'auth_provider.dart';

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
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context);
    
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms) {
      setState(() => _error = l10n.pleaseAgreeToTerms);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }

    setState(() => _error = null);
    try {
      final user = await ref.read(authProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
          );
      
      if (!mounted) return;
      
      if (user != null) {
        SangakToast.show(context, l10n.registeredSuccessfully);
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
        title: Text(l10n.createAccount, style: SangakTypography.h3),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SangakDimens.spacing24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SangakTextField(
                  label: l10n.fullName,
                  hintText: l10n.enterFullName,
                  controller: _nameController,
                  leadingIcon: Icons.person_outline,
                  validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: SangakDimens.spacing16),
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
                const SizedBox(height: SangakDimens.spacing16),
                SangakTextField(
                  label: l10n.phoneNumber,
                  hintText: '+90 5XX XXX XX XX',
                  controller: _phoneController,
                  leadingIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Phone is required';
                    if (!v.startsWith('+')) return 'Must start with + (E.164)';
                    if (v.length < 10) return 'Invalid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: SangakDimens.spacing16),
                SangakTextField(
                  label: l10n.password,
                  hintText: l10n.enterPassword,
                  controller: _passwordController,
                  isPassword: true,
                  leadingIcon: Icons.lock_outline,
                  validator: (v) => (v == null || v.length < 6) ? 'Password too short' : null,
                ),
                const SizedBox(height: SangakDimens.spacing16),
                SangakTextField(
                  label: l10n.confirmPassword,
                  hintText: l10n.reEnterPassword,
                  controller: _confirmPasswordController,
                  isPassword: true,
                  leadingIcon: Icons.lock_clock_outlined,
                  errorText: _error,
                  validator: (v) => (v == null || v.isEmpty) ? 'Confirm your password' : null,
                ),
                const SizedBox(height: SangakDimens.spacing16),
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
                        style: SangakTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SangakDimens.spacing32),
                SangakButton.primary(
                  label: l10n.createAccount,
                  width: double.infinity,
                  isLoading: isLoading,
                  onPressed: _register,
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
                  icon: Icons.g_mobiledata,
                  onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
