import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_result.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
