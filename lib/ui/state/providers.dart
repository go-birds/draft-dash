import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progenitor_core/progenitor_core.dart';

import '../../domain/draft/auction.dart';
import '../../domain/draft/draft_config.dart';
import '../../domain/draft/draft_engine.dart';
import '../../domain/draft/draft_mode.dart';
import '../../domain/draft/draft_result.dart';
import '../../domain/draft/league_ledger.dart';
import '../../domain/draft/draft_settings.dart';
import '../../domain/draft/participant.dart';
import '../../storage/storage_service.dart';
import '../theme/app_tokens.dart';
import '../theme/themes.dart';

/// Default jersey colors/numbers assigned to new managers, in roster order.
const kJerseyPalette = <int>[
  0xFF3A86FF,
  0xFFE63946,
  0xFFFFB703,
  0xFF06D6A0,
  0xFF9B5DE5,
  0xFFFB5607,
  0xFF34C759,
  0xFFFF5DA2,
  0xFF4CC9F0,
  0xFFB5179E,
  0xFF8AC926,
  0xFFF15BB5,
];
const kJerseyNumbers = <String>[
  '07',
  '23',
  '12',
  '05',
  '88',
  '44',
  '31',
  '19',
  '80',
  '22',
  '11',
  '99',
];

String _newId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';

int _freshSeed() =>
    DateTime.now().millisecondsSinceEpoch ^ (Random().nextInt(1 << 30));

// ─── storage ──────────────────────────────────────────────────────────────
final storageProvider = Provider<StorageService>(
  (_) =>
      throw UnimplementedError('storageProvider must be overridden in main()'),
);

// ─── theme ──────────────────────────────────────────────────────────────────
class ThemeController extends Notifier<AppTheme<DraftTokens>> {
  @override
  AppTheme<DraftTokens> build() {
    final id = ref.read(storageProvider).themeId;
    return id == null ? AppThemes.defaultTheme : AppThemes.byId(id);
  }

  void select(AppTheme<DraftTokens> t) {
    state = t;
    unawaited(ref.read(storageProvider).setThemeId(t.id));
  }
}

final themeProvider = NotifierProvider<ThemeController, AppTheme<DraftTokens>>(
  ThemeController.new,
);

// ─── settings ─────────────────────────────────────────────────────────────
class SettingsController extends Notifier<DraftSettings> {
  @override
  DraftSettings build() => ref.read(storageProvider).loadSettings();

  void _save() => unawaited(ref.read(storageProvider).saveSettings(state));

  void setSound(bool v) {
    state = state.copyWith(soundEnabled: v);
    _save();
  }

  void setHaptics(bool v) {
    state = state.copyWith(hapticsEnabled: v);
    _save();
  }

  void setDefaultMode(DraftMode m) {
    state = state.copyWith(defaultMode: m);
    _save();
  }
}

final settingsProvider = NotifierProvider<SettingsController, DraftSettings>(
  SettingsController.new,
);

// ─── league name ────────────────────────────────────────────────────────────
class LeagueNameController extends Notifier<String> {
  @override
  String build() => ref.read(storageProvider).leagueName;

  void set(String v) {
    state = v;
    unawaited(ref.read(storageProvider).setLeagueName(v));
  }
}

final leagueNameProvider = NotifierProvider<LeagueNameController, String>(
  LeagueNameController.new,
);

// ─── draft config (the league roster + setup) ────────────────────────────────
class DraftConfigController extends Notifier<DraftConfig> {
  static const maxManagers = 16;

  @override
  DraftConfig build() {
    final saved = ref.read(storageProvider).loadConfig();
    if (saved != null && saved.participants.isNotEmpty) return saved;
    return DraftConfig(
      participants: const [],
      mode: ref.read(settingsProvider).defaultMode,
    );
  }

  void _set(DraftConfig c) {
    state = c;
    unawaited(ref.read(storageProvider).saveConfig(c));
  }

  void restore(DraftConfig c) => _set(c);

  List<Participant> get _ps => state.participants;

