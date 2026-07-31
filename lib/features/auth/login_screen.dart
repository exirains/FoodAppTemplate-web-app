import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_text_field.dart';
import '../../shared/widgets/app_logo.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _error = null);
    try {
      await ref.read(authProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      final authState = ref.read(authProvider);
      if (authState.hasError) {
        setState(() => _error = authState.error.toString());
      } else if (authState.value != null) {
        if (mounted) context.go('/home');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SangakDimens.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: SangakDimens.spacing48),
              const Center(
                child: Hero(
                  tag: 'app_logo',
                  child: AppLogo.medium(),
                ),
              ),
              const SizedBox(height: SangakDimens.spacing24),
              Center(
                child: Text(
                  'Welcome Back',
                  style: SangakTypography.h1,
                ),
              ),
              const SizedBox(height: SangakDimens.spacing48),
              SangakTextField(
                label: 'Email',
                hintText: 'Enter your email',
                controller: _emailController,
                leadingIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: SangakDimens.spacing24),
              SangakTextField(
                label: 'Password',
                hintText: 'Enter your password',
                controller: _passwordController,
                isPassword: true,
                leadingIcon: Icons.lock_outline,
                errorText: _error,
              ),
              const SizedBox(height: SangakDimens.spacing8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {}, // TODO: Forgot Password
                  child: Text(
                    'Forgot Password?',
                    style: SangakTypography.bodySmall.copyWith(color: SangakColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: SangakDimens.spacing32),
              SangakButton.primary(
                label: 'Login',
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
                    child: Text('OR', style: SangakTypography.caption),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: SangakDimens.spacing24),
              SangakButton.outlined(
                label: 'Continue with Google',
                width: double.infinity,
                icon: Icons.g_mobiledata, // Placeholder for Google icon
                onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
              ),
              const SizedBox(height: SangakDimens.spacing48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: SangakTypography.bodyMedium),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: Text(
                      'Create one',
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
    );
  }
}
