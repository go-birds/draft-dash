# Draft Domain

This directory contains the pure Dart rules and data model for Draft Dash. It
must stay free of Flutter, Riverpod, storage, and platform imports so draft
behavior remains deterministic and easy to unit test.

## Files

```text
draft/
├── auction.dart        # Auction-mode state machine and result creation
├── draft_config.dart   # League setup: mode, managers, odds, budgets, pins
├── draft_engine.dart   # Deterministic order generation for non-auction modes
├── draft_mode.dart     # Persisted mode enum
├── draft_recap.dart    # Shareable recap text
├── draft_result.dart   # Saved result, proof code, JSON, roster snapshots
├── draft_settings.dart # User-facing settings model
├── league_ledger.dart  # Season consequences: odds changes, pick locks, notes
└── participant.dart    # Manager model
```

## Design Rules

1. Keep domain code deterministic for a given seed/configuration.
2. Preserve saved results even when live league setup later changes.
3. Treat old or partial saved JSON as recoverable user data, not an error.
4. Keep persistence codes stable once released.
5. Prefer small immutable models with `copyWith` over mutating shared state.
6. Add tests for edge cases before changing draft-order behavior.
7. Keep League Ledger entries local-first and serializable with `DraftConfig`.

## Important Invariants

- `DraftResult.proofCode` is based on the draft mode, seed, and ordered manager
  IDs. It intentionally ignores display names and roster snapshots.
- `DraftResult.proofMetadata` captures the execution timestamp, seed, and full
  draft settings snapshot used to run the draft. User-facing copy calls these
  "verification details" so the app does not expose implementation jargon.
- League Ledger entries are applied before draft generation. Odds entries adjust
  manager weights, pick-lock entries merge into commissioner pins, and all
  entries are retained in proof metadata for draft-day auditability.
- Lottery mode uses `NbaLottery`: 14 balls, 4-number combinations, 1,000
  assigned combinations, and a redraw for the ignored 11-12-13-14 combination.
  By default, lottery picks are drawn until only one manager remains. A lower
  `lotteryPickCount` can be configured to fill more of the board by remaining
  lottery order after the lottery portion.
- `DraftResult.rosterSnapshot` captures manager details at result time so saved
  boards remain readable after setup changes.
- `DraftEngine.generate` sanitizes commissioner pins before ordering, because
  release builds cannot rely on debug-only assertions.
- `HistoryController` owns saved-history dedupe and cap behavior in the UI
  state layer because it coordinates domain results with local persistence.

See `docs/PROOF_VERIFICATION.md` for the user-facing explanation of how proof
codes and metadata are used to audit a saved draft.

## Test Coverage

Domain behavior is covered primarily by:

- `test/draft_engine_test.dart`
- `test/auction_test.dart`
- `test/draft_result_test.dart`
- `test/draft_recap_test.dart`