  void addManager([String name = '']) {
    if (_ps.length >= maxManagers) return;
    final idx = _ps.length;
    final p = Participant(
      id: _newId(),
      name: name.trim().isEmpty ? 'Manager ${idx + 1}' : name.trim(),
      number: kJerseyNumbers[idx % kJerseyNumbers.length],
      colorValue: kJerseyPalette[idx % kJerseyPalette.length],
    );
    _set(state.copyWith(participants: [..._ps, p]));
  }

  void removeManager(String id) {
    final next = [
      for (final p in _ps)
        if (p.id != id) p,
    ];
    final pins = {
      for (final e in state.pins.entries)
        if (e.value != id) e.key: e.value,
    };
    _set(
      state.copyWith(
        participants: next,
        pins: pins,
        ledgerEntries: [
          for (final entry in state.ledgerEntries)
            if (entry.managerId != id) entry,
        ],
      ),
    );
  }

  void updateManager(Participant updated) {
    _set(
      state.copyWith(
        participants: [
          for (final p in _ps)
            if (p.id == updated.id) updated else p,
        ],
      ),
    );
  }

  void setWeight(String id, double w) {
    final p = _tryById(id);
    if (p == null) return;
    // Weights must stay > 0: the engine samples with pow(u, 1/w).
    updateManager(p.copyWith(weight: w.clamp(0.1, 10.0)));
  }

  void setBudget(String id, int b) {
    final p = _tryById(id);
    if (p == null) return;
    updateManager(p.copyWith(budget: b.clamp(0, 100000)));
  }

  void setTaunt(String id, String? taunt) {
    final p = _tryById(id);
    if (p == null) return;
    final trimmed = taunt?.trim();
    updateManager(
      p.copyWith(taunt: (trimmed == null || trimmed.isEmpty) ? null : trimmed),
    );
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [..._ps];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _set(state.copyWith(participants: list));
  }

  void setMode(DraftMode m) => _set(state.copyWith(mode: m));
  void setWeightingEnabled(bool v) => _set(state.copyWith(weightingEnabled: v));
  void setReverseOrder(bool v) => _set(state.copyWith(reverseOrder: v));
  void setLotteryPickCount(int v) => _set(state.copyWith(lotteryPickCount: v));

  void addLedgerEntry(LeagueLedgerEntry entry) {
    _set(state.copyWith(ledgerEntries: [entry, ...state.ledgerEntries]));
  }

  void removeLedgerEntry(String id) {
    _set(
      state.copyWith(
        ledgerEntries: [
          for (final entry in state.ledgerEntries)
            if (entry.id != id) entry,
        ],
      ),
    );
  }

  void clearLedger() => _set(state.copyWith(ledgerEntries: const []));

  void resetOdds() => _set(
    state.copyWith(
      participants: [for (final p in _ps) p.copyWith(weight: 1.0)],
    ),
  );

  // commissioner pins ───────────────────────────────────────────
  void setPin(int slot, String id) {
    // A manager can hold only one pin; clear any prior slot for this id.
    final pins = {
      for (final e in state.pins.entries)
        if (e.value != id && e.key != slot) e.key: e.value,
    };
    pins[slot] = id;
    _set(state.copyWith(pins: pins));
  }

  void clearPin(int slot) {
    final pins = {...state.pins}..remove(slot);
    _set(state.copyWith(pins: pins));
  }

  void clearAllPins() => _set(state.copyWith(pins: const {}));

  void clearLeague() => _set(const DraftConfig(participants: []));

  /// Starts a clean draft from the saved league roster while preserving ledger
  /// entries that should still apply on draft day.
  void prepareNewDraft() => _set(
    state.copyWith(
      participants: [for (final p in _ps) p.copyWith(weight: 1.0)],
      weightingEnabled: false,
      reverseOrder: false,
      pins: const {},
      clearLotteryPickCount: true,
    ),
  );

  Participant? _tryById(String id) {
    for (final p in _ps) {
      if (p.id == id) return p;
    }
    return null;
  }
}

