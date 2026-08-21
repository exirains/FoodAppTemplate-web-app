import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_validators.dart';
import '../auth/profile_provider.dart';
import '../basket/basket_provider.dart';
import 'home_provider.dart';
import 'tab_provider.dart';
import 'widgets/settings_bottom_sheet.dart';
import 'widgets/promotion_banners.dart';
import '../../core/localization/locale_provider.dart';
import '../../services/greeting_service.dart';
import '../../shared/utils/auth_gate.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/utils/action_guard.dart';
import '../../shared/widgets/category_chip.dart';
import '../../shared/widgets/hero_banner.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/quantity_selector.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_dialogs.dart';
import '../../shared/widgets/sangak_skeletons.dart';
import '../../shared/widgets/user_role_tag.dart';
import '../../core/localization/sangak_number_formatter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final breadsAsync = ref.watch(filteredBreadsProvider);
    final popularBreadsAsync = ref.watch(filteredPopularBreadsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final user = ref.watch(authProvider).asData?.value;
    final isGuest = user == null;
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;

    return Scaffold(
      backgroundColor: SangakColors.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Search
          SliverAppBar(
            floating: true,
            expandedHeight: 88,
            backgroundColor: SangakColors.background,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(GreetingService.getGreeting(context), style: SangakTypography.bodySmall(context)),
                        const SizedBox(height: 1),
                        if (!isGuest)
                          Row(
                            children: [
                              Text(
                                user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
                                style: SangakTypography.h3(context),
                              ),
                              const SizedBox(width: 8),
                              UserRoleTag(role: ref.watch(userProfileProvider).value?.role ?? 'customer'),
                            ],
                          ),
                        if (isGuest)
                          Padding(
                            padding: const EdgeInsets.only(top: 3.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                              decoration: BoxDecoration(
                                color: SangakColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.guest.toUpperCase(),
                                style: SangakTypography.caption(context).copyWith(
                                  color: SangakColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => SettingsBottomSheet.show(context),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: SangakColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: SangakDimens.shadowLow,
                        ),
                        child: const Icon(Icons.settings_outlined, color: SangakColors.ink, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(SangakDimens.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Banner
                  HeroBanner(
                    title: l10n.freshlyBakedSangak,
                    subtitle: l10n.heroSubtitle,
                    imageUrl: 'https://obealvlqkffozfigtobc.supabase.co/storage/v1/object/public/branding/top_banner_dark.jpg',
                  ),
                  const SizedBox(height: SangakDimens.spacing24),

                  const PromotionBanners(),
                  const SizedBox(height: SangakDimens.spacing24),

                  // Phone Number Warning Banner
                  if (!isGuest && 
                      !ref.watch(userProfileProvider).isLoading && 
                      !AuthValidators.hasValidPhoneNumber(ref.watch(userProfileProvider).value?.phoneNumber) &&
                      !AuthValidators.hasValidPhoneNumber(user.userMetadata?['phone'] as String?))
                    Padding(
                      padding: const EdgeInsets.only(bottom: SangakDimens.spacing24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SangakColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(SangakDimens.radiusL),
                          border: Border.all(color: SangakColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: SangakColors.warning,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.completeYourProfile,
                                    style: SangakTypography.title(context).copyWith(fontSize: 14),
                                  ),
                                  Text(
                                    l10n.addPhoneToOrder,
                                    style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.inkLight),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SangakButton.primary(
                              label: l10n.add,
                              width: 80,
                              onPressed: () => ref.read(tabProvider.notifier).state = 3, // Go to Profile
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Categories
                  Text(l10n.categories, style: SangakTypography.h3(context)),
                  const SizedBox(height: SangakDimens.spacing16),
                  categoriesAsync.when(
                    data: (categories) => SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero, // Reset padding
                        itemCount: categories.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(width: SangakDimens.spacing12),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsetsDirectional.only(start: 0),
                              child: CategoryChip(
                                label: l10n.all,
                                isSelected: selectedCategoryId == null,
                                onTap: () => ref.read(selectedCategoryIdProvider.notifier).state = null,
                              ),
                            );
                          }
                          final category = categories[index - 1];
                          return CategoryChip(
                            label: category.localizedName(lang),
                            isSelected: selectedCategoryId == category.id,
                            onTap: () => ref.read(selectedCategoryIdProvider.notifier).state = category.id,
                          );
                        },
                      ),
                    ),
                    loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
                    error: (error, stack) => Text(l10n.errorLoadingCategories),
                  ),
                  const SizedBox(height: SangakDimens.spacing32),

                  // Popular Today
                  if (popularBreadsAsync.value?.isNotEmpty ?? true)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.popularToday, style: SangakTypography.h3(context)),
                        TextButton(
                          onPressed: () => ref.read(tabProvider.notifier).state = 1,
                          child: Text(l10n.seeAll, style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.primary)),
                        ),
                      ],
                    ),
                  if (popularBreadsAsync.value?.isNotEmpty ?? true)
                    const SizedBox(height: SangakDimens.spacing16),
                ],
              ),
            ),
          ),

          // Bread Horizontal List
          if (popularBreadsAsync.value?.isNotEmpty ?? true)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 292, // Further reduced to prevent excessive height
                child: popularBreadsAsync.when(
                data: (breads) => ListView.separated(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: SangakDimens.spacing24),
                  scrollDirection: Axis.horizontal,
                  itemCount: breads.length,
                  separatorBuilder: (context, index) => const SizedBox(width: SangakDimens.spacing16),
                  itemBuilder: (context, index) {
                    final bread = breads[index];
                    final displayName = bread.localizedName(lang);
                    return ProductCard(
                      bread: bread,
                      name: displayName,
                      description: bread.localizedDescription(lang),
                      price: bread.price,
                      imageUrl: bread.imageUrl,
                      freshness: bread.freshness,
                      isFavorite: bread.isFavorite,
                      width: 190, // Slightly narrower
                      imageAspectRatio: 1, // Wider image (less tall)
                      onFavoriteToggle: () {
                        if (!ActionGuard.check(context, ref)) return;
                        AuthGate.run(
                          context,
                          ref,
                          action: () => ref.read(favoritesProvider.notifier).toggle(bread.id),
                          title: l10n.saveYourFavorites,
                          message: l10n.saveFavoritesMessage,
                        );
                      },
                      onAddToBasket: () {
                        if (!ActionGuard.check(context, ref)) return;
                        AuthGate.run(
                          context,
                          ref,
                          action: () {
                            ref.read(basketProvider.notifier).addItem(bread);
                            SangakToast.show(context, l10n.addedToBasket(displayName));
                          },
                        );
                      },
                    );
                  },
                ),
                loading: () => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: SangakDimens.spacing24),
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (context, index) => const SizedBox(width: SangakDimens.spacing16),
                  itemBuilder: (context, index) => const ProductCardSkeleton(),
                ),
                error: (error, stack) => Center(child: Text(l10n.errorLoadingBreads)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: SangakDimens.spacing32)),

          // Today's Specials (Vertical List)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: SangakDimens.spacing24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.traditionalFavorites, style: SangakTypography.h3(context)),
                  const SizedBox(height: SangakDimens.spacing16),
                ],
              ),
            ),
          ),

          breadsAsync.when(
            data: (breads) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: SangakDimens.spacing24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final bread = breads[index];
                    final displayName = bread.localizedName(lang);
                    final bool isAvailable = bread.available;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: SangakDimens.spacing16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isAvailable ? () => context.push('/product-details', extra: bread) : null,
                          borderRadius: BorderRadius.circular(SangakDimens.radiusL),
                          child: Opacity(
                            opacity: isAvailable ? 1.0 : 0.6,
                            child: Ink(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: SangakColors.surface,
                                borderRadius: BorderRadius.circular(SangakDimens.radiusL),
                                boxShadow: SangakDimens.shadowLow,
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(SangakDimens.radiusM),
                                    child: ColorFiltered(
                                      colorFilter: isAvailable 
                                          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                                          : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                      child: CachedNetworkImage(
                                        imageUrl: bread.imageUrl,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        memCacheHeight: 200,
                                        placeholder: (context, url) => Container(
                                          width: 80,
                                          height: 80,
                                          color: SangakColors.border,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          width: 80,
                                          height: 80,
                                          color: SangakColors.border,
                                          child: const Icon(Icons.breakfast_dining, color: SangakColors.inkLight),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: SangakDimens.spacing16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          displayName,
                                          style: SangakTypography.title(context).copyWith(
                                            fontSize: 16,
                                            color: isAvailable ? SangakColors.ink : SangakColors.inkLight,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          bread.localizedDescription(lang),
                                          style: SangakTypography.bodySmall(context).copyWith(
                                            color: SangakColors.inkLight,
                                            height: 1.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          SangakNumberFormatter.formatCurrency(bread.price, lang),
                                          style: SangakTypography.price(context).copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: isAvailable ? SangakColors.primary : SangakColors.inkLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Consumer(builder: (context, ref, child) {
                                        final isFavorite = ref.watch(isFavoriteProvider(bread.id));
                                        return SizedBox(
                                          height: 32,
                                          width: 32,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              if (!ActionGuard.check(context, ref)) return;
                                              AuthGate.run(
                                                context,
                                                ref,
                                                action: () => ref.read(favoritesProvider.notifier).toggle(bread.id),
                                                title: l10n.saveYourFavorites,
                                                message: l10n.saveFavoritesMessage,
                                              );
                                            },
                                            icon: Icon(
                                              isFavorite ? Icons.favorite : Icons.favorite_border,
                                              color: isFavorite ? SangakColors.error : SangakColors.inkLight,
                                              size: 20,
                                            ),
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 8),
                                      Consumer(builder: (context, ref, child) {
                                        final basket = ref.watch(basketProvider);
                                        final item = basket.where((item) => item.bread.id == bread.id).firstOrNull;
                                        final quantity = item?.quantity ?? 0;
                                        if (quantity > 0) {
                                          return QuantitySelector(
                                            quantity: quantity,
                                            compact: true,
                                            onIncrement: isAvailable ? () {
                                              if (!ActionGuard.check(context, ref)) return;
                                              ref.read(basketProvider.notifier).addItem(bread);
                                            } : () {},
                                            onDecrement: () {
                                              if (!ActionGuard.check(context, ref)) return;
                                              if (quantity == 1) {
                                                SangakConfirmDialog.show(
                                                  context,
                                                  title: l10n.remove,
                                                  message: l10n.removeItemFromBasket,
                                                  confirmLabel: l10n.remove,
                                                  cancelLabel: l10n.cancel,
                                                  onConfirm: () => ref.read(basketProvider.notifier).removeItem(bread.id),
                                                  isDestructive: true,
                                                );
                                              } else {
                                                ref.read(basketProvider.notifier).updateQuantity(bread.id, -1);
                                              }
                                            },
                                            onDelete: () {
                                              if (!ActionGuard.check(context, ref)) return;
                                              SangakConfirmDialog.show(
                                                context,
                                                title: l10n.remove,
                                                message: l10n.removeItemFromBasket,
                                                confirmLabel: l10n.remove,
                                                cancelLabel: l10n.cancel,
                                                onConfirm: () => ref.read(basketProvider.notifier).removeItem(bread.id),
                                                isDestructive: true,
                                              );
                                            },
                                          );
                                        }
                                        return SizedBox(
                                          height: 32,
                                          width: 32,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: isAvailable ? () {
                                              if (!ActionGuard.check(context, ref)) return;
                                              AuthGate.run(
                                                context,
                                                ref,
                                                action: () {
                                                  ref.read(basketProvider.notifier).addItem(bread);
                                                  SangakToast.show(context, l10n.addedToBasket(displayName));
                                                },
                                              );
                                            } : null,
                                            icon: Icon(
                                              Icons.add_circle, 
                                              color: isAvailable ? SangakColors.primary : SangakColors.border, 
                                              size: 28,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: breads.length,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (error, stack) => SliverToBoxAdapter(child: Center(child: Text(l10n.errorLoadingBreads))),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: SangakDimens.spacing64)),
        ],
      ),
    );
  }
}
