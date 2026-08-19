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

  Future<void> setThemeMode(AppThemeMode value) async {
    final settings = state.value!.copyWith(themeMode: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setDynamicColor(bool value) async {
    final settings = state.value!.copyWith(dynamicColor: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setRemoteLayout(RemoteLayout value) async {
    final settings = applyRemoteLayoutPreset(value, state.value!);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setShowTvStatus(bool value) async {
    final settings = state.value!.copyWith(showTvStatus: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setShowDigits(bool value) async {
    final settings = state.value!.copyWith(showDigits: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setShowSleepTimer(bool value) async {
    final settings = state.value!.copyWith(showSleepTimer: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setShowExtras(bool value) async {
    final settings = state.value!.copyWith(showExtras: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setLanguageCode(String? value) async {
    final settings = state.value!.copyWith(languageCode: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setSleepTimerHumanReadable(bool value) async {
    final settings = state.value!.copyWith(sleepTimerHumanReadable: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setSleepTimerShowMinutesInParens(bool value) async {
    final settings = state.value!.copyWith(
      sleepTimerShowMinutesInParens: value,
    );
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setSleepTimerManualInput(bool value) async {
    final settings = state.value!.copyWith(sleepTimerManualInput: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setTvStatusTracking(bool value) async {
    final settings = state.value!.copyWith(tvStatusTracking: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> setWifiWarningEnabled(bool value) async {
    final settings = state.value!.copyWith(wifiWarningEnabled: value);
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
