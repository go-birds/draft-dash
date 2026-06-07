# Domain Layer

Pure Dart — zero Flutter imports. 100% unit-testable.

The domain has a small genre-agnostic core that every app needs, plus
track-specific patterns depending on the kind of game you are building.

---

## Core (all games)

```
domain/
├── game/
│   ├── game.dart       # Game session state: immutable, copyWith()
│   └── game_codec.dart # JSON serialization
```

Rules:
1. One file = one concept. No giant files.
2. All data classes immutable. Mutations return new instances via `copyWith()`.
3. No `print()`. No Flutter imports (`package:flutter/...`).
4. Constructors: `factory` for named construction patterns, `const` wherever possible.
5. Enums: add a `code` getter (short string) for persistence. Add `fromCode(String)`.

---

## Track A — Generated / deduction grid puzzles

For games where puzzles are created programmatically (like Sudoku, Binairo, etc.).

```
domain/
├── board/
│   ├── cell.dart           # Piece/value enum (e.g. empty/a/b)
│   ├── board.dart          # N×N immutable grid + operations
│   └── puzzle.dart         # Puzzle = clues + solution + metadata
├── rules/
│   └── rules.dart          # Rule validators, violation types
├── solver/
│   └── solver.dart         # Deduction engine — used as generation gate AND hint engine
├── generator/
│   └── generator.dart      # Seeded, deterministic puzzle gen (rejects if solver can't solve)
├── game/
│   ├── game.dart
│   └── game_codec.dart
└── difficulty.dart         # Difficulty enum
```

**Build order:** rules → generator → solver (use solver to verify generator output) → game.

**Key invariant:** the generator must reject any puzzle its own solver can't uniquely solve.
Frame the solver as a *generation gate*, not just for hints.

---

## Track B — Authored level packs

For games with hand-crafted levels (platformers, puzzles with designer intent, etc.).

```
domain/
├── level/
│   ├── level.dart          # Immutable level data: layout, start state, par
│   └── levels.dart         # Level pack: ordered list of Level + metadata
├── game/
│   ├── game.dart           # Session state: current level + player state + move history
│   ├── game_engine.dart    # Pure step(Game, Input) → Game — no Flutter/Riverpod deps
│   └── game_codec.dart
```

**Build order:** engine → levels → solvability test → UI.

**Key invariant:** every shipped level must be solver-verified. See §9 (Build Order) for
the solvability test pattern.

**Pure engine rule:** `game_engine.dart` must have zero storage/provider/Flutter dependencies.
The controller calls it, sets state, and persists. This enables:
- The live game and the test solver to share identical rules by construction (so the test
  can't drift from gameplay).
- Unit testing without a device.
- The UI to animate a move (engine returns the path, not just the final state).

**Memory trap:** if `Game` stores an undo snapshot pointing at the previous `Game`, a
sequence of moves forms a linked list of past states. BFS over such states explodes memory.
Give `Game` a `stripHistory()` method and use it when enqueuing solver states.

---

See PLAYBOOK.md for detailed patterns and code examples for each track.
