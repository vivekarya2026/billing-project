# frontend/

Flutter application — web, iOS, and Android.

## Quick start

> **Flutter SDK is required.** Install it from [flutter.dev](https://flutter.dev/docs/get-started/install) and confirm with `flutter doctor`.

```bash
cd frontend
cp .env.example .env           # fill in your Supabase URL + anon key
flutter pub get
flutter run -d chrome          # web
flutter run -d ios             # iOS simulator
flutter run -d android         # Android emulator
```

## BYPASS_AUTH

Set `BYPASS_AUTH=true` in `.env` to skip the OAuth sign-in flow during development. The router guard is disabled; you land directly on HomeScreen. **Remove this flag before any production release.**

## Structure

```
lib/
  main.dart               Entry point — loads .env, inits Supabase, runs app
  router.dart             go_router declarative routes + auth guard
  theme/
    tokens.dart           Every design constant — the single source of truth
    colours.dart          Semantic colour tokens (light + dark)
    typography.dart       Full type scale (D4: 19pt body)
    spacing.dart          8pt grid SizedBox / EdgeInsets presets
    theme.dart            ThemeData assembly (enforces D1–D4)
  shared/
    components/
      bill_card.dart      Signature component — amount + interpretation
      primary_button.dart Capsule button, 60px, all variants
      list_row.dart       Settings / list rows
    services/
      supabase_client.dart  Typed Supabase helpers
      ai_service_client.dart HTTP client for FastAPI
  features/
    home/                 Unified due view
    bill_capture/         Camera + file picker entry
    bill_detail/          The answer screen (3 registers)
    onboarding/           First-run batch add
    settings/             Exactly 4 settings items
web/
  index.html              Flutter web host + CSS import
  styles/globals.css      Global CSS token layer (mirrors tokens.dart)
```

## Design rules

| ID | Rule |
|----|------|
| D1 | 60px minimum touch target (not HIG's 44px) |
| D2 | Colour NEVER carries bill status — words only |
| D3 | No tab bar — Home + persistent Add button |
| D4 | 19pt body text (not HIG's 17pt) |

## Build

```bash
flutter build web --release         # web
flutter build ipa                   # iOS (requires Xcode)
flutter build appbundle             # Android AAB
```

## Environment variables

See `.env.example`. Never commit `.env`.

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Public anon key |
| `BYPASS_AUTH` | `true` to skip OAuth in dev — **remove before launch** |
| `AI_SERVICE_URL` | URL of the FastAPI AI service (default `http://localhost:8000`) |
