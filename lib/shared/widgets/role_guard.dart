import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../features/auth/profile_provider.dart';

class RoleGuard extends ConsumerWidget {
  final List<String> allowedRoles;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile != null && allowedRoles.contains(profile.role)) {
          return child;
        }
        return Scaffold(
          body: Center(
            child: Text(AppLocalizations.of(context).unauthorized),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        body: Center(child: Text(AppLocalizations.of(context).errorOccurred)),
      ),
    );
  }
}

