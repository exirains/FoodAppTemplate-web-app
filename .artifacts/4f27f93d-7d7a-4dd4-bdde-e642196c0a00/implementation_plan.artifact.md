# Implementation Plan - Phase 5 Refined: Final Polish & Full Integration

This phase addresses critical bugs, completes the transactional sync, and applies a massive round of UI/UX "silky" polish to meet flagship standards.

## 🥖 Phase 5 Refinement Goals
1. **Fix Transactional Failures**: Ensure Cart items are persisted to Supabase `cart_items`.
2. **Auth & Profile Perfection**: Fix Login button, add Back button, and enable Avatar display.
3. **Elite UI/UX**:
    - Beautiful, non-jittery transitions.
    - Time-based greetings (Good Morning/Afternoon/Evening).
    - Optimistic Favorites (no page refresh).
    - Heroic Splash screen with a larger logo.
4. **Layout Fixes**: Eliminate the 32px overflow on the Explore page and fix the button "jump".
5. **Tooling Upgrade**: Add Prep Time, Calories, and Organic status to the CLI and UI.

---

## Proposed Changes

### [1. Transactional & Backend Sync]
#### [MODIFY] [cart_provider.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/cart/cart_provider.dart)
- Implement `syncToSupabase()`: When a user logs in, immediately push all local guest items to the `cart_items` table.
- Ensure `addItem` and `updateQuantity` perform real-time Supabase updates if the user is authenticated.

#### [FIX] [LoginScreen](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/auth/login_screen.dart)
- Connect the **Login** button correctly (it was missing the final state check).
- Add a **Back Button** in the AppBar to prevent users from getting stuck.

### [2. Product Excellence]
#### [MODIFY] [bread.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/models/bread.dart)
- Add fields: `prepTime` (int), `calories` (int), `isOrganic` (bool).
- Match Supabase column names if they exist, or handle as metadata.

#### [MODIFY] [product_card.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/shared/widgets/product_card.dart)
- **Fix Height Jump**: Ensure the `ElevatedButton` and `QuantitySelector` have identical height constraints (54px) to prevent the "jump" when morphing.

#### [MODIFY] [ProductDetailsScreen](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/home/product_details_screen.dart)
- **Favorites**: Connect the heart button to `FavoriteService`.
- **Quantity**: Make the bottom quantity selector functional.
- **Organic Tag**: Only show the "Organic" chip if `isOrganic` is true.

### [3. UI/UX Master Polish]
#### [MODIFY] [home_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/home/home_screen.dart)
- **Dynamic Greeting**: Implement a `GreetingService` that returns localized "Good Morning/Afternoon/Evening" based on device time.

#### [MODIFY] [explore_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/explore/explore_screen.dart)
- **Fix Overflow**: Adjust `bottom` padding and `SliverGridDelegate` to eliminate the 32px overflow.

#### [MODIFY] [profile_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/profile/profile_screen.dart)
- **Avatar Fix**: Ensure `avatar_url` is fetched from the `profiles` table and displayed using `CachedNetworkImage`.
- **Cleanup**: Remove the redundant language selection.

### [4. Developer Tools (CLI)]
#### [MODIFY] [main.py](file:///C:/Users/Mahyar/StudioProjects/Sangak/tools/product_manager/main.py)
- Add prompts for `prep_time`, `calories`, and `is_organic` during `add` and `update`.

---

## User Review Required

> [!IMPORTANT]
> **Supabase Schema**: I will assume the `products` table now supports `prep_time`, `calories`, and `is_organic`. If these columns don't exist yet, I will save them into a `metadata` JSON column if available, or please add them in Supabase.
> **Phone Format**: I will apply `FilteringTextInputFormatter` to ensure the phone field strictly follows E.164 (+[country][number]).

> [!TIP]
> To achieve the "silky" feel, I will use `PageTransitionsTheme` in `ThemeData` to ensure all routes glide smoothly across both Android and Web.

## Verification Plan
1. **Cart Persistence**: Verify `cart_items` table in Supabase fills up after adding items as a logged-in user.
2. **Auth Flow**: Perform a full "Back -> Login" cycle and verify the button responsiveness.
3. **Time Audit**: Change device time to 8 PM and verify the greeting changes to "Good Evening".
4. **Visual Audit**: Verify the larger logo on Splash and the lack of "jump" on product cards.
