# Draft Dash

Draft Dash is a Flutter app for fantasy football draft-order games. It supports four draft formats:

- Race
- Card Flip
- Lottery
- Auction

Managers are saved locally on-device, and draft history is preserved between launches.

## Release Checklist

Before shipping an alpha build:

1. Update `pubspec.yaml` with the next app version and build number.
2. Provide Android signing credentials in `android/key.properties` or via the matching `DRAFT_RACE_ANDROID_*` environment variables. Start from [`android/key.properties.example`](/Users/ncoleman/draft-race/android/key.properties.example).
3. Run the validation suite:

```bash
flutter analyze
flutter test
flutter build apk --release
flutter build ipa --no-codesign
```

## Development

```bash
flutter pub get
flutter run
```

## Notes

- The app uses local persistence via `shared_preferences`.
- Sentry is wired in, but it is a no-op unless `SENTRY_DSN` is provided at build time.