final draftConfigProvider =
    NotifierProvider<DraftConfigController, DraftConfig>(
      DraftConfigController.new,
    );

/// Live odds (chance at pick #1) for the current config, for the setup UI.
final oddsProvider = Provider<Map<String, double>>(
  (ref) => DraftEngine.relativeOdds(ref.watch(draftConfigProvider)),
);

// ─── draft result (the produced order; shared by all modes) ───────────────────
class DraftController extends Notifier<DraftResult?> {
  @override
  DraftResult? build() => null;

  /// Auto-reveal modes: compute the final order now; the screen dramatizes it.
  void run() {
    final cfg = ref.read(draftConfigProvider);
    if (cfg.participants.isEmpty) return;
    state = DraftEngine.generate(cfg, seed: _freshSeed());
  }

  /// Bidding mode hands its finished order in here.
  void setResult(DraftResult r) => state = r;

  /// Post-draw commissioner override.
  void editOrder(List<String> order) {
    final s = state;
    if (s != null) state = s.copyWith(order: order);
  }

  void clear() => state = null;

  Future<void> saveToHistory() async {
    final s = state;
    if (s == null) return;
    final name = ref.read(leagueNameProvider).trim();
    final cfg = ref.read(draftConfigProvider);
    final rosterSnapshot = s.rosterSnapshot.isNotEmpty
        ? s.rosterSnapshot
        : cfg.participants;
    await ref
        .read(historyProvider.notifier)
        .add(
          s.copyWith(
            leagueName: name.isEmpty ? null : name,
            rosterSnapshot: rosterSnapshot,
          ),
        );
  }
}

final draftControllerProvider = NotifierProvider<DraftController, DraftResult?>(
  DraftController.new,
);

// ─── auction (live bidding state) ─────────────────────────────────────────────
class AuctionController extends Notifier<AuctionState?> {
  @override
  AuctionState? build() => null;

  void start() {
    final cfg = ref.read(draftConfigProvider);
    if (cfg.participants.isEmpty) return;
    state = AuctionState.initial(cfg.participants);
  }

  /// Resolve one sealed-bid round. Returns true once the auction is complete.
  bool resolveRound(Map<String, int> bids, {String? commissionerWinner}) {
    final s = state;
    if (s == null || s.isComplete) return s?.isComplete ?? false;
    final next = s.resolveRound(
      bids,
      commissionerWinner: commissionerWinner,
      rng: Random(),
    );
    state = next;
    if (next.isComplete) {
      ref
          .read(draftControllerProvider.notifier)
          .setResult(
            next.toResult(
              seed: _freshSeed(),
              config: ref.read(draftConfigProvider),
            ),
          );
      return true;
    }
    return false;
  }

  void cancel() => state = null;
}

final auctionProvider = NotifierProvider<AuctionController, AuctionState?>(
  AuctionController.new,
);

// ─── history ──────────────────────────────────────────────────────────────────
class HistoryController extends Notifier<List<DraftResult>> {
  static const _maxSavedDrafts = 50;

  @override
  List<DraftResult> build() => ref.read(storageProvider).loadHistory();

  Future<void> add(DraftResult r) async {
    final existing = [
      for (final saved in state)
        if (!_sameDraft(saved, r)) saved,
    ];
    final next = [r, ...existing].take(_maxSavedDrafts).toList();
    state = next;
    await ref.read(storageProvider).saveHistory(next);
  }

  Future<void> clearAll() async {
    state = [];
    await ref.read(storageProvider).saveHistory(const []);
  }

  bool _sameDraft(DraftResult a, DraftResult b) {
    if (a.seed != b.seed ||
        a.mode != b.mode ||
        a.order.length != b.order.length) {
      return false;
    }
    for (var i = 0; i < a.order.length; i++) {
      if (a.order[i] != b.order[i]) return false;
    }
    return true;
  }
}

final historyProvider = NotifierProvider<HistoryController, List<DraftResult>>(
  HistoryController.new,
);
