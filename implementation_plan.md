# Standardize Application Headers

The user requested that all other menu screens in the app match the new premium header layout introduced in the `Mutasi` (Transaction History) screen.

## Proposed Changes

To ensure consistency and maintainability, I will extract the premium header into a reusable widget and apply it across all relevant screens.

### 1. Create Reusable Header Component
#### [NEW] lib/shared/widgets/premium_header.dart
- Create a `PremiumHeader` widget that accepts a `title` and an optional `bottomWidget` (for things like `TabBar`).
- It will replicate the exact premium styling (dark green, rounded bottom corners, soft shadow, modern back button) used in the Mutasi screen.

### 2. Update All Menu Screens
I will replace the standard `AppBar` with `PremiumHeader` in the following files:

#### [MODIFY] lib/features/gadai/screens/gadai_screen.dart
#### [MODIFY] lib/features/sijaka/screens/sijaka_portfolio_screen.dart
#### [MODIFY] lib/features/sijaka/screens/sijaka_submission_screen.dart
#### [MODIFY] lib/features/sijaka/screens/shu_report_screen.dart
#### [MODIFY] lib/features/savings/screens/simpanan_screen.dart
#### [MODIFY] lib/features/product/screens/katalog_produk_screen.dart
#### [MODIFY] lib/features/profile/screens/profile_screen.dart
#### [MODIFY] lib/features/qris/screens/qris_payment_screen.dart
#### [MODIFY] lib/features/history/screens/transaction_history_screen.dart (refactor to use the new reusable widget)

## Verification Plan
- Verify that each screen successfully compiles.
- Check that navigation (back button) functions properly on all screens.
- Ensure any `TabBar` or bottom elements are seamlessly integrated into the `PremiumHeader`.
