import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/app_settings.dart';

/// Settings notifier backed by the persisted [SettingsStore].
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => ref.watch(settingsStoreProvider).load();

  Future<void> setCommandFeedback(CommandFeedback value) async {
    final settings = state.value!.copyWith(commandFeedback: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setSleepTimerHumanReadable(bool value) async {
    final settings = state.value!.copyWith(sleepTimerHumanReadable: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setSleepTimerShowMinutesInParens(bool value) async {
    final settings =
        state.value!.copyWith(sleepTimerShowMinutesInParens: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setSleepTimerManualInput(bool value) async {
    final settings = state.value!.copyWith(sleepTimerManualInput: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);