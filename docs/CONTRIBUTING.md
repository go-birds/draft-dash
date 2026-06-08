# Contributing

This repo is optimized for small, verified changes. Keep commits focused and
run the validation commands before pushing release-facing work.

## Local Setup

```bash
flutter pub get
flutter run
```

## Quality Bar

Before opening or merging a change:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

For release-impacting changes, also run:

```bash
flutter build appbundle --release
```

## Code Organization

- Put deterministic draft rules in `lib/domain/draft`.
- Put persistence code in `lib/storage`.
- Put Riverpod controllers/providers in `lib/ui/state`.
- Put reusable visual components in `lib/ui/widgets`.
- Keep screens focused on layout, navigation, and user interaction.
- Keep season-long commissioner consequences in League Ledger models before
  adding backend/account complexity.

## Testing Guidance

- Add unit tests for draft-order, proof-code, serialization, and recap behavior.
- Add widget tests for destructive actions, saved boards, and navigation states.
- Regression-test old saved JSON when changing persistence models.

## Secrets

Never commit:

- Android keystores
- `android/key.properties`
- Store passwords
- Sentry DSNs or other production credentials
