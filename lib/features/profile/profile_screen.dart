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
import '../../shared/widgets/sangak_text_field.dart';
import '../../shared/widgets/sangak_dialogs.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/utils/role_switcher.dart';
import '../../shared/utils/action_guard.dart';
import '../../shared/widgets/user_role_tag.dart';
import '../auth/auth_validators.dart';
import '../../services/supabase_service.dart';
import '../auth/auth_provider.dart';
import '../auth/profile_provider.dart';
import '../loyalty/loyalty_provider.dart';
import '../../features/home/home_provider.dart';
import '../orders/orders_provider.dart';
import 'widgets/referral_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadAvatar() async {
    if (!ActionGuard.check(context, ref)) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    setState(() => _isUploading = true);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;

      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${user.id}/$fileName';

      final bytes = await image.readAsBytes();

      await SupabaseService.client.storage.from('avatars').uploadBinary(
        path, 
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      
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
    final phoneController = TextEditingController(text: user.userMetadata?['phone'] as String? ?? '+90 ');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final viewInsets = MediaQuery.of(context).viewInsets;
            
            return Container(
              decoration: const BoxDecoration(
                color: SangakColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(SangakDimens.spacing32),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: SangakColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: SangakColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_outline_rounded, color: SangakColors.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Text(l10n.editProfile, style: SangakTypography.h2(context)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SangakTextField(
                          label: l10n.fullName,
                          hintText: l10n.enterFullName,
                          controller: nameController,
                          leadingIcon: Icons.badge_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return l10n.requiredField;
                            if (value.trim().length < 2) return l10n.nameTooShort;
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SangakTextField(
                          label: l10n.phoneNumber,
                          hintText: '+90 5XX XXX XX XX',
                          controller: phoneController,
                          leadingIcon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [_TurkeyPhoneInputFormatter()],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty || AuthValidators.isDefaultPrefixOnly(value)) return l10n.requiredField;
                            final error = AuthValidators.validatePhoneNumber(value);
                            if (error != null) return l10n.invalidPhoneNumber;
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
                        SangakButton.primary(
                          label: l10n.saveChanges,
                          width: double.infinity,
                          isLoading: isSaving,
                          onPressed: isSaving ? null : () async {
                            if (!ActionGuard.check(context, ref)) return;
                            if (!formKey.currentState!.validate()) return;
                            
                            setModalState(() => isSaving = true);
                            
                            try {
                              final data = {
                                'full_name': nameController.text.trim(),
                                'phone': phoneController.text.trim(),
                              };
                              
                              await SupabaseService.client.from('profiles').update(data).eq('id', user.id);
                              
                              await ref.read(authProvider.notifier).updateMetadata(data);
                              
                              if (modalContext.mounted) {
                                Navigator.of(modalContext).pop();
                                if (mounted) {
                                  SangakToast.show(context, l10n.profileUpdated);
                                }
                              }
                            } catch (e) {
                              debugPrint('Error updating profile: $e');
                              if (modalContext.mounted) {
                                SangakToast.show(modalContext, l10n.networkError);
                              }
                            } finally {
                              if (modalContext.mounted) {
                                setModalState(() => isSaving = false);
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.asData?.value;
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    
    final l10n = AppLocalizations.of(context);
    final favoriteCount = ref.watch(favoriteCountProvider);
    final ordersAsync = ref.watch(myOrdersProvider);
    final orderCount = ordersAsync.value?.length ?? 0;

    if (user == null) return const SizedBox.shrink();
    
    final role = profile?.role ?? 'customer';
    final canSwitchRole = role != 'customer';

    return Scaffold(
      backgroundColor: SangakColors.background,
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          if (canSwitchRole)
            IconButton(
              onPressed: () => RoleSwitcher.show(context, role),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
                        style: SangakTypography.h2(context),
                      ),
                      const SizedBox(width: 8),
                      UserRoleTag(role: profile?.role ?? 'customer'),
                    ],
                  ),
                  Text(
                    user.email ?? '',
                    style: SangakTypography.bodyMedium(context).copyWith(color: SangakColors.inkLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Loyalty Bar
            _buildLoyaltyBar(context, ref),
            const SizedBox(height: 32),
            
            Text(l10n.activity, style: SangakTypography.title(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildActivityCard(Icons.favorite_rounded, l10n.favorites, '$favoriteCount', context, onTap: () => context.push('/favorites'))),
                const SizedBox(width: 16),
                Expanded(child: _buildActivityCard(Icons.shopping_bag_rounded, l10n.orders, '$orderCount', context, onTap: () => context.push('/orders'))),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Text(l10n.account, style: SangakTypography.title(context)),
            const SizedBox(height: 16),
            if (!AuthValidators.hasValidPhoneNumber(user.userMetadata?['phone'] as String?))
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SangakColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(SangakDimens.radiusM),
                    border: Border.all(color: SangakColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: SangakColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.addPhoneToOrder,
                          style: SangakTypography.bodySmall(context).copyWith(
                            color: SangakColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            _buildActionTile(
              Icons.phone_outlined, 
              l10n.phoneNumber, 
              () => _showEditProfile(user), 
              context,
              value: user.userMetadata?['phone'] ?? '-',
              isPhone: true,
            ),
            const SizedBox(height: 12),
            _buildActionTile(Icons.location_on_outlined, l10n.deliveryAddress, () => context.push('/address-selection?from=profile'), context),
            const SizedBox(height: 12),
            _buildActionTile(Icons.credit_card_outlined, l10n.paymentInfo, () => context.push('/payment-selection?from=profile'), context),
            
            const SizedBox(height: 12),
            // Referral Section
            const ReferralSection(),

            const SizedBox(height: 48),
            SangakButton.outlined(
              label: l10n.signOut,
              width: double.infinity,
              foregroundColor: SangakColors.error,
              borderColor: SangakColors.error.withValues(alpha: 0.3),
              onPressed: _signOut,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyBar(BuildContext context, WidgetRef ref) {
    final loyaltyAsync = ref.watch(userLoyaltyProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context);
    
    final profile = profileAsync.value;
    final streak = profile?.currentStreak ?? 0;

    return loyaltyAsync.when(
      data: (loyalty) => _buildLoyaltyContent(context, loyalty?.currentPoints ?? 0, loyalty?.loyaltyLevel ?? "Bronze", streak, l10n),
      loading: () => _buildLoyaltyContent(context, 0, "...", streak, l10n, isLoading: true),
      error: (e, s) {
        debugPrint('🚨 Loyalty Bar Error: $e');
        return _buildLoyaltyContent(context, 0, "Error", streak, l10n);
      },
    );
  }

  Widget _buildLoyaltyContent(BuildContext context, int points, String level, int streak, AppLocalizations l10n, {bool isLoading = false}) {
    return InkWell(
      onTap: () => context.push('/loyalty'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: SangakColors.ink,
          borderRadius: BorderRadius.circular(20),
          boxShadow: SangakDimens.shadowMedium,
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔥 ${l10n.streakDay(streak)}',
                  style: SangakTypography.title(context).copyWith(color: Colors.white, fontSize: 14),
                ),
                Text(
                  l10n.memberLevel(level),
                  style: SangakTypography.caption(context).copyWith(color: Colors.white70),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: SangakColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  if (isLoading)
                    const SizedBox(width: 20, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  else
                    Text(
                      '$points ${l10n.pts}',
                      style: SangakTypography.title(context).copyWith(color: Colors.white, fontSize: 14),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(IconData icon, String label, String value, BuildContext context, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        boxShadow: SangakDimens.shadowLow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SangakDimens.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: SangakColors.primary),
                const SizedBox(height: 8),
                Text(value, style: SangakTypography.h3(context)),
                Text(label, style: SangakTypography.caption(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap, BuildContext context, {String? value, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SangakDimens.radiusM),
          child: Ink(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: SangakTypography.title(context).copyWith(fontSize: 16)),
                    if (value != null)
                      Text(
                        value,
                        textDirection: isPhone ? TextDirection.ltr : null,
                        style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.inkLight),
                      ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Directionality.of(context) == TextDirection.rtl 
                      ? Icons.chevron_left 
                      : Icons.chevron_right, 
                  color: SangakColors.inkLight, 
                  size: 20,
                ),
              ],
            ),
          ),
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
              behavior: HitTestBehavior.opaque,
              onTap: _isUploading ? null : _pickAndUploadAvatar,
              child: Ink(
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
}

class _TurkeyPhoneInputFormatter extends TextInputFormatter {
  static const _prefix = '+90 ';
  static const _maxNationalDigits = 10;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('90')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    
    if (digits.length > _maxNationalDigits) {
      digits = digits.substring(0, _maxNationalDigits);
    }

    var formatted = _prefix;
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6 || i == 8) {
        formatted += ' ';
      }
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
