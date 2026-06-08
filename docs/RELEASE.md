# Release Runbook

Use this checklist when preparing a Draft Dash alpha, beta, or production build.

## Store Identity

- App name: `Draft Dash`
- Android package: `com.gobirds.draftdash`
- Current Dart package: `draft_race`
- Privacy policy URL:
  `https://github.com/go-birds/draft-dash/blob/main/PRIVACY_POLICY.md`

## Versioning

Update `pubspec.yaml` before each store upload:

```yaml
version: 1.0.0+1
```

Use `X.Y.Z+N`, where `X.Y.Z` is the user-visible version and `N` is the
monotonically increasing Android `versionCode`.

## Android Signing

Release builds require either `android/key.properties` or environment variables.

Preferred environment variable names:

```bash
DRAFT_DASH_ANDROID_STORE_FILE
DRAFT_DASH_ANDROID_STORE_PASSWORD
DRAFT_DASH_ANDROID_KEY_ALIAS
DRAFT_DASH_ANDROID_KEY_PASSWORD
```

The older `DRAFT_RACE_ANDROID_*` names are still accepted as a compatibility
fallback.

Start from:

```text
android/key.properties.example
```

Do not commit real keystores, passwords, or `android/key.properties`.

## Validation

Run the full local validation suite before uploading:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build appbundle --release
```

The Android App Bundle is created at:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Google Play Notes

- Initial release track: internal testing or closed testing alpha.
- Ads declaration: answer based on the current uploaded build. If ads are not
  integrated yet, do not declare that this build contains ads. Update the Play
  Console declaration before uploading a later build with ads.
- Data safety: Draft Dash currently stores league setup, settings, and draft
  history locally on-device. Sentry crash reporting is optional and only active
  when `SENTRY_DSN` is supplied at build time.

## Proof Verification Notes

Draft recaps include a compact proof code plus metadata. League members can use
the proof code to match the saved board, then use the metadata to audit the
execution timestamp, seed, draft mode, weighting setting, reverse-order setting,
commissioner pins, and manager settings used for the draw.

See [`PROOF_VERIFICATION.md`](PROOF_VERIFICATION.md) for the full verification
workflow and current limitations.

## Suggested Release Name

```text
Draft Dash Alpha 1
```

## Suggested Release Notes

```text
Initial alpha for Draft Dash.

- Create fantasy draft orders with Race, Card Flip, Lottery, and Auction modes.
- Save draft boards locally and reopen them later.
- Copy shareable draft recaps with verification proof codes, execution
- timestamps, lottery-depth settings, League Ledger consequences, and
  draft-settings metadata.
- Manage league settings, themes, sound, and draft history on-device.
```
