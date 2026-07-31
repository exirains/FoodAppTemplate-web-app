# Implementation Plan - In-App Update Service & Refinements

This plan outlines the implementation of a production-ready in-app update service using GitHub Releases, along with branding refinements, localization completion, and animation improvements.

## Proposed Changes

### [Core Update System]

#### [NEW] [update_model.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/core/update/update_model.dart)
Define the `UpdateModel` to match the required JSON structure:
- `appName`, `version`, `buildNumber`, `forceUpdate`, `apkUrl`, `notes`.

#### [NEW] [update_repository.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/core/update/update_repository.dart)
Fetch `update.json` from GitHub. Handle timeouts, network errors, and invalid JSON gracefully. Use a configurable constant for the URL.

#### [NEW] [update_service.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/core/update/update_service.dart)
Business logic for version checking:
- Platform check: Only run on Android.
- Semantic version comparison using `pub_semver`.
- Decide between mandatory and optional update dialogs.

#### [NEW] [update_dialog.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/core/update/update_dialog.dart)
Premium Material 3 dialog following the Sangak Design System:
- Displays current vs. new version.
- Scrollable changelog (notes).
- Theme-aware buttons (`SangakButton`).
- Mandatory mode: Hidden "Later" button, undismissible.

### [Localization & Cleanup]

#### [MODIFY] ARB Files ([app_en.arb](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/l10n/app_en.arb), etc.)
Add missing keys for:
- Update dialog: `updateAvailable`, `updateNow`, `updateLater`, `whatsNew`, `currentVersion`, `newVersion`.
- Checkout/Home/Cart: Migrate all remaining hardcoded strings.
- Settings: `settings`, `language`, `appVersion`.

#### [FIX] Lint Issues
- Remove unused imports in `home_screen.dart`.
- Fix unnecessary underscores in `cart_screen.dart` and `home_screen.dart`.
- Replace `print` with a proper logger or silence it in `update_repository.dart`.

### [Settings & Language Selection]

#### [MODIFY] Home Header
Add a settings icon button to the `HomeScreen` header.

#### [NEW] [settings_bottom_sheet.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/home/widgets/settings_bottom_sheet.dart)
A refined bottom sheet to:
- Change the app language instantly.
- Display the current app version.
- Link to the Design System Gallery (for developers).

### [Animation Overhaul]

#### [REFINEMENT] Motion Principles
Rework animations to feel "premium, calm, and intentional":
- **Splash**: Gentle fade and small scale entrance.
- **Page Transitions**: Consistent, non-bouncy transitions.
- **Card Interactions**: Remove any "awful" bouncy or exaggerated effects.
- **Loading States**: Ensure elegant skeletons.

---

## User Review Required

> [!IMPORTANT]
> **Update URL**: I will use `https://raw.githubusercontent.com/exirains/sangak-app/main/update.json` as the default placeholder.
> **RTL Mirroring**: I will ensure the settings button and directional icons mirror correctly for Persian.

> [!TIP]
> The update check will be silent and have a 10-second timeout to ensure it never blocks the app startup experience.

## Verification Plan

### Automated Tests
- `UpdateService` unit tests for version comparison logic.

### Manual Verification
1. **Update Trigger**: Mock a remote version `1.1.0` and verify the dialog appears on Android.
2. **Force Update**: Mock `force_update: true` and verify the dialog cannot be closed.
3. **Localization Audit**: Switch between EN/TR/FA and verify 100% string coverage.
4. **Settings Flow**: Change language from the Home header and verify it persists.
5. **Animation Audit**: Verify all transitions feel smooth and premium on a real device.
