# Expenzless — Smart Mobile Expense Tracker

A Flutter mobile application for small business owners to track expenses,
manage budgets, set savings goals, and get AI-powered financial insights.

---

## Setup Instructions

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Firebase (already configured)
- `android/app/google-services.json` — already included with your project keys
- `lib/firebase_options.dart` — Android config already set

**⚠️ For Windows testing:** Go to Firebase Console → Project Settings →
Add a Web app → copy the web config values into `lib/firebase_options.dart`
under the `web` section.

### 3. Enable Firebase Auth
Firebase Console → Authentication → Sign-in method → Email/Password → Enable

### 4. Run the app
```bash
# Windows desktop (for testing)
flutter run -d windows

# Android (connect device or start emulator)
flutter run -d android

# List available devices
flutter devices
```

### 5. Run tests
```bash
flutter test test/expense_crud_test.dart
```

---

## Project Structure
```
lib/
├── main.dart
├── firebase_options.dart
├── theme/app_theme.dart
├── models/expense_model.dart        # ExpenseModel, BudgetModel, SavingsGoalModel
├── services/
│   ├── firebase_service.dart        # All Firestore CRUD
│   ├── camera_service.dart          # LOCAL RESOURCE 1: Camera
│   ├── notification_service.dart    # LOCAL RESOURCE 2: Push Notifications
│   ├── offline_service.dart         # LOCAL RESOURCE 3: Background Sync
│   ├── location_service.dart        # LOCAL RESOURCE 4: GPS
│   ├── gemini_service.dart          # WEB API: Gemini AI
│   └── connectivity_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── expense_provider.dart
│   ├── budget_provider.dart
│   └── savings_provider.dart
├── screens/
│   ├── auth/       splash, login, signup
│   ├── dashboard/  home with charts
│   ├── expenses/   add/edit/list
│   ├── budgets/    budget management
│   ├── savings/    savings goals
│   ├── reports/    AI insights
│   └── settings/   profile, export, logout
└── widgets/
    ├── expense_tile.dart
    ├── app_text_field.dart
    ├── loading_button.dart
    └── category_picker.dart
```

---

## Fixes Applied
- WorkManager platform guard (no crash on Windows)
- `expense_tile.dart` duplicate class definitions removed
- `slate700` colour added to AppColors
- `getTotalSpendThisMonth()` FutureOr type error fixed
- Unused variable removed from tests
- `google-services.json` package name matches `build.gradle.kts`
