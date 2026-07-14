# Proof Verification

Draft Dash includes a compact proof code plus proof metadata so a league can
audit a completed draft board.

## What Gets Shared

When a result recap is copied, it includes:

- Proof code, such as `DD-ABC-1234`
- Execution timestamp
- Draft seed
- Draft mode
- Whether weighted odds were enabled
- Whether reverse order was enabled
- How many picks were drawn by lottery before deterministic fill
- Commissioner pins, if any
- League Ledger entries, including odds boosts, odds penalties, pick locks, and
  commissioner notes
- Manager settings at execution time, including names, jersey numbers, weights,
  and auction budgets
- Final draft board
- Every post-draw commissioner order edit, including its UTC timestamp and the
  complete before/after order
- A shareable PNG proof card with the proof code, original execution details,
  final order, and prominent edit history (manager emails are never included)

## What The Proof Code Verifies

The short proof code is generated from:

- Draft mode
- Draft seed
- Final ordered manager IDs
- The complete commissioner edit audit trail, when edits exist: timestamp plus
  every manager ID in the before and after orders

If any of those change, the proof code changes.

The proof code intentionally does not include display-only details such as
manager names, colors, or saved roster snapshots. That keeps the code stable if
a manager later edits a display name or color.

## What The Metadata Verifies

The proof metadata explains the conditions under which the draft was executed:

- `executedAt` proves when the draft was run.
- `seed` is the random seed used by the draft engine.
- `settings.mode` proves which draft mode was selected.
- `settings.weightingEnabled` proves whether custom odds were active.
- `settings.reverseOrder` proves whether the result was flipped.
- `settings.lotteryPickCount` proves how many picks were drawn by the lottery
  before deterministic fill. If it is absent, the default is every pick until
  only one manager remains.
- `settings.pins` proves any commissioner-assigned pick slots.
- `settings.ledgerEntries` proves which season-long consequences were applied
  or summarized on draft day.
- `settings.participants` proves the manager weights, budgets, numbers, and
  names that were present when the draft was executed.
- `orderEdits` records every post-draw commissioner override as an immutable
  before/after snapshot with a UTC timestamp.

This gives league members enough context to answer, "Were these the settings we
agreed to before the draw?"

## How To Verify A Draft Result

1. Compare the copied proof code to the proof code shown on the saved draft
   board in Draft Dash.
2. Compare the execution timestamp to when the league ran the draft.
3. Compare the metadata settings to the league's agreed setup before the draw.
4. Confirm commissioner pins match any manual pick assignments the league
   agreed to use.
5. Confirm League Ledger entries match the season-long penalties, rewards,
   trades, and notes the commissioner recorded.
6. Confirm the final draft board in the recap matches the saved board in the
   app.
7. If the proof card says `COMMISSIONER OVERRIDE`, inspect every before/after
   order and confirm those changes were approved by the league.

If all of those match, the recap represents the saved Draft Dash result and the
settings snapshot used when it was executed.

## Current Limitations

- Draft Dash does not yet provide a separate public web verifier where someone
  can paste a proof packet and recompute the code.
- The proof code is an integrity check for the app-generated result, not a
  cryptographic signature.
- A local commissioner can still create a different proof packet; the code and
  image make changes conspicuous and internally consistent, but are not a
  server-signed attestation. League members should compare the shared receipt
  at the time of the draw.

## Developer Notes

- `DraftResult.proofCode` is the compact code shown in the UI.
- `DraftResult.proofMetadata` is serialized into saved history and copied into
  recaps when available.
- `DraftProofMetadata.settings` stores a snapshot of `DraftConfig` so later
  league setup edits do not rewrite the audit record for old boards.
- Legacy JSON without `orderEdits` remains valid and retains its original proof
  code. Edited boards use the versioned edit-trail fingerprint extension.
