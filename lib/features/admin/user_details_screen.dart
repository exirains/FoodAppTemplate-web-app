import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/widgets/sangak_dialogs.dart';
import '../../shared/widgets/sangak_text_field.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/user_role_tag.dart';
import '../../models/order.dart';
import '../../models/address.dart';
import '../../models/bread.dart';
import '../../services/order_repository.dart';

import '../../core/localization/sangak_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import 'user_management_screen.dart';

final userDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final client = SupabaseService.client;
  
  // Fetch Profile
  final profileRes = await client.from('profiles').select().eq('id', userId).single();
  
  // Fetch Orders using robust join query
  final List<OrderModel> orders = await ref.read(sangakOrderRepositoryProvider).getMyOrders(userId);
  
  // Fetch Saved Addresses (from user_addresses table)
  final addressesRes = await client.from('user_addresses').select().eq('user_id', userId);
  final savedAddresses = (addressesRes as List).map((e) => Address.fromJson(Map<String, dynamic>.from(e as Map))).toList();

  // Extract unique addresses from orders for "Recently Used"
  final List<Address> orderAddresses = [];
  for (final order in orders) {
    final addr = Address.fromJson(order.addressSnapshot);
    if (!orderAddresses.any((a) => a.fullAddress == addr.fullAddress)) {
      orderAddresses.add(addr);
    }
  }
  
  // Fetch Favorites (mapped to Bread objects)
  final favoritesRes = await client
      .from('favorites')
      .select('*, products:product_id(*, product_translations(*))')
      .eq('user_id', userId);
      
  // Fetch Assigned Orders (for drivers)
  List<OrderModel> assignedOrders = [];
  if (profileRes['role'] == 'delivery') {
    assignedOrders = await ref.read(sangakOrderRepositoryProvider).getAssignedOrders(userId);
  }

  return {
    'profile': profileRes,
    'orders': orders,
    'saved_addresses': savedAddresses,
    'recent_addresses': orderAddresses,
    'favorites': (favoritesRes as List)
        .where((e) => e['products'] != null)
        .map((e) => Bread.fromJson(Map<String, dynamic>.from(e['products'] as Map)))
        .toList(),
    'assigned_orders': assignedOrders,
  };
});

class UserDetailsScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserDetailsScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  String? _currentRole;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Tab controller will be initialized when data arrives
  }

  Future<void> _pickAndUploadAvatar(String userId) async {
    final l10n = AppLocalizations.of(context);
    
    final confirmed = await SangakConfirmDialog.show(
      context,
      title: l10n.editProfile,
      message: l10n.confirmChangeAvatar,
      confirmLabel: l10n.save,
      cancelLabel: l10n.cancel,
      onConfirm: () {},
    );

    if (confirmed != true) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;
    if (!mounted) return;

    setState(() => _isUploading = true);

    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'admin_overrides/$fileName';
      final bytes = await image.readAsBytes();

      await SupabaseService.client.storage.from('avatars').uploadBinary(
        path, 
        bytes,
        fileOptions: const sb.FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      
      final avatarUrl = SupabaseService.client.storage.from('avatars').getPublicUrl(path);

      await SupabaseService.client.from('profiles').update({'avatar_url': avatarUrl}).eq('id', userId);

      if (mounted) {
        SangakToast.show(context, l10n.profilePictureUpdated);
        ref.invalidate(userDetailProvider(widget.userId));
        ref.invalidate(usersProvider);
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      if (mounted) {
        SangakToast.show(context, l10n.failedToUpdateProfilePicture);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _initTabController(String role) {
    final length = role == 'delivery' ? 4 : 3;
    if (_tabController == null) {
      _currentRole = role;
      _tabController = TabController(length: length, vsync: this);
    } else if (_currentRole != role) {
      // Role changed, need new controller
      final oldController = _tabController;
      _currentRole = role;
      _tabController = TabController(length: length, vsync: this);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController?.dispose();
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDetailProvider(widget.userId));
    final l10n = AppLocalizations.of(context);

    return RoleGuard(
      allowedRoles: const ['admin'],
      child: Scaffold(
        backgroundColor: SangakColors.background,
        appBar: AppBar(
          title: Text(l10n.profile),
          actions: [
            userAsync.when(
              data: (data) => IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showEditDialog(data['profile']),
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
        body: userAsync.when(
          data: (data) {
            final profile = data['profile'];
            final orders = data['orders'] as List<OrderModel>;
            final savedAddresses = data['saved_addresses'] as List<Address>;
            final recentAddresses = data['recent_addresses'] as List<Address>;
            final favorites = data['favorites'] as List<Bread>;
            final assignedOrders = data['assigned_orders'] as List<OrderModel>? ?? [];
            final isActive = profile['is_active'] ?? true;
            final isDriver = profile['role'] == 'delivery';
            
            _initTabController(profile['role'] ?? 'customer');

            return Column(
              children: [
                _buildHeader(profile, isActive),
                TabBar(
                  controller: _tabController,
                  isScrollable: isDriver,
                  labelColor: SangakColors.primary,
                  unselectedLabelColor: SangakColors.inkLight,
                  indicatorColor: SangakColors.primary,
                  tabs: [
                    if (isDriver) Tab(text: l10n.myTasks),
                    Tab(text: l10n.orders),
                    Tab(text: l10n.address),
                    Tab(text: l10n.favorites),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      if (isDriver) _buildAssignedOrdersList(assignedOrders),
                      _buildOrdersList(orders),
                      _buildAddressesList(savedAddresses, recentAddresses),
                      _buildFavoritesList(favorites),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text(l10n.errorOccurred)),
        ),
        bottomNavigationBar: userAsync.when(
          data: (data) => _buildBottomBar(data['profile']),
          loading: () => null,
          error: (error, stack) => null,
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> profile, bool isActive) {
    final l10n = AppLocalizations.of(context);
    final createdAt = DateTime.parse(profile['created_at']).toLocal();
    final joinedDate = DateFormat('MMM dd, yyyy').format(createdAt);
    final avatarUrl = profile['avatar_url'] as String?;
    final fullName = profile['full_name'] ?? l10n.guest;

    return Container(
      color: SangakColors.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: SangakColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: SangakColors.border),
                    ),
                    child: ClipOval(
                      child: avatarUrl != null
                          ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover)
                          : Center(child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: SangakColors.primary))),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploading ? null : () => _pickAndUploadAvatar(profile['id']),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: SangakColors.primary, shape: BoxShape.circle),
                        child: _isUploading 
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName, style: SangakTypography.h2(context)),
                    Text(profile['email'] ?? '', style: SangakTypography.bodyMedium(context).copyWith(color: SangakColors.inkLight)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        UserRoleTag(role: profile['role'] ?? 'customer'),
                        const SizedBox(width: 8),
                        _buildStatusChip(isActive),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.joinedDate, style: SangakTypography.caption(context)),
              Text(joinedDate, style: SangakTypography.title(context).copyWith(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    final l10n = AppLocalizations.of(context);
    final color = isActive ? SangakColors.success : SangakColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isActive ? l10n.statusActive.toUpperCase() : l10n.statusDisabled.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    final l10n = AppLocalizations.of(context);
    if (orders.isEmpty) return Center(child: Text(l10n.noOrdersFound));
    
    final lang = ref.watch(localeProvider).languageCode;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(order: order, lang: lang, isAssigned: false);
      },
    );
  }

  Widget _buildAssignedOrdersList(List<OrderModel> orders) {
    final l10n = AppLocalizations.of(context);
    if (orders.isEmpty) return Center(child: Text(l10n.noActiveDeliveries));
    
    final lang = ref.watch(localeProvider).languageCode;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(order: order, lang: lang, isAssigned: true);
      },
    );
  }

  Widget _buildAddressesList(List<Address> saved, List<Address> recent) {
    final l10n = AppLocalizations.of(context);
    if (saved.isEmpty && recent.isEmpty) return Center(child: Text(l10n.noAddressesFound));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (saved.isNotEmpty) ...[
          Text(l10n.userAddresses.toUpperCase(), style: SangakTypography.caption(context).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...saved.map((addr) => _buildAddressCard(addr)),
          const SizedBox(height: 24),
        ],
        if (recent.isNotEmpty) ...[
          Text(l10n.lastUsedAddresses.toUpperCase(), style: SangakTypography.caption(context).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...recent.map((addr) => _buildAddressCard(addr, isRecent: true)),
        ],
      ],
    );
  }

  Widget _buildAddressCard(Address addr, {bool isRecent = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isRecent ? SangakColors.border.withValues(alpha: 0.5) : SangakColors.border),
      ),
      child: ListTile(
        leading: Icon(
          isRecent ? Icons.history_rounded : Icons.location_on_outlined, 
          color: isRecent ? SangakColors.inkLight : SangakColors.primary,
        ),
        title: Text(addr.title, style: SangakTypography.title(context).copyWith(fontSize: 14)),
        subtitle: Text(addr.fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _buildFavoritesList(List<Bread> favorites) {
    final l10n = AppLocalizations.of(context);
    if (favorites.isEmpty) return Center(child: Text(l10n.noFavoritesFound));
    
    final lang = ref.watch(localeProvider).languageCode;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bread = favorites[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: SangakColors.border),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(imageUrl: bread.imageUrl, width: 48, height: 48, fit: BoxFit.cover),
            ),
            title: Text(bread.localizedName(lang), style: SangakTypography.title(context).copyWith(fontSize: 14)),
            subtitle: Text(SangakNumberFormatter.formatCurrency(bread.price, lang)),
            onTap: () => context.push('/product-details', extra: bread),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> profile) {
    final l10n = AppLocalizations.of(context);
    final isActive = profile['is_active'] ?? true;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SangakButton.primary(
          label: isActive ? l10n.disableAccount : l10n.enableAccount,
          backgroundColor: isActive ? SangakColors.error : SangakColors.success,
          onPressed: () => _confirmStatusChange(profile, !isActive),
        ),
      ),
    );
  }

  void _confirmStatusChange(Map<String, dynamic> user, bool newStatus) {
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
          ref.invalidate(userDetailProvider(widget.userId));
          ref.invalidate(usersProvider);
          if (mounted) SangakToast.show(context, l10n.userStatusUpdated);
        } catch (e) {
          if (mounted) SangakToast.show(context, 'Error: $e');
        }
      },
      isDestructive: !newStatus,
    );
  }

  void _showEditDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => _AdminEditUserDialog(
        user: user, 
        onRefresh: () {
          ref.invalidate(userDetailProvider(widget.userId));
          ref.invalidate(usersProvider);
        }
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final String lang;
  final bool isAssigned;

  const _OrderCard({
    required this.order,
    required this.lang,
    required this.isAssigned,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SangakColors.border),
      ),
      child: ListTile(
        onTap: () => context.push('/admin/orders/${order.id}'),
        title: Row(
          children: [
            Text(order.orderNumber, style: SangakTypography.title(context).copyWith(fontSize: 14)),
            if (isAssigned) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: SangakColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(l10n.driver.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: SangakColors.primary)),
              ),
            ],
          ],
        ),
        subtitle: Text(DateFormat('MMM dd, HH:mm').format(order.createdAt.toLocal())),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(SangakNumberFormatter.formatCurrency(order.totalPrice, lang), style: const TextStyle(fontWeight: FontWeight.bold)),
            _StatusChip(status: order.status),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color color;
    switch (status) {
      case OrderStatus.pending: color = SangakColors.warning; break;
      case OrderStatus.preparing:
      case OrderStatus.confirmed: color = SangakColors.info; break;
      case OrderStatus.ready: color = SangakColors.accent; break;
      case OrderStatus.outForDelivery: color = SangakColors.primary; break;
      case OrderStatus.delivered: color = SangakColors.success; break;
      case OrderStatus.cancelled: color = SangakColors.error; break;
    }

    return Text(
      status.localizedLabel(l10n).toUpperCase(),
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
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
