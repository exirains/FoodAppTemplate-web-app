# Implementation Plan - Sangak Brand Identity & Design System (v1.3)

This plan defines the flagship visual identity and production-ready design system (v1.0.0) for **Sangak**. It balances traditional Persian craftsmanship with modern simplicity, ensuring every component is built for scale, performance, and appetite appeal.

## 1. Design System Specification (v1.0.0)

Every component in the system is tracked with:
- **Version**: 1.0.0
- **Status**: Draft / Stable / Deprecated
- **Definition of Done**:
    - ✓ Pixel-perfect to the brand identity
    - ✓ Responsive & Theme-aware
    - ✓ Accessible (min 48x48 touch targets, semantic labels)
    - ✓ Tested in all states (Default, Hover, Pressed, Focus, Disabled, Loading, Error)
    - ✓ Uses Design Tokens only (no hardcoded colors/spacing)
    - ✓ Fully documented and localizable

## 2. Sangak Design Language: "Artisanal Precision"

The interface philosophy:
- **Warm, never cold**: Soft creams and golden crust tones.
- **Premium, never luxurious for the sake of luxury**: Focused on quality, not ornament.
- **Handmade, never rustic**: Clean execution with organic rhythm.
- **Calm, never busy**: Every screen is a moment of peace.

## 3. Brand Identity & Visual Strategy

### Photography: The Visual North Star
Product photography is our primary asset.
- **Guidelines**: Warm natural lighting, shallow depth of field, texture-focused (crust/crumb), consistent framing. UI is built *around* the photography.

### Signature Component: The Product Card
- **Goal**: Instantly recognizable as "Sangak."
- **Immutable Rules**: Fixed image ratios, padding, and badge placement.
- **Interactions**: Smooth morphing for "Add-to-Cart" and elegant favorite fills.

### Freshness & Status System
- `Fresh Today`: Olive Sage + Wheat Icon.
- `Just Out of Oven`: Amber Accent + Steam Icon.
- `Limited Quantity`: Soft Red + Alert Icon.
- Also: `Bestseller`, `Seasonal`, `Preorder`, `Sold Out`.

## 4. Foundation Tokens

### [NEW] [sangak_colors.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/core/design_system/sangak_colors.dart)
- `primary` (Golden Crust): #C68A2B
- `secondary` (Oven Stone): #7D4F39
- `background` (Natural Paper): #FDFCF8
- `surface` (Flour White): #FFFFFF
- `textPrimary` (Ink): #2A241E

### [NEW] [sangak_typography.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/core/design_system/sangak_typography.dart)
- **High-Impact**: *Fraunces* (Headlines only).
- **Functional**: *Plus Jakarta Sans* (Everything else).

### [NEW] [sangak_tokens.dart](file:///C:/Users/Mahyar/StudioProjects/Sangak/lib/core/design_system/sangak_tokens.dart)
- **Spacing**: 8pt grid system.
- **Radii**: 8 (S), 12 (M), 16 (L), 24 (XL).
- **Animations**: Use appropriate Flutter animation approaches (built-in or package-based) prioritizing performance and consistency.

## 5. Execution Roadmap

### Phase 0: Design System Foundation (Current)
1. Brand Identity Documentation & Tokens
2. Atomic Components (Buttons, Inputs, Badges)
3. Complex Components (Product Cards, Banners, Nav)
4. Developer Gallery (Hidden route `/gallery`)

### Phase 1: Onboarding & Identity
Splash, Language Selection, Login/Register (Email & Google).

### Phase 2: Core Experience
Home, Product Details, Search, Categories.

### Phase 3: Transactional
Cart, Checkout, Address Management.

### Phase 4: Post-Purchase & Account
Orders, Tracking, Profile.

### Phase 5: Retention
Notifications, Favorites, Coupons, Loyalty.

## 6. Architecture for Scale
Designed for: Multi-branch, delivery zones, pickup/delivery, seasonal products, and future expansion (Istanbul/Izmir).

## Verification Plan
1. **Gallery Audit**: Verify all component states and tokens.
2. **Contrast & Accessibility**: Audit via screen reader and contrast checkers.
3. **Responsive Check**: Test on small phone, large phone, and tablet layouts.
