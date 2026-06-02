# Monitor — VAT Dashboard Status Monitor

Flutter web/mobile app for tracking VAT taxation, financial statements, and shop management with real-time file approval system. Targets Thai accounting workflows for multi-shop businesses.

## Commands

```bash
# Install dependencies
flutter pub get

# Regenerate JSON serialization (after modifying models with @JsonSerializable)
flutter packages pub run build_runner build
flutter packages pub run build_runner watch   # watch mode

# Run
flutter run -d chrome
flutter run --dart-define=BASE_URL=https://api.dev.dedepos.com

# Test
flutter test
flutter test test/unit/

# Build (PowerShell scripts)
.\build_prod.ps1 -Platform web -Env prod
.\build_prod.ps1 -Platform web -Env dev
.\build_prod.ps1 -Platform apk -Env prod
```

## Architecture

BLoC pattern with layered architecture:

```
Pages/Components  →  BLoC (Events/States)  →  Services/Repositories  →  Models
```

- **`lib/blocs/`** — State management. Each feature has `*_bloc.dart`, `*_event.dart`, `*_state.dart`
- **`lib/services/`** — API calls and business logic. `api_service.dart` is the main HTTP client
- **`lib/models/`** — JSON-serializable data models. `*.g.dart` files are auto-generated — do not edit manually
- **`lib/pages/`** — Screen widgets
- **`lib/components/`** — Reusable UI components
- **`lib/widgets/`** — Feature-specific widgets
- **`lib/core/constants/app_constants.dart`** — Business logic thresholds (VAT income limits, pagination sizes)

## State Management (BLoC)

All state changes go through Events → BLoC → States. Pattern per feature:

```dart
// Emit loading, call service, emit loaded or error
on<LoadFooEvent>((event, emit) async {
  emit(FooLoading());
  try {
    final data = await _service.fetch();
    emit(FooLoaded(data));
  } catch (e) {
    emit(FooError(e.toString()));
  }
});
```

DashboardBloc caches data for 2 minutes. Auth tokens stored in `FlutterSecureStorage` with 5-minute expiry buffer.

## Models

All models use `json_serializable`. After adding/changing fields, run:

```bash
flutter packages pub run build_runner build
```

Never edit `.g.dart` files directly.

## API & Auth

- **Prod**: `https://api.dedepos.com`
- **Dev**: `https://api.dev.dedepos.com`
- Base URL injected via `--dart-define=BASE_URL=...`

Auth flow: email/password → JWT stored in `FlutterSecureStorage`, OR Google Sign-In → Firebase Auth. `auth_repository.dart` handles token refresh.

## Responsive Breakpoints

```dart
mobile: < 600px
tablet: < 800px
desktop: < 1200px
largeDesktop: >= 1600px
```

Use `ResponsiveHelper` for breakpoint-aware layouts. Sidebar collapses on tablet.

## Business Logic Constants

From `lib/core/constants/app_constants.dart`:

| Threshold | Value (THB) |
|-----------|-------------|
| Safe income max | 1,000,000 |
| Warning income min | 1,000,000 |
| Warning income max | 1,800,000 |
| Exceeded income min | 1,800,000 |

## Deployment

Firebase Hosting:
- Dev: `account-seaandhill-dev.web.app`
- Prod: `account-seaandhill.web.app`

`build_prod.ps1` builds and deploys automatically for the web platform.

## Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | Entry point, Firebase init, BLoC providers |
| `lib/layouts/main_layout.dart` | Responsive sidebar navigation |
| `lib/services/api_service.dart` | HTTP client, multi-shop fetch |
| `lib/services/auth_repository.dart` | Token management |
| `lib/dashboard_content.dart` | Main dashboard layout |
| `lib/blocs/bloc_exports.dart` | BLoC barrel export |
