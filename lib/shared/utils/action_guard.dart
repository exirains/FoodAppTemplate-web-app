import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/profile_provider.dart';
import '../../l10n/app_localizations.dart';

class ActionGuard {
  static bool check(BuildContext context, WidgetRef ref) {
    final profile = ref.read(userProfileProvider).asData?.value;
    final l10n = AppLocalizations.of(context);
    
    if (profile != null && !profile.isActive) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.lock_person_outlined, color: Colors.red),
              const SizedBox(width: 12),
              Text(l10n.accountDisabledTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.accountDisabledMessage,
                style: const TextStyle(height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.iUnderstand),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }
}
