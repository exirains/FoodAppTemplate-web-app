import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_dimens.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/babka_empty_states.dart';
import '../../shared/utils/babka_toast.dart';
import '../../core/localization/locale_provider.dart';
import 'favorites_provider.dart';
import '../home/home_provider.dart';
import '../home/tab_provider.dart';
import '../basket/basket_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favoritesAsync = ref.watch(favoritesProvider);
    final allBreadsAsync = ref.watch(breadsProvider);
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: BabkaColors.background,
      appBar: AppBar(
        title: Text(l10n.favorites),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: favoritesAsync.when(
        data: (favoriteIds) {
          if (favoriteIds.isEmpty) {
            return BabkaEmptyState(
              title: l10n.saveYourFavorites,
              message: l10n.saveYourFavoritesDescription,
              icon: Icons.favorite_border_rounded,
              actionLabel: l10n.explore,
              onAction: () {
                ref.read(tabProvider.notifier).state = 0;
                context.go('/home');
              },
            );
          }

          return allBreadsAsync.when(
            data: (allBreads) {
              final favoritedBreads = allBreads.where((b) => favoriteIds.contains(b.id)).toList();

              return GridView.builder(
                padding: const EdgeInsets.all(BabkaDimens.spacing24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.61,
                ),
                itemCount: favoritedBreads.length,
                itemBuilder: (context, index) {
                  final bread = favoritedBreads[index];
                  final displayName = bread.localizedName(lang);
                  return ProductCard(
                    bread: bread,
                    name: displayName,
                    description: bread.localizedDescription(lang),
                    price: bread.price,
                    imageUrl: bread.imageUrl,
                    freshness: bread.freshness,
                    isFavorite: true,
                    imageAspectRatio: 1.0, // Consistent with Explore grid
                    onFavoriteToggle: () {
                      ref.read(favoritesProvider.notifier).toggle(bread.id);
                    },
                    onAddToBasket: () {
                      ref.read(basketProvider.notifier).addItem(bread);
                      BabkaToast.show(context, l10n.addedToBasket(displayName));
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text(l10n.networkError)),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l10n.networkError)),
      ),
    );
  }
}

