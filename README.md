# Draft Dash

Draft Dash is a Flutter app for fantasy football leagues that want a better
way to decide draft order. It turns the order reveal into a short game-day
moment with four modes:

- Race
- Card Flip
- Lottery, using an NBA-style 14-ball, 4-number combination draw. By default,
  every pick is drawn until one manager remains; commissioners can choose fewer
  lottery picks and let the rest fill deterministically.
- Auction

The app stores league setup and draft history locally on-device. Draft results
can be saved, reopened later, copied as a recap, and verified with a stable
proof code plus execution metadata.

Draft Dash also includes **League Ledger**, a local commissioner log for
season-long consequences: odds boosts, odds penalties, traded/locked picks, and
draft-day notes.

## Project Structure

```text
lib/
├── domain/draft/   # Pure Dart draft models, engines, recaps, and result logic
├── services/       # Cross-cutting platform/app services
├── storage/        # Local persistence wrapper
└── ui/             # Screens, widgets, state controllers, and theme tokens

assets/
├── audio/          # Local sound effects
├── fonts/          # Bundled display/body fonts
└── icon/           # Source launcher/splash artwork

docs/               # Release and contributor runbooks
tool/               # Asset-generation helpers
test/               # Unit and widget tests
```

## Development

```bash
flutter pub get
flutter run
```

Run the web app locally with `flutter run -d chrome`. Deployment configuration
for Greenbean Studio is documented in
[`docs/WEB_DEPLOYMENT.md`](docs/WEB_DEPLOYMENT.md).

Useful checks before committing:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Preview a seeded screen for screenshot/design work:

```bash
flutter run -t lib/preview.dart --dart-define=PREVIEW=race
```

Supported preview values: `setup`, `race`, `cards`, `lottery`, `bidding`, and
`result`.

## Release Checklist

Before shipping an alpha build:

1. Update `pubspec.yaml` with the next app version and build number.
2. Provide Android signing credentials in `android/key.properties` or via the
   matching `DRAFT_DASH_ANDROID_*` environment variables. Start from
   [`android/key.properties.example`](android/key.properties.example).
3. Run the validation suite:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build appbundle --release
```

The Play Store upload artifact is written to:

```text
build/app/outputs/bundle/release/app-release.aab
```

See [`docs/RELEASE.md`](docs/RELEASE.md) for the fuller release runbook,
store notes, and GitHub privacy-policy URL.

## Proof Verification

Copied draft recaps include a proof code, execution timestamp, draft seed, draft
settings snapshot, commissioner pins, manager settings, and final board. Use
these together to confirm the saved result matches the settings the league
agreed to before the draw.

Post-draw commissioner reorders are retained as timestamped before/after audit
entries and committed into the proof code. The result screen can also export a
PNG proof receipt containing the final order and visible edit history without
including manager email addresses.

If League Ledger entries are present, recaps also include their draft-day
summary so odds penalties, bonuses, and pick locks are visible to the league.

See [`docs/PROOF_VERIFICATION.md`](docs/PROOF_VERIFICATION.md) for the full
verification workflow and current limitations.

## Notes

- The app uses local persistence via `shared_preferences`.
- Sentry is wired in, but it is a no-op unless `SENTRY_DSN` is provided at build time.
- The Dart package name remains `draft_race` for now to avoid a high-churn import
  rename during alpha prep; the shipped app name and Android package are Draft
  Dash / `com.gobirds.draftdash`.
