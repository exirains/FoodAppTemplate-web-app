import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/profile_provider.dart';

class ActionGuard {
  static bool check(BuildContext context, WidgetRef ref) {
    final profile = ref.read(userProfileProvider).asData?.value;
    
    if (profile != null && !profile.isActive) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.lock_person_outlined, color: Colors.red),
              SizedBox(width: 12),
              Text('Account Disabled'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sorry, but your account has been disabled.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Your account has been disabled for violating the rules and guidelines. '
                'You are only permitted to use the app as a viewer. Actions such as placing orders, '
                'updating your profile, or adding favorites are restricted.',
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('I Understand'),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }
}
