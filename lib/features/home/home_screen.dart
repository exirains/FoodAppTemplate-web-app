import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../auth/auth_provider.dart';
import '../cart/cart_provider.dart';
import 'home_provider.dart';
import 'tab_provider.dart';
import 'widgets/settings_bottom_sheet.dart';
import '../../services/greeting_service.dart';
import '../../shared/utils/auth_gate.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/widgets/category_chip.dart';
import '../../shared/widgets/hero_banner.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/sangak_skeletons.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final breadsAsync = ref.watch(filteredBreadsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final user = ref.watch(authProvider).value;
    final isGuest = user == null;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: SangakColors.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Search
          SliverAppBar(
            floating: true,
            expandedHeight: 120,
            backgroundColor: SangakColors.background,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(GreetingService.getGreeting(context), style: SangakTypography.bodySmall),
                            const SizedBox(height: 4),
                            if (!isGuest)
                              Text(
                                user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
                                style: SangakTypography.h3,
                              ),
                            if (isGuest)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: SangakColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.guest.toUpperCase(),
                                  style: SangakTypography.caption.copyWith(
                                    color: SangakColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => SettingsBottomSheet.show(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: SangakColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: SangakDimens.shadowLow,
                            ),
                            child: const Icon(Icons.settings_outlined, color: SangakColors.ink),
                          ),
                        ),
                      ],
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
                    imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=800',
                  ),
                  const SizedBox(height: SangakDimens.spacing32),

                  // Categories
                  Text(l10n.categories, style: SangakTypography.h3),
                  const SizedBox(height: SangakDimens.spacing16),
                  categoriesAsync.when(
                    data: (categories) => SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(width: SangakDimens.spacing12),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return CategoryChip(
                              label: l10n.all,
                              isSelected: selectedCategoryId == null,
                              onTap: () => ref.read(selectedCategoryIdProvider.notifier).state = null,
                            );
                          }
                          final category = categories[index - 1];
                          return CategoryChip(
                            label: category.name,
                            isSelected: selectedCategoryId == category.id,
                            onTap: () => ref.read(selectedCategoryIdProvider.notifier).state = category.id,
                          );
                        },
                      ),
                    ),
                    loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
                    error: (error, stack) => Text('${l10n.errorLoadingCategories}: $error'),
                  ),
                  const SizedBox(height: SangakDimens.spacing32),

                  // Popular Today
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.popularToday, style: SangakTypography.h3),
                      TextButton(
                        onPressed: () => ref.read(tabProvider.notifier).state = 1,
                        child: Text(l10n.seeAll, style: SangakTypography.bodySmall.copyWith(color: SangakColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: SangakDimens.spacing16),
                ],
              ),
            ),
          ),

          // Bread Horizontal List
          SliverToBoxAdapter(
            child: SizedBox(
              height: 380,
              child: breadsAsync.when(
                data: (breads) => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: SangakDimens.spacing24),
                  scrollDirection: Axis.horizontal,
                  itemCount: breads.length,
                  separatorBuilder: (context, index) => const SizedBox(width: SangakDimens.spacing16),
                  itemBuilder: (context, index) {
                    final bread = breads[index];
                    return ProductCard(
                      bread: bread,
                      name: bread.name,
                      description: bread.description,
                      price: bread.price,
                      imageUrl: bread.imageUrl,
                      freshness: bread.freshness,
                      isFavorite: bread.isFavorite,
                      onFavoriteToggle: () {
                        AuthGate.run(
                          context,
                          ref,
                          action: () => ref.read(favoritesProvider.notifier).toggle(bread.id),
                          title: l10n.saveYourFavorites,
                          message: l10n.saveFavoritesMessage,
                        );
                      },
                      onAddToCart: () {
                        AuthGate.run(
                          context,
                          ref,
                          action: () {
                            ref.read(cartProvider.notifier).addItem(bread);
                            SangakToast.show(context, l10n.addedToBasket(bread.name));
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
                error: (error, stack) => Center(child: Text('${l10n.errorLoadingBreads}: $error')),
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
                  Text(l10n.traditionalFavorites, style: SangakTypography.h3),
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: SangakDimens.spacing16),
                      child: GestureDetector(
                        onTap: () => context.push('/product-details', extra: bread),
                        child: Container(
                          padding: const EdgeInsets.all(SangakDimens.spacing12),
                          decoration: BoxDecoration(
                            color: SangakColors.surface,
                            borderRadius: BorderRadius.circular(SangakDimens.radiusL),
                            boxShadow: SangakDimens.shadowLow,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(SangakDimens.radiusM),
                                child: CachedNetworkImage(
                                  imageUrl: bread.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
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
                              const SizedBox(width: SangakDimens.spacing16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      bread.name,
                                      style: SangakTypography.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      bread.description,
                                      style: SangakTypography.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text('₺${bread.price.toStringAsFixed(0)}', style: SangakTypography.price.copyWith(fontSize: 16)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      AuthGate.run(
                                        context,
                                        ref,
                                        action: () => ref.read(favoritesProvider.notifier).toggle(bread.id),
                                        title: l10n.saveYourFavorites,
                                        message: l10n.saveFavoritesMessage,
                                      );
                                    },
                                    icon: Icon(
                                      bread.isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: bread.isFavorite ? SangakColors.error : SangakColors.inkLight,
                                      size: 20,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      AuthGate.run(
                                        context,
                                        ref,
                                        action: () {
                                          ref.read(cartProvider.notifier).addItem(bread);
                                          SangakToast.show(context, l10n.addedToBasket(bread.name));
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.add_circle, color: SangakColors.primary, size: 32),
                                  ),
                                ],
                              ),
                            ],
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
            error: (error, stack) => SliverToBoxAdapter(child: Center(child: Text('${l10n.errorLoadingBreads}: $error'))),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: SangakDimens.spacing64)),
        ],
      ),
    );
  }
}
