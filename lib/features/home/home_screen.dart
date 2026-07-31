import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/hero_banner.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/category_chip.dart';
import '../../shared/widgets/sangak_skeletons.dart';
import '../../shared/utils/auth_gate.dart';
import '../auth/auth_provider.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final breadsAsync = ref.watch(filteredBreadsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final user = ref.watch(authProvider).value;
    final isGuest = user == null;

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
                            Text(isGuest ? 'Welcome to Sangak,' : 'Good Morning,', style: SangakTypography.bodySmall),
                            Row(
                              children: [
                                Text(isGuest ? 'Guest' : (user.email?.split('@')[0] ?? 'User'), style: SangakTypography.h3),
                                if (isGuest) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: SangakColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'GUEST',
                                      style: SangakTypography.caption.copyWith(
                                        color: SangakColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SangakColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: SangakDimens.shadowLow,
                          ),
                          child: const Icon(Icons.notifications_outlined, color: SangakColors.ink),
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
                  const HeroBanner(
                    title: 'Freshly Baked Sangak',
                    subtitle: 'Straight from the stone oven to your door.',
                    imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=800',
                  ),
                  const SizedBox(height: SangakDimens.spacing32),

                  // Categories
                  Text('Categories', style: SangakTypography.h3),
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
                              label: 'All',
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
                    error: (_, __) => const Text('Error loading categories'),
                  ),
                  const SizedBox(height: SangakDimens.spacing32),

                  // Popular Today
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Popular Today', style: SangakTypography.h3),
                      TextButton(
                        onPressed: () {},
                        child: Text('See All', style: SangakTypography.bodySmall.copyWith(color: SangakColors.primary)),
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
                      title: bread.title,
                      description: bread.description,
                      price: bread.price,
                      imageUrl: bread.imageUrl,
                      freshness: bread.freshness,
                      isFavorite: bread.isFavorite,
                      onFavoriteToggle: () {
                        AuthGate.run(
                          context,
                          ref,
                          action: () {
                            // TODO: Implement favorite toggle
                          },
                          title: 'Save your favorites',
                          message: 'Create an account to save your favorite artisan breads and access them anytime.',
                        );
                      },
                      onAddToCart: () {
                        AuthGate.run(
                          context,
                          ref,
                          action: () {
                            // TODO: Implement add to cart logic (Riverpod state)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${bread.title} added to basket!')),
                            );
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
                error: (_, __) => const Center(child: Text('Error loading breads')),
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
                  Text('Traditional Favorites', style: SangakTypography.h3),
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
                              child: Image.network(
                                bread.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: SangakDimens.spacing16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(bread.title, style: SangakTypography.title),
                                  Text(bread.description, style: SangakTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Text('₺${bread.price.toStringAsFixed(0)}', style: SangakTypography.price.copyWith(fontSize: 16)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                AuthGate.run(
                                  context,
                                  ref,
                                  action: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${bread.title} added to basket!')),
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.add_circle, color: SangakColors.primary, size: 32),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: breads.length,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SliverToBoxAdapter(child: Center(child: Text('Error loading breads'))),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: SangakDimens.spacing64)),
        ],
      ),
    );
  }
}
