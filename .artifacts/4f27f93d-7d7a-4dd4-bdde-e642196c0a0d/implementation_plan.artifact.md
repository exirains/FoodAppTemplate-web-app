# Implementation Plan - Full Product & Category Localization

Implement multi-language support (EN, TR, FA) for all products and categories using Supabase translation tables and a robust fallback system.

## User Review Required

> [!IMPORTANT]
> **Database Schema**: This plan assumes `product_translations` and `category_translations` tables exist with `language_code`, `name`, and `description` (for products) columns.
> **Caching Strategy**: We will store separate Hive cache keys per language (e.g., `all_breads_en`) to ensure instant UI updates when switching languages without mixing data.

---

## Proposed Changes

### [1. Model Enhancements]

#### [MODIFY] [bread.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/models/bread.dart)
- Add `Map<String, dynamic> translations` field to store all fetched translations.
- Implement `localizedName(String locale)` and `localizedDescription(String locale)` methods.
- Logic: `locale` -> `tr` -> `en` -> `originalName`.

#### [MODIFY] [category.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/models/category.dart)
- Add `Map<String, String> translations` field.
- Implement `localizedName(String locale)` method.

### [2. Repository & Backend Sync]

#### [MODIFY] [bread_repository.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/services/bread_repository.dart)
- Update all fetch queries to include `product_translations(*)` and `category_translations(*)`.
- Update `fromJson` calls to pass the translation list to the models.

### [3. State & Cache Management]

#### [MODIFY] [cache_service.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/services/cache_service.dart)
- Update `saveBreads`, `getBreads`, `saveCategories`, etc., to take a `languageCode`.
- Use language-specific keys (e.g., `categories_tr`) in Hive.

#### [MODIFY] [home_provider.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/home/home_provider.dart)
- Watch `localeProvider`.
- Pass the current `languageCode` to the `CacheService` and `BreadRepository` if needed.
- Ensure providers invalidate or refresh when the locale changes.

### [4. UI Integration]

#### [MODIFY] [product_card.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/shared/widgets/product_card.dart)
- Watch `localeProvider`.
- Use `bread.localizedName(locale.languageCode)` for display.

#### [MODIFY] [home_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/home/home_screen.dart)
#### [MODIFY] [product_details_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/home/product_details_screen.dart)
#### [MODIFY] [explore_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/explore/explore_screen.dart)
- Ensure all product/category displays use the localized name/description.

### [5. Admin CLI Support]

#### [MODIFY] [main.py](file:///C:/Users/Mahyar/StudioProjects/Sangak/tools/product_manager/main.py)
- Update `add_product` to prompt for EN, TR, and FA names/descriptions.
- Create entries in `product_translations` after creating the product.

---

## Verification Plan

### Localization Test
1. Set app language to **Persian**.
2. Verify all bread names and descriptions appear in Persian.
3. Switch to **Turkish**.
4. Verify immediate UI update to Turkish.

### Fallback Test
1. Remove the Persian translation for one product in the database.
2. Set app language to **Persian**.
3. Verify it falls back to **Turkish** (or **English** if TR is missing).

### Cache Test
1. Switch between languages in offline mode.
2. Verify that each language shows its own correct cached data without mixing.
