# Walkthrough - Guest Mode & Context Preservation

I have successfully transformed the authentication experience into a **Guest-First** model. This implementation ensures that users can experience the Sangak brand and its artisan breads immediately, while providing a seamless transition to a registered account when they are ready to buy.

## Key Implementation Details

### 🥖 Low-Friction Onboarding
- **Guest Flow**: Users now travel from `Splash` -> `Language Selection` -> `Home` dashboard without any mandatory login walls.
- **Guest Indicator**: A subtle "GUEST" tag has been added to the Home header to clarify the current app state.
- **Welcoming Previews**: When a guest explores the **Cart** or **Profile** tabs, they are greeted with warm, invitation-style views that explain the benefits of joining the Sangak family.

### 🛡️ Adaptive Authentication
- **Auth Gate**: A new utility ensures that actions requiring an identity (Basket, Favorites, Orders) are intercepted.
- **Premium Auth Prompt**: Instead of a simple error, a brand-aligned **Bottom Sheet** appears with a warm welcome and clear options to Sign In or Create an Account.

### ⚙️ Context Preservation (One-Tap Continuity)
- **Problem**: Users hate repeating actions after logging in.
- **Solution**: I implemented a `PendingActionNotifier` that stores the user's intent (e.g., "Add Sangak to Basket").
- **Workflow**:
  1. Guest taps "Add to Basket".
  2. Prompt appears -> User logs in.
  3. App automatically returns the user to their product and completes the "Add" action instantly.

## Verification Results
- **Success**: Verified that guest users can browse all categories and view product details.
- **Success**: Verified that the "Add to Basket" action is successfully preserved and executed after a transition from Guest to Authenticated.
- **Success**: Verified that the UI remains calm and premium during auth transitions (no bouncing, smooth slides).

> [!TIP]
> This "Explore First" model significantly reduces bounce rates by letting the quality of the bread sell the account.

> [!IMPORTANT]
> The "Context Preservation" logic currently supports simple callbacks. As we add more complex state (like quantity selections), we can extend the `PendingAction` model to include state payloads.
