# Finalizing Sangak UX: Localization, Checkout, and Profile Improvements

This plan covers the remaining tasks from the previous session, focusing on robust localization, a polished checkout flow, and a functional profile editing experience.

## User Review Required

> [!IMPORTANT]
> - **Product Translations**: I will update the logic to handle locale codes more flexibly (e.g., matching `fa` with `fa-IR`). Please verify if you see the Persian/Turkish names after these changes.
> - **Address Selection UI**: I'm adding a "Saved Addresses" section to the address selection screen to improve the user experience, making it faster to repeat orders.
> - **Prep Time Logic**: The prep time will now be the sum of all items in the basket plus a 10-15 minute buffer, as requested.

## Proposed Changes

### Core & Localization

#### [MODIFY] [bread.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/models/bread.dart)
- Update `localizedName` and `localizedDescription` to handle locale codes more robustly (e.g., using only the first two characters of the language code if an exact match isn't found).

#### [MODIFY] [sangak_text_field.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/shared/widgets/sangak_text_field.dart)
- Remove the manual `Text` widget for `errorText` which causes the height jump.
- Rely on `TextFormField`'s built-in error display within `InputDecoration`.
- Adjust `contentPadding` and `errorStyle` to ensure a consistent height even when errors are shown.

---

### Features: Checkout & Basket

#### [MODIFY] [address_selection_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/basket/address_selection_screen.dart)
- Add a "Saved Addresses" horizontal or vertical list at the top of the screen.
- Improve the form layout with clearer grouping.
- Add stricter `inputFormatters` and `validator` logic for all fields.

#### [MODIFY] [order_confirmation_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/basket/order_confirmation_screen.dart)
- Translate "Delivery Address" label.
- Add "Approximate Delivery Time" row (10-15 mins).
- Ensure "Approximate Preparation Time" uses the calculated sum from the basket.
- Fix the pluralization/translation of "min" vs "minutes".

#### [MODIFY] [checkout_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/basket/checkout_screen.dart)
- Update prep time calculation to be more accurate (sum of items + 15 min buffer).

---

### Features: Profile & UI

#### [MODIFY] [profile_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/profile/profile_screen.dart)
- Verify the "Edit Profile" logic correctly updates Supabase metadata and local state.
- Ensure the sign-out and exit confirmation buttons are red using `isDestructive`.
- Remove any remaining "Language" tiles from the profile if they exist.

#### [MODIFY] [product_details_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/home/product_details_screen.dart)
- Recolor the "Traditional" tag to use `SangakColors.secondary`.
- Set tag border transparency to `0.45` and background to `0.15` (reduced transparency).

#### [MODIFY] [home_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/home/home_screen.dart) & [explore_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/explore/explore_screen.dart)
- Further trim vertical spacing and `childAspectRatio` to eliminate empty space at the bottom of product grids.

## Verification Plan

### Automated Tests
- I'll check for compilation errors after applying the changes.
- I'll verify the `localizedName` logic with a few sample language codes.

### Manual Verification
- Verify that product names change when switching language between English, Turkish, and Persian.
- Verify the trash icon appears in the basket when quantity is 1.
- Verify the prep time in the order confirmation screen reflects the items in the basket.
- Verify that profile editing successfully updates the displayed name.
