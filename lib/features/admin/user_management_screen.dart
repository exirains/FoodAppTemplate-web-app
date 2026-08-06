import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/widgets/sangak_dialogs.dart';

final usersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('profiles')
      .select()
      .order('full_name');
  return (response as List).cast<Map<String, dynamic>>();
});

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  bool _showDisabledOnly = false;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final l10n = AppLocalizations.of(context);

    return RoleGuard(
      allowedRoles: const ['admin'],
      child: Scaffold(
        backgroundColor: SangakColors.background,
        appBar: AppBar(
          title: Text(l10n.userManagement),
          actions: [
            // Filter Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FilterChip(
                label: const Text('Disabled Only'),
                selected: _showDisabledOnly,
                onSelected: (v) => setState(() => _showDisabledOnly = v),
                selectedColor: SangakColors.error.withValues(alpha: 0.2),
                checkmarkColor: SangakColors.error,
              ),
            ),
          ],
        ),
        body: usersAsync.when(
          data: (users) {
            final filteredUsers = _showDisabledOnly 
                ? users.where((u) => (u['is_active'] ?? true) == false).toList()
                : users;

            if (filteredUsers.isEmpty) {
              return Center(child: Text(_showDisabledOnly ? 'No disabled users' : 'No users found'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(SangakDimens.spacing24),
              itemCount: filteredUsers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final isActive = user['is_active'] ?? true;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SangakColors.surface,
                    borderRadius: BorderRadius.circular(SangakDimens.radiusL),
                    border: Border.all(color: SangakColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: SangakColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          (user['full_name'] as String? ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: SangakColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['full_name'] ?? 'No Name', style: SangakTypography.title(context).copyWith(fontSize: 15)),
                            Text(user['email'] ?? '', style: SangakTypography.caption(context)),
                          ],
                        ),
                      ),
                      // Role Badge
                      InkWell(
                        onTap: () => _showRolePicker(context, ref, user),
                        child: _RoleBadge(role: user['role'] ?? 'customer'),
                      ),
                      const SizedBox(width: 12),
                      // Status Toggle Button
                      IconButton(
                        onPressed: () => _confirmStatusChange(context, ref, user, !isActive),
                        icon: Icon(
                          isActive ? Icons.person_outline_rounded : Icons.person_off_rounded,
                          color: isActive ? SangakColors.success : SangakColors.error,
                        ),
                        tooltip: isActive ? 'Disable User' : 'Enable User',
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  void _confirmStatusChange(BuildContext context, WidgetRef ref, Map<String, dynamic> user, bool newStatus) {
    final l10n = AppLocalizations.of(context);
    SangakConfirmDialog.show(
      context,
      title: newStatus ? 'Enable Account' : 'Disable Account',
      message: 'Are you sure you want to ${newStatus ? 'enable' : 'disable'} account for ${user['full_name']}?',
      confirmLabel: newStatus ? 'Enable' : 'Disable',
      cancelLabel: l10n.cancel,
      onConfirm: () async {
        try {
          // Explicitly update the profiles table
          final response = await SupabaseService.client
              .from('profiles')
              .update({'is_active': newStatus})
              .eq('id', user['id'])
              .select();
          
          debugPrint('Update response: $response');
          
          ref.invalidate(usersProvider);
          if (context.mounted) {
            SangakToast.show(context, 'User status updated');
          }
        } catch (e) {
          if (context.mounted) SangakToast.show(context, 'Error: $e');
        }
      },
      isDestructive: !newStatus,
    );
  }

  void _showRolePicker(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    final l10n = AppLocalizations.of(context);
    final roles = ['customer', 'staff', 'delivery', 'admin'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${l10n.changeRole}: ${user['full_name']}', style: SangakTypography.h3(context)),
            const SizedBox(height: 24),
            ...roles.map((role) => ListTile(
              title: Text(role.toUpperCase()),
              trailing: user['role'] == role ? const Icon(Icons.check, color: SangakColors.primary) : null,
              onTap: () async {
                try {
                  await SupabaseService.client
                      .from('profiles')
                      .update({'role': role})
                      .eq('id', user['id']);
                  ref.invalidate(usersProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    SangakToast.show(context, l10n.roleUpdated);
                  }
                } catch (e) {
                   if (context.mounted) SangakToast.show(context, 'Error: $e');
                }
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'admin': color = SangakColors.error; break;
      case 'staff': color = SangakColors.info; break;
      case 'delivery': color = SangakColors.primary; break;
      default: color = SangakColors.inkLight;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
