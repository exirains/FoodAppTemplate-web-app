import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/widgets/user_role_tag.dart';

enum UserSortOption { newestFirst, oldestFirst, alphabetical }

final usersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('profiles')
      .select()
      .order('created_at', ascending: false);
  return (response as List).cast<Map<String, dynamic>>();
});

final userSearchQueryProvider = StateProvider<String>((ref) => '');
final userRoleFilterProvider = StateProvider<String>((ref) => 'all');
final userDisabledFilterProvider = StateProvider<bool>((ref) => false);
final userSortOptionProvider = StateProvider<UserSortOption>((ref) => UserSortOption.newestFirst);

final filteredUsersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final usersAsync = ref.watch(usersProvider);
  final searchQuery = ref.watch(userSearchQueryProvider).toLowerCase();
  final roleFilter = ref.watch(userRoleFilterProvider);
  final showDisabledOnly = ref.watch(userDisabledFilterProvider);
  final sortOption = ref.watch(userSortOptionProvider);

  return usersAsync.when(
    data: (users) {
      var filtered = users.where((u) {
        final name = (u['full_name'] as String? ?? '').toLowerCase();
        final email = (u['email'] as String? ?? '').toLowerCase();
        final matchesSearch = name.contains(searchQuery) || email.contains(searchQuery);
        
        final matchesRole = roleFilter == 'all' || u['role'] == roleFilter;
        final matchesDisabled = !showDisabledOnly || (u['is_active'] ?? true) == false;
        
        return matchesSearch && matchesRole && matchesDisabled;
      }).toList();

      switch (sortOption) {
        case UserSortOption.newestFirst:
          filtered.sort((a, b) => b['created_at'].compareTo(a['created_at']));
          break;
        case UserSortOption.oldestFirst:
          filtered.sort((a, b) => a['created_at'].compareTo(b['created_at']));
          break;
        case UserSortOption.alphabetical:
          filtered.sort((a, b) => (a['full_name'] ?? '').compareTo(b['full_name'] ?? ''));
          break;
      }

      return filtered;
    },
    loading: () => [],
    error: (error, stack) => [],
  );
});

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final filteredUsers = ref.watch(filteredUsersProvider);
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
            _buildSearchAndFilters(context, ref, l10n),
            Expanded(
              child: usersAsync.when(
                data: (_) {
                  if (filteredUsers.isEmpty) {
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
                    itemCount: filteredUsers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _UserListItem(
                      user: filteredUsers[index],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text(l10n.errorOccurred)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Container(
      color: SangakColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: SangakColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SangakColors.border),
                  ),
                  child: TextField(
                    onChanged: (v) => ref.read(userSearchQueryProvider.notifier).state = v,
                    decoration: InputDecoration(
                      hintText: l10n.searchByPlaceholder,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: SangakColors.inkLight),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  ref.read(userSearchQueryProvider.notifier).state = '';
                  ref.read(userRoleFilterProvider.notifier).state = 'all';
                  ref.read(userDisabledFilterProvider.notifier).state = false;
                  ref.read(userSortOptionProvider.notifier).state = UserSortOption.newestFirst;
                },
                icon: const Icon(Icons.filter_alt_off_rounded, color: SangakColors.error),
                tooltip: l10n.resetFilters,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(l10n.categories.toUpperCase(), style: SangakTypography.caption(context).copyWith(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.sort_rounded, color: SangakColors.primary, size: 20),
                onPressed: () => _showSortDialog(context, ref, l10n),
                tooltip: l10n.sortBy,
              ),
              IconButton(
                icon: Icon(
                  ref.watch(userDisabledFilterProvider) ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: ref.watch(userDisabledFilterProvider) ? SangakColors.error : SangakColors.inkLight,
                  size: 20,
                ),
                onPressed: () => ref.read(userDisabledFilterProvider.notifier).update((s) => !s),
                tooltip: l10n.filterDisabledOnly,
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _RoleFilterChip(label: l10n.filterAll, value: 'all'),
                const SizedBox(width: 8),
                _RoleFilterChip(label: l10n.filterAdmins, value: 'admin'),
                const SizedBox(width: 8),
                _RoleFilterChip(label: l10n.filterStaff, value: 'staff'),
                const SizedBox(width: 8),
                _RoleFilterChip(label: l10n.filterDelivery, value: 'delivery'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.sortBy, style: SangakTypography.h3(context)),
            const SizedBox(height: 16),
            _SortTile(label: l10n.newestFirst, value: UserSortOption.newestFirst),
            _SortTile(label: l10n.oldestFirst, value: UserSortOption.oldestFirst),
            _SortTile(label: l10n.alphabetical, value: UserSortOption.alphabetical),
          ],
        ),
      ),
    );
  }
}

class _RoleFilterChip extends ConsumerWidget {
  final String label;
  final String value;
  const _RoleFilterChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(userRoleFilterProvider);
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => ref.read(userRoleFilterProvider.notifier).state = value,
      behavior: HitTestBehavior.opaque,
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

class _SortTile extends ConsumerWidget {
  final String label;
  final UserSortOption value;
  const _SortTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(userSortOptionProvider);
    return ListTile(
      title: Text(label),
      trailing: selected == value ? const Icon(Icons.check_circle, color: SangakColors.primary) : null,
      onTap: () {
        ref.read(userSortOptionProvider.notifier).state = value;
        Navigator.pop(context);
      },
    );
  }
}

class _UserListItem extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserListItem({required this.user});

  @override
  Widget build(BuildContext context) {
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
          // View Information Button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => context.push('/admin/users/${user['id']}'),
              icon: const Icon(Icons.info_outline_rounded, size: 18),
              label: Text(l10n.viewInformation),
              style: TextButton.styleFrom(
                foregroundColor: SangakColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
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
