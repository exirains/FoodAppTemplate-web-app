import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangak/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_dialogs.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../services/supabase_service.dart';
import '../auth/auth_provider.dart';

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

    setState(() => _isUploading = true);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;

      final fileFile = File(image.path);
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${user.id}/$fileName';

      // Upload to avatars bucket
      await SupabaseService.client.storage.from('avatars').upload(path, fileFile);

      // Get public URL
      final avatarUrl = SupabaseService.client.storage.from('avatars').getPublicUrl(path);

      // Update profile
      await SupabaseService.client.from('profiles').update({'avatar_url': avatarUrl}).eq('id', user.id);

      if (mounted) {
        SangakToast.show(context, 'Profile picture updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        SangakToast.show(context, 'Failed to update profile picture: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _signOut() {
    SangakConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of your Sangak account?',
      confirmLabel: 'Sign Out',
      cancelLabel: 'Cancel',
      onConfirm: () => ref.read(authProvider.notifier).signOut(),
      isDestructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final l10n = AppLocalizations.of(context);

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: SangakColors.background,
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded, color: SangakColors.error),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SangakDimens.spacing24),
        child: Column(
          children: [
            _buildAvatar(user),
            const SizedBox(height: 24),
            Text(
              user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
              style: SangakTypography.h2,
            ),
            Text(
              user.email ?? '',
              style: SangakTypography.bodyMedium.copyWith(color: SangakColors.inkLight),
            ),
            const SizedBox(height: 48),
            _buildInfoTile(Icons.phone_outlined, l10n.phoneNumber, user.userMetadata?['phone'] ?? '-'),
            const SizedBox(height: 16),
            _buildInfoTile(Icons.email_outlined, l10n.email, user.email ?? '-'),
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
                      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, size: 64, color: SangakColors.border),
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

  Widget _buildInfoTile(IconData icon, String label, String value) {
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
              Text(label, style: SangakTypography.caption),
              Text(value, style: SangakTypography.title.copyWith(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
