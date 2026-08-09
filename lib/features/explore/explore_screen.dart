import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/utils/auth_gate.dart';
import '../../shared/utils/action_guard.dart';
import '../home/home_provider.dart';
import '../basket/basket_provider.dart';
import '../../core/localization/locale_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const ExploreScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCategoryIdProvider.notifier).state = widget.initialCategoryId;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final breadsAsync = ref.watch(filteredBreadsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;

    return Scaffold(
      backgroundColor: SangakColors.background,
      appBar: AppBar(
        title: Text(l10n.explore),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Container(
              decoration: BoxDecoration(
                color: SangakColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: SangakDimens.shadowLow,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: l10n.searchBreads,
                  prefixIcon: const Icon(Icons.search_rounded, color: SangakColors.inkLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Categories horizontal
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: categoriesAsync.when(
              data: (categories) => SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final category = isAll ? null : categories[index - 1];
                    final isSelected = isAll ? selectedCategoryId == null : selectedCategoryId == category?.id;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => ref.read(selectedCategoryIdProvider.notifier).state = category?.id,
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? SangakColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? SangakColors.primary : SangakColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isAll ? l10n.all : category!.localizedName(lang),
                              style: SangakTypography.title(context).copyWith(
                                fontSize: 13,
                                color: isSelected ? Colors.white : SangakColors.inkLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ),
          
          Expanded(
            child: breadsAsync.when(
              data: (breads) {
                final filtered = breads.where((b) {
                  final name = b.localizedName(lang).toLowerCase();
                  final desc = b.localizedDescription(lang).toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  return name.contains(query) || desc.contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noProductsFound,
                      style: SangakTypography.bodyLarge(context).copyWith(color: SangakColors.inkLight),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 64),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.61, // Detached from home page sizing
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final bread = filtered[index];
                    final displayName = bread.localizedName(lang);
                    return ProductCard(
                      bread: bread,
                      name: bread.name,
                      description: bread.description,
                      price: bread.price,
                      imageUrl: bread.imageUrl,
                      freshness: bread.freshness,
                      isFavorite: bread.isFavorite,
                      imageAspectRatio: 1.0, // Square images for explore grid
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
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text(l10n.errorLoadingBreads)),
            ),
          ),
        ],
      ),
    );
  }
}
