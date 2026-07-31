# Implementation Plan - Guest Mode & Adaptive Authentication (Refined)

This plan describes the implementation of **Guest Mode** for Sangak, allowing users to experience the artisan bakery before requiring an account.

## Goal
Establish a high-conversion onboarding flow where users can browse, view details, and see prices as guests. Authentication is only requested when it adds value (Basket, Favorites, Orders).

## Proposed Changes

### [Core Logic]

#### [NEW] [auth_gate.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/shared/utils/auth_gate.dart)
A utility to handle authenticated actions:
- Checks if the user is logged in.
- If guest: Stores the "pending action" (e.g., "Add Sangak to Cart") and triggers the `AuthPromptBottomSheet`.
- **Context Preservation**: After successful login/registration, the stored pending action is automatically executed.

### [UI & Experience]

#### [NEW] [auth_prompt_bottom_sheet.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/shared/widgets/auth_prompt_bottom_sheet.dart)
A premium brand introduction:
- **Design**: "🥖 Create your Sangak account" with a warm welcome.
- **Messaging**: Focus on benefits (Save basket, track orders).
- **Actions**: [Create Account] (Primary), [Sign In] (Secondary).

#### [MODIFY] [splash_screen.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/splash/splash_screen.dart)
- Update routing: `/splash` -> `/language` (if first time) -> `/home` (always).

#### [MODIFY] Home Header
- Add a **Guest Indicator** (e.g., "Browsing as Guest") in the profile/header area to provide context for future prompts.

#### [MODIFY] Cart Tab (Guest State)
- Instead of a simple block, show a **Welcoming Preview**:
  - "Your basket is waiting. Create an account to save your items and complete your order."
  - Consistent styling with the design system.

#### [MODIFY] Actions
- **Add to Basket**: Intercepted by `AuthGate`.
- **Favorite**: Intercepted by `AuthGate` (persisted synced data).
- **Orders/Profile**: Redirects to the welcoming auth invitation.

---

## User Review Required

> [!IMPORTANT]
> **Automatic Action Completion**: I will implement a `pendingActionProvider` in Riverpod to store closures. After auth state changes to `user != null`, the app will check this provider and execute the call (e.g., add to cart) before clearing it.

> [!TIP]
> **Guest Indicator**: I'll use a subtle "Guest" tag next to the greeting in the Home header to keep the UI clean but informative.

## Verification Plan
1.  **Guest Journey**: Verify flow from Splash -> Language -> Home without a login screen.
2.  **Context Preservation**:
    - As guest: Tap "Add Traditional Sangak".
    - Sign in.
    - Verify user is back on the product page AND the bread is already in their basket.
3.  **Cart Preview**: Verify the Cart tab shows a welcoming invitation when guest.
4.  **UI Audit**: Ensure the `AuthPromptBottomSheet` follows "Artisanal Precision" (no bouncy wiggles, just smooth slides).
