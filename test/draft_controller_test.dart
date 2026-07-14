import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_result.dart';
import 'package:draft_race/domain/draft/league_ledger.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('commissioner reorders append immutable proof audit entries', () async {
    final (:container, :storage) = await _container();
    addTearDown(container.dispose);

    final config = container.read(draftConfigProvider.notifier);
    config.addManager('Nick');
    config.addManager('Jordan');
    config.addManager('Taylor');
    final controller = container.read(draftControllerProvider.notifier);
    controller.run();
    final original = container.read(draftControllerProvider)!;
    final firstOrder = [...original.order]..insert(0, original.order.last);
    firstOrder.removeLast();

    controller.editOrder(firstOrder, editedAt: DateTime.utc(2026, 7, 14, 1));
    final afterFirst = container.read(draftControllerProvider)!;
    expect(afterFirst.proofMetadata!.orderEdits, hasLength(1));
    expect(
      afterFirst.proofMetadata!.orderEdits.single.previousOrder,
      original.order,
    );
    expect(
      afterFirst.proofMetadata!.orderEdits.single.updatedOrder,
      firstOrder,
    );
    expect(afterFirst.proofCode, isNot(original.proofCode));

    controller.editOrder(
      original.order,
      editedAt: DateTime.utc(2026, 7, 14, 1, 1),
    );
    final restored = container.read(draftControllerProvider)!;
    expect(restored.order, original.order);
    expect(restored.proofMetadata!.orderEdits, hasLength(2));
    // Restoring the visible order does not restore the original fingerprint:
    // the proof still commits to both manual changes.
    expect(restored.proofCode, isNot(original.proofCode));

    controller.editOrder(
      original.order,
      editedAt: DateTime.utc(2026, 7, 14, 1, 2),
    );
    expect(
      container.read(draftControllerProvider)!.proofMetadata!.orderEdits,
      hasLength(2),
    );
    expect(storage.loadHistory(), isEmpty);
  });

  test('saveToHistory preserves the captured roster snapshot', () async {
    final (:container, :storage) = await _container();
    addTearDown(container.dispose);

    final config = container.read(draftConfigProvider.notifier);
    config.addManager('Nick');
    config.addManager('Jordan');
    container.read(leagueNameProvider.notifier).set(' Sunday League ');
    container.read(draftControllerProvider.notifier).run();

    final liveResult = container.read(draftControllerProvider);
    expect(liveResult?.rosterSnapshot.map((p) => p.name), ['Nick', 'Jordan']);

    config.clearLeague();
    await container.read(draftControllerProvider.notifier).saveToHistory();

    final saved = container.read(historyProvider).single;
    expect(saved.leagueName, 'Sunday League');
    expect(saved.rosterSnapshot.map((p) => p.name), ['Nick', 'Jordan']);
    expect(storage.loadHistory().single.rosterSnapshot.map((p) => p.name), [
      'Nick',
      'Jordan',
    ]);
  });

  test(
    'saveToHistory updates an existing saved board instead of duplicating it',
    () async {
      final (:container, :storage) = await _container();
      addTearDown(container.dispose);

      final config = container.read(draftConfigProvider.notifier);
      config.addManager('Nick');
      config.addManager('Jordan');
      container.read(leagueNameProvider.notifier).set('First Name');
      container.read(draftControllerProvider.notifier).run();

      await container.read(draftControllerProvider.notifier).saveToHistory();
      container.read(leagueNameProvider.notifier).set('Updated Name');
      await container.read(draftControllerProvider.notifier).saveToHistory();

      expect(container.read(historyProvider), hasLength(1));
      expect(container.read(historyProvider).single.leagueName, 'Updated Name');
      expect(storage.loadHistory(), hasLength(1));
      expect(storage.loadHistory().single.leagueName, 'Updated Name');
    },
  );

  test('history keeps only the most recent 50 distinct boards', () async {
    final (:container, :storage) = await _container();
    addTearDown(container.dispose);
    final history = container.read(historyProvider.notifier);

    for (var i = 0; i < 55; i++) {
      await history.add(
        DraftResult(
          order: ['p$i', 'q$i'],
          seed: i,
          mode: DraftMode.race,
          createdAt: DateTime.utc(2026, 6, 7),
        ),
      );
    }

    expect(container.read(historyProvider), hasLength(50));
    expect(container.read(historyProvider).first.seed, 54);
    expect(container.read(historyProvider).last.seed, 5);
    expect(storage.loadHistory(), hasLength(50));
    expect(storage.loadHistory().first.seed, 54);
    expect(storage.loadHistory().last.seed, 5);
  });

  test('stale manager odds and budget updates are ignored safely', () async {
    final (:container, :storage) = await _container();
    addTearDown(container.dispose);
    final config = container.read(draftConfigProvider.notifier);

    config.addManager('Nick');
    config.addManager('Jordan');
    final removedId = container.read(draftConfigProvider).participants.first.id;
    config.removeManager(removedId);

    expect(() {
      config.setWeight(removedId, 5);
      config.setBudget(removedId, 500);
    }, returnsNormally);

    final current = container.read(draftConfigProvider);
    expect(current.participants.map((p) => p.name), ['Jordan']);
    expect(current.participants.single.weight, 1);
    expect(current.participants.single.budget, 100);
    expect(storage.loadConfig()?.participants.map((p) => p.name), ['Jordan']);
  });

  test('setBudget clamps values to the 0..100000 range', () async {
    final (:container, :storage) = await _container();
    addTearDown(container.dispose);
    final config = container.read(draftConfigProvider.notifier);

    config.addManager('Nick');
    final id = container.read(draftConfigProvider).participants.single.id;

    config.setBudget(id, -50);
    expect(container.read(draftConfigProvider).participants.single.budget, 0);

    config.setBudget(id, 9999999);
    expect(
      container.read(draftConfigProvider).participants.single.budget,
      100000,
    );
    expect(storage.loadConfig()?.participants.single.budget, 100000);
  });

  test('setWeight clamps values to the 0.2..5.0 range', () async {
    final (:container, :storage) = await _container();
    addTearDown(container.dispose);
    final config = container.read(draftConfigProvider.notifier);

    config.addManager('Nick');
    final id = container.read(draftConfigProvider).participants.single.id;

    config.setWeight(id, 0);
    expect(container.read(draftConfigProvider).participants.single.weight, .2);

    config.setWeight(id, -3);
    expect(container.read(draftConfigProvider).participants.single.weight, .2);

    config.setWeight(id, 50);
    expect(container.read(draftConfigProvider).participants.single.weight, 5);
    expect(storage.loadConfig()?.participants.single.weight, 5);
  });

  test('addManager is a no-op once the roster hits 16 managers', () async {
    final (:container, :storage) = await _container();
    addTearDown(container.dispose);
    final config = container.read(draftConfigProvider.notifier);

    for (var i = 0; i < DraftConfigController.maxManagers + 3; i++) {
      config.addManager('Manager $i');
    }

    expect(
      container.read(draftConfigProvider).participants,
      hasLength(DraftConfigController.maxManagers),
    );
    expect(
      storage.loadConfig()?.participants,
      hasLength(DraftConfigController.maxManagers),
    );
  });

  test('manager removal also clears their ledger entries', () async {
    final (:container, :storage) = await _container();
    addTearDown(container.dispose);
    final config = container.read(draftConfigProvider.notifier);

    config.addManager('Nick');
    config.addManager('Jordan');
    final removedId = container.read(draftConfigProvider).participants.first.id;
    config.addLedgerEntry(
      LeagueLedgerEntry(
        id: 'e1',
        type: LedgerEntryType.oddsPenalty,
        managerId: removedId,
        title: 'Last place tax',
        weightDelta: -.5,
        createdAt: DateTime.utc(2026, 6, 8),
      ),
    );

    config.removeManager(removedId);

    expect(container.read(draftConfigProvider).ledgerEntries, isEmpty);
    expect(storage.loadConfig()?.ledgerEntries, isEmpty);
  });

  test(
    'prepareNewDraft resets manual odds and locks but keeps ledger',
    () async {
      final (:container, :storage) = await _container();
      addTearDown(container.dispose);
      final config = container.read(draftConfigProvider.notifier);

      config.addManager('Nick');
      config.addManager('Jordan');
      final state = container.read(draftConfigProvider);
      final nickId = state.participants.first.id;
      final jordanId = state.participants.last.id;
      config.setWeightingEnabled(true);
      config.setReverseOrder(true);
      config.setWeight(nickId, 3);
      config.setPin(0, jordanId);
      config.setLotteryPickCount(0);
      config.addLedgerEntry(
        LeagueLedgerEntry(
          id: 'e1',
          type: LedgerEntryType.oddsBoost,
          managerId: nickId,
          title: 'Consolation champ',
          weightDelta: .5,
          createdAt: DateTime.utc(2026, 6, 8),
        ),
      );

      config.prepareNewDraft();

      final prepared = container.read(draftConfigProvider);
      expect(prepared.weightingEnabled, isFalse);
      expect(prepared.reverseOrder, isFalse);
      expect(prepared.pins, isEmpty);
      expect(prepared.lotteryPickCount, isNull);
      expect(prepared.participants.map((p) => p.weight), [1, 1]);
      expect(prepared.ledgerEntries, hasLength(1));
      expect(storage.loadConfig()?.ledgerEntries, hasLength(1));
    },
  );
}

Future<({ProviderContainer container, StorageService storage})>
_container() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  final container = ProviderContainer(
    overrides: [storageProvider.overrideWithValue(storage)],
  );
  return (container: container, storage: storage);
}
