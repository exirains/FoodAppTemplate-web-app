# Task List - Guest Mode & Context Preservation

- `[x]` 1. Infrastructure Update
    - `[x]` Create `AuthPromptBottomSheet`
    - `[x]` Implement `PendingActionNotifier` for context preservation
    - `[x]` Create `AuthGate` utility
- `[x]` 2. Flow & Routing
    - `[x]` Update `SplashScreen` routing (Default to `/home`)
    - `[x]` Update `AppRouter` to handle guest states
- `[x]` 3. Tab & Header Refinement
    - `[x]` Add Guest Indicator to `HomeScreen` header
    - `[x]` Create `CartGuestView` for the Cart tab
    - `[x]` Create `ProfileGuestView` for the Profile tab
- `[x]` 4. Action Interception
    - `[x]` Wrap "Add to Cart" with `AuthGate`
    - `[x]` Wrap "Favorite" with `AuthGate`
- `[x]` 5. Verification
    - `[x]` Test context preservation (Auto-add after login)
    - `[x]` UI audit of prompts and guest views
