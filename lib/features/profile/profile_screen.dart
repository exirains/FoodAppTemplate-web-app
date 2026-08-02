import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangak/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_dialogs.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../services/supabase_service.dart';
import '../auth/auth_provider.dart';
import '../../features/home/home_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    setState(() => _isUploading = true);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;

      final fileFile = File(image.path);
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${user.id}/$fileName';

      await SupabaseService.client.storage.from('avatars').upload(path, fileFile);
      final avatarUrl = SupabaseService.client.storage.from('avatars').getPublicUrl(path);

      await SupabaseService.client.from('profiles').update({'avatar_url': avatarUrl}).eq('id', user.id);
      await ref.read(authProvider.notifier).updateMetadata({'avatar_url': avatarUrl});

      if (mounted) {
        SangakToast.show(context, l10n.profilePictureUpdated);
      }
    } catch (e) {
      if (mounted) {
        SangakToast.show(context, l10n.failedToUpdateProfilePicture);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _signOut() {
    final l10n = AppLocalizations.of(context);
    SangakConfirmDialog.show(
      context,
      title: l10n.signOut,
      message: l10n.signOutConfirmation,
      confirmLabel: l10n.signOut,
      cancelLabel: l10n.no,
      onConfirm: () => ref.read(authProvider.notifier).signOut(),
      isDestructive: true,
    );
  }

  Future<void> _showEditProfile(User user) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: user.userMetadata?['full_name'] as String? ?? '');
    final phoneController = TextEditingController(text: user.userMetadata?['phone'] as String? ?? '+90');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            SangakDimens.spacing24,
            SangakDimens.spacing24,
            SangakDimens.spacing24,
            MediaQuery.of(context).viewInsets.bottom + SangakDimens.spacing24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.editProfile, style: SangakTypography.h3(context)),
              const SizedBox(height: SangakDimens.spacing24),
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                decoration: InputDecoration(labelText: l10n.fullName),
              ),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  LengthLimitingTextInputFormatter(13),
                ],
                decoration: InputDecoration(labelText: l10n.phoneNumber),
              ),
              const SizedBox(height: SangakDimens.spacing24),
              SangakButton.primary(
                label: l10n.saveChanges,
                width: double.infinity,
                onPressed: () async {
                  final data = {
                    'full_name': nameController.text.trim(),
                    'phone': phoneController.text.trim(),
                  };
                  await SupabaseService.client.from('profiles').update(data).eq('id', user.id);
                  await ref.read(authProvider.notifier).updateMetadata(data);
                  if (context.mounted) Navigator.pop(context);
                  if (mounted) SangakToast.show(this.context, l10n.profileUpdated);
                },
              ),
            ],
          ),
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final l10n = AppLocalizations.of(context);
    final favoriteCount = ref.watch(favoriteCountProvider);

    if (user == null) return const SizedBox.shrink();
    
    // Role check for switcher
    final role = user.userMetadata?['role'] as String? ?? 'customer';
    final canSwitchRole = role != 'customer';

    return Scaffold(
      backgroundColor: SangakColors.background,
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          if (canSwitchRole)
            IconButton(
              onPressed: () => _showRoleSwitcher(context),
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: l10n.roleSwitch,
            ),
          IconButton(
            onPressed: () => _showEditProfile(user),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SangakDimens.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(user),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
                    style: SangakTypography.h2(context),
                  ),
                  Text(
                    user.email ?? '',
                    style: SangakTypography.bodyMedium(context).copyWith(color: SangakColors.inkLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            
            // Activity Section
            Text(l10n.activity, style: SangakTypography.title(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildActivityCard(Icons.favorite_rounded, l10n.favorites, '$favoriteCount', context)),
                const SizedBox(width: 16),
                Expanded(child: _buildActivityCard(Icons.shopping_bag_rounded, l10n.orders, '0', context)),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Account Section
            Text(l10n.account, style: SangakTypography.title(context)),
            const SizedBox(height: 16),
            _buildInfoTile(Icons.phone_outlined, l10n.phoneNumber, user.userMetadata?['phone'] ?? '-', context),
            const SizedBox(height: 12),
            _buildActionTile(Icons.location_on_outlined, l10n.deliveryAddress, () => context.push('/address-selection'), context),
            const SizedBox(height: 12),
            _buildActionTile(Icons.credit_card_outlined, l10n.paymentInfo, () {}, context),
            
            const SizedBox(height: 48),
            SangakButton.outlined(
              label: l10n.signOut,
              width: double.infinity,
              foregroundColor: SangakColors.error,
              borderColor: SangakColors.error,
              onPressed: _signOut,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showRoleSwitcher(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.roleSwitch, style: SangakTypography.h3(context)),
            const SizedBox(height: 24),
            _buildRoleItem(context, l10n.customerApp, Icons.person_outline, true),
            _buildRoleItem(context, l10n.adminPanel, Icons.admin_panel_settings_outlined, false),
            _buildRoleItem(context, l10n.deliveryPanel, Icons.delivery_dining_outlined, false),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleItem(BuildContext context, String label, IconData icon, bool isActive) {
    return ListTile(
      leading: Icon(icon, color: isActive ? SangakColors.primary : SangakColors.inkLight),
      title: Text(label, style: SangakTypography.title(context).copyWith(fontSize: 16)),
      trailing: isActive ? const Icon(Icons.check_circle, color: SangakColors.primary) : null,
      onTap: () => Navigator.pop(context),
    );
  }

  Widget _buildActivityCard(IconData icon, String label, String value, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        boxShadow: SangakDimens.shadowLow,
      ),
      child: Column(
        children: [
          Icon(icon, color: SangakColors.primary),
          const SizedBox(height: 8),
          Text(value, style: SangakTypography.h3(context)),
          Text(label, style: SangakTypography.caption(context)),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap, BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SangakDimens.radiusM),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SangakColors.surface,
          borderRadius: BorderRadius.circular(SangakDimens.radiusM),
          border: Border.all(color: SangakColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: SangakColors.primary, size: 22),
            const SizedBox(width: 16),
            Text(label, style: SangakTypography.title(context).copyWith(fontSize: 16)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: SangakColors.inkLight, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(User user) {
    final avatarUrl = user.userMetadata?['avatar_url'] as String?;

    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: SangakColors.surface,
              shape: BoxShape.circle,
              boxShadow: SangakDimens.shadowMedium,
              border: Border.all(color: SangakColors.primary, width: 2),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.person_rounded, size: 64, color: SangakColors.border),
                    )
                  : const Icon(Icons.person_rounded, size: 64, color: SangakColors.border),
            ),
          ),
          if (_isUploading)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploading ? null : _pickAndUploadAvatar,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: SangakColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SangakColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: SangakColors.primary, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: SangakTypography.caption(context)),
              Text(value, style: SangakTypography.title(context).copyWith(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
