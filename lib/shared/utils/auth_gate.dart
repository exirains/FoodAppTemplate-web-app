import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/pending_action_provider.dart';
import '../widgets/auth_prompt_bottom_sheet.dart';

class AuthGate {
  static Future<void> run(
    BuildContext context,
    WidgetRef ref, {
    required VoidCallback action,
    String? title,
    String? message,
  }) async {
    final user = ref.read(authProvider).asData?.value;

    if (user != null) {
      // User is authenticated, run immediately
      action();
    } else {
      // User is guest, store action and prompt auth
      ref.read(pendingActionProvider.notifier).set(action);
      final result = await AuthPromptBottomSheet.show(
        context,
        title: title,
        message: message,
      );

      if (!context.mounted) return;

      if (result == 'login') {
        context.push('/login');
      } else if (result == 'register') {
        context.push('/signup-choice');
      }
    }
  }
}
