# Implementation Plan - Google OAuth Redirect Flow Fix

Fix the Google OAuth redirect flow to support both Flutter Web and Android APK, ensuring correct redirection after authentication.

## User Review Required

> [!IMPORTANT]
> **Supabase Dashboard Actions**: After these code changes, you MUST update your Supabase configuration:
> 1. Go to **Authentication → URL Configuration**.
> 2. Change **Site URL** to `https://sangak.tr`.
> 3. Add **Redirect URLs**:
>    - `https://sangak.tr/**`
>    - `com.sangak.app://login-callback`
>
> **Google Cloud Console Actions**: Ensure the Android OAuth client is configured:
> 1. Go to Google Cloud Console.
> 2. Add an Android OAuth client with:
>    - Package Name: `com.sangak.app`
>    - Release SHA-1 certificate fingerprint.

---

## Proposed Changes

### 1. Update `signInWithGoogle` in `auth_provider.dart`
- Import `package:flutter/foundation.dart` for `kIsWeb`.
- Implement platform-specific `redirectUrl`.
- Pass `redirectUrl` to `signInWithOAuth`.

#### [MODIFY] [auth_provider.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/features/auth/auth_provider.dart)

### 2. Configure Android Deep Linking
- Add the required `intent-filter` to the `AndroidManifest.xml` to handle the `com.sangak.app://login-callback` deep link.

#### [MODIFY] [AndroidManifest.xml](file:///C:/Users/Mahyar/StudioProjects/Sangak/android/app/src/main/AndroidManifest.xml)

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no syntax errors.

### Manual Verification
1. **Web Flow**:
   - Deploy/Run on Web.
   - Login with Google from `https://sangak.tr`.
   - Verify it returns to the website after authentication.
2. **Android Flow**:
   - Run on Android Emulator/Device.
   - Login with Google.
   - Verify it returns back into the Sangak app after authentication (no localhost redirect).
