import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/widgets/sangak_dialogs.dart';
import '../../shared/widgets/sangak_text_field.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/user_role_tag.dart';

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
  String _searchQuery = '';
  bool _showDisabledOnly = false;
  String _selectedRoleFilter = 'all'; // 'all', 'admin', 'staff', 'delivery', 'customer'

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
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildSearchAndFilters(l10n),
            Expanded(
              child: usersAsync.when(
                data: (users) {
                  final filtered = users.where((u) {
                    final name = (u['full_name'] as String? ?? '').toLowerCase();
                    final email = (u['email'] as String? ?? '').toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    final matchesSearch = name.contains(query) || email.contains(query);
                    
                    final matchesRole = _selectedRoleFilter == 'all' || u['role'] == _selectedRoleFilter;
                    final matchesDisabled = !_showDisabledOnly || (u['is_active'] ?? true) == false;
                    
                    return matchesSearch && matchesRole && matchesDisabled;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 64, color: SangakColors.border),
                          const SizedBox(height: 16),
                          Text(l10n.noUsersFound, style: SangakTypography.bodyLarge(context).copyWith(color: SangakColors.inkLight)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(SangakDimens.spacing24),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _UserListItem(
                      user: filtered[index],
                      onRefresh: () => ref.invalidate(usersProvider),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(AppLocalizations l10n) {
    return Container(
      color: SangakColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: SangakColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SangakColors.border),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: l10n.searchByPlaceholder,
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: SangakColors.inkLight),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Role & Disabled Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.filterAll,
                  isSelected: _selectedRoleFilter == 'all',
                  onTap: () => setState(() => _selectedRoleFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.filterAdmins,
                  isSelected: _selectedRoleFilter == 'admin',
                  onTap: () => setState(() => _selectedRoleFilter = 'admin'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.filterStaff,
                  isSelected: _selectedRoleFilter == 'staff',
                  onTap: () => setState(() => _selectedRoleFilter = 'staff'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.filterDelivery,
                  isSelected: _selectedRoleFilter == 'delivery',
                  onTap: () => setState(() => _selectedRoleFilter = 'delivery'),
                ),
                const SizedBox(width: 16),
                const VerticalDivider(width: 1),
                const SizedBox(width: 16),
                FilterChip(
                  label: Text(l10n.filterDisabledOnly),
                  selected: _showDisabledOnly,
                  onSelected: (v) => setState(() => _showDisabledOnly = v),
                  selectedColor: SangakColors.error.withValues(alpha: 0.1),
                  checkmarkColor: SangakColors.error,
                  labelStyle: TextStyle(
                    color: _showDisabledOnly ? SangakColors.error : SangakColors.inkLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? SangakColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? SangakColors.primary : SangakColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : SangakColors.inkLight,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _UserListItem extends ConsumerWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRefresh;

  const _UserListItem({required this.user, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isActive = user['is_active'] ?? true;
    final avatarUrl = user['avatar_url'] as String?;
    final fullName = user['full_name'] ?? 'No Name';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowLow,
        border: Border.all(color: isActive ? SangakColors.border : SangakColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: SangakColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: SangakColors.border),
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => const Icon(Icons.person, color: SangakColors.border),
                        )
                      : Center(
                          child: Text(
                            fullName[0].toUpperCase(),
                            style: const TextStyle(color: SangakColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            fullName, 
                            style: SangakTypography.h3(context).copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        UserRoleTag(role: user['role'] ?? 'customer'),
                      ],
                    ),
                    Text(
                      user['email'] ?? '', 
                      style: SangakTypography.caption(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              _StatusLabel(isActive: isActive),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Actions Row
          Row(
            children: [
              // EDIT PROFILE ON LEFT
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _showAdminEditDialog(context, ref),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.editProfileButton),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: SangakColors.ink,
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // DISABLE ON RIGHT
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _confirmStatusChange(context, ref, !isActive),
                  icon: Icon(isActive ? Icons.block_flipped : Icons.check_circle_outline_rounded, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(isActive ? l10n.disableAccount : l10n.enableAccount),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: isActive ? SangakColors.error : SangakColors.success,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmStatusChange(BuildContext context, WidgetRef ref, bool newStatus) {
    final l10n = AppLocalizations.of(context);
    final statusText = newStatus ? l10n.enable : l10n.disable;
    
    SangakConfirmDialog.show(
      context,
      title: newStatus ? l10n.enableAccount : l10n.disableAccount,
      message: l10n.confirmStatusChange(statusText, user['full_name'] ?? 'User'),
      confirmLabel: newStatus ? l10n.enableAccount : l10n.disableAccount,
      cancelLabel: l10n.cancel,
      onConfirm: () async {
        try {
          await SupabaseService.client
              .from('profiles')
              .update({'is_active': newStatus})
              .eq('id', user['id']);
          onRefresh();
          if (context.mounted) SangakToast.show(context, l10n.userStatusUpdated);
        } catch (e) {
          if (context.mounted) SangakToast.show(context, 'Error: $e');
        }
      },
      isDestructive: !newStatus,
    );
  }

  void _showAdminEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AdminEditUserDialog(user: user, onRefresh: onRefresh),
    );
  }
}

class _AdminEditUserDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRefresh;
  const _AdminEditUserDialog({required this.user, required this.onRefresh});

  @override
  ConsumerState<_AdminEditUserDialog> createState() => _AdminEditUserDialogState();
}

class _AdminEditUserDialogState extends ConsumerState<_AdminEditUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedRole;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['full_name']);
    _phoneController = TextEditingController(text: widget.user['phone'] ?? widget.user['phone_number']);
    _selectedRole = widget.user['role'] ?? 'customer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roles = ['customer', 'staff', 'delivery', 'admin'];

    return AlertDialog(
      title: Text(l10n.editUserProfile),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SangakTextField(label: l10n.fullName, controller: _nameController),
            const SizedBox(height: 16),
            SangakTextField(label: l10n.phoneNumber, controller: _phoneController, keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l10n.roleSwitch.toUpperCase(), style: SangakTypography.caption(context).copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SangakColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        SangakButton.primary(
          label: l10n.save,
          width: 100,
          isLoading: _isSaving,
          onPressed: () async {
            setState(() => _isSaving = true);
            try {
              await SupabaseService.client.from('profiles').update({
                'full_name': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'role': _selectedRole,
              }).eq('id', widget.user['id']);
              
              widget.onRefresh();
              if (context.mounted) {
                SangakToast.show(context, l10n.profileUpdated);
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) SangakToast.show(context, 'Error: $e');
            } finally {
              if (mounted) setState(() => _isSaving = false);
            }
          },
        ),
      ],
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final bool isActive;
  const _StatusLabel({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Text(
      isActive ? l10n.statusActive.toUpperCase() : l10n.statusDisabled.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: isActive ? SangakColors.success : SangakColors.error,
        letterSpacing: 0.5,
      ),
    );
  }
}
