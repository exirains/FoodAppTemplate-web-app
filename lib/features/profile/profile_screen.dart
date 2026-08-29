import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:babka/l10n/app_localizations.dart';
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
        BabkaToast.show(context, l10n.profilePictureUpdated);
      }
    } catch (e) {
      if (mounted) {
        BabkaToast.show(context, l10n.failedToUpdateProfilePicture);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _signOut() {
    final l10n = AppLocalizations.of(context);
    BabkaConfirmDialog.show(
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
                color: BabkaColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(BabkaDimens.spacing32),
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
                              color: BabkaColors.border,
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
                                color: BabkaColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_outline_rounded, color: BabkaColors.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Text(l10n.editProfile, style: BabkaTypography.h2(context)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        BabkaTextField(
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
                        BabkaTextField(
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
                        BabkaButton.primary(
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
                                  BabkaToast.show(context, l10n.profileUpdated);
                                }
                              }
                            } catch (e) {
                              debugPrint('Error updating profile: $e');
                              if (modalContext.mounted) {
                                BabkaToast.show(modalContext, l10n.networkError);
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
      backgroundColor: BabkaColors.background,
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
        padding: const EdgeInsets.all(BabkaDimens.spacing24),
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
                        style: BabkaTypography.h2(context),
                      ),
                      const SizedBox(width: 8),
                      UserRoleTag(role: profile?.role ?? 'customer'),
                    ],
                  ),
                  Text(
                    user.email ?? '',
                    style: BabkaTypography.bodyMedium(context).copyWith(color: BabkaColors.inkLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Loyalty Bar
            _buildLoyaltyBar(context, ref),
            const SizedBox(height: 32),
            
            Text(l10n.activity, style: BabkaTypography.title(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildActivityCard(Icons.favorite_rounded, l10n.favorites, '$favoriteCount', context, onTap: () => context.push('/favorites'))),
                const SizedBox(width: 16),
                Expanded(child: _buildActivityCard(Icons.shopping_bag_rounded, l10n.orders, '$orderCount', context, onTap: () => context.push('/orders'))),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Text(l10n.account, style: BabkaTypography.title(context)),
            const SizedBox(height: 16),
            if (!AuthValidators.hasValidPhoneNumber(user.userMetadata?['phone'] as String?))
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BabkaColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
                    border: Border.all(color: BabkaColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: BabkaColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.addPhoneToOrder,
                          style: BabkaTypography.bodySmall(context).copyWith(
                            color: BabkaColors.error,
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
            
            const SizedBox(height: 32),
            if (role == 'admin' || role == 'staff') ...[
              Text(l10n.notifications, style: BabkaTypography.title(context)),
              const SizedBox(height: 16),
              _buildNotificationToggle(
                l10n.newOrders,
                profile?.notificationsNewOrderEnabled ?? true,
                (value) async {
                  if (profile == null) return;
                  try {
                    await SupabaseService.client
                        .from('profiles')
                        .update({'notifications_new_order_enabled': value})
                        .eq('id', profile.id);
                    if (!context.mounted) return;
                    if (mounted) {
                      BabkaToast.show(context, l10n.settingsSaved);
                    }
                  } catch (e) {
                    debugPrint('🚨 NOTIFICATION TOGGLE ERROR: $e');
                    if (e is PostgrestException) {
                      debugPrint('   - Message: ${e.message}');
                      debugPrint('   - Code: ${e.code}');
                      debugPrint('   - Details: ${e.details}');
                      debugPrint('   - Hint: ${e.hint}');
                    }
                    if (mounted) {
                      if (!context.mounted) return;
                      BabkaToast.show(context, l10n.errorOccurred);
                    }
                  }
                },
                context,
              ),
              const SizedBox(height: 32),
            ],
            
            const SizedBox(height: 12),
            // Referral Section
            const ReferralSection(),

            const SizedBox(height: 48),
            BabkaButton.outlined(
              label: l10n.signOut,
              width: double.infinity,
              foregroundColor: BabkaColors.error,
              borderColor: BabkaColors.error.withValues(alpha: 0.3),
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
          color: BabkaColors.ink,
          borderRadius: BorderRadius.circular(20),
          boxShadow: BabkaDimens.shadowMedium,
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔥 ${l10n.streakDay(streak)}',
                  style: BabkaTypography.title(context).copyWith(color: Colors.white, fontSize: 14),
                ),
                Text(
                  l10n.memberLevel(level),
                  style: BabkaTypography.caption(context).copyWith(color: Colors.white70),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: BabkaColors.primary,
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
                      style: BabkaTypography.title(context).copyWith(color: Colors.white, fontSize: 14),
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
        color: BabkaColors.surface,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
        boxShadow: BabkaDimens.shadowLow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: BabkaColors.primary),
                const SizedBox(height: 8),
                Text(value, style: BabkaTypography.h3(context)),
                Text(label, style: BabkaTypography.caption(context)),
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
          borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BabkaColors.surface,
              borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
              border: Border.all(color: BabkaColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: BabkaColors.primary, size: 22),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: BabkaTypography.title(context).copyWith(fontSize: 16)),
                    if (value != null)
                      Text(
                        value,
                        textDirection: isPhone ? TextDirection.ltr : null,
                        style: BabkaTypography.bodySmall(context).copyWith(color: BabkaColors.inkLight),
                      ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Directionality.of(context) == TextDirection.rtl 
                      ? Icons.chevron_left 
                      : Icons.chevron_right, 
                  color: BabkaColors.inkLight, 
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(String label, bool value, ValueChanged<bool> onChanged, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: BabkaColors.surface,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
        border: Border.all(color: BabkaColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: BabkaColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: BabkaTypography.title(context).copyWith(fontSize: 16)),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: BabkaColors.primary,
          ),
        ],
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
              color: BabkaColors.surface,
              shape: BoxShape.circle,
              boxShadow: BabkaDimens.shadowMedium,
              border: Border.all(color: BabkaColors.primary, width: 2),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.person_rounded, size: 64, color: BabkaColors.border),
                    )
                  : const Icon(Icons.person_rounded, size: 64, color: BabkaColors.border),
            ),
          ),
          if (_isUploading)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isUploading ? null : _pickAndUploadAvatar,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BabkaColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
