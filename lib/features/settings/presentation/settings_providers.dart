import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../remote_control/domain/remote_layout.dart';
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
    final settings = applyRemoteLayoutPreset(
      value,
      state.value!.copyWith(activeCustomLayoutId: null),
    );
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  /// Activates a saved custom layout, or deactivates back to the last preset
  /// when [id] is `null`.
  Future<void> activateCustomLayout(String? id) async {
    final settings = state.value!.copyWith(
      activeCustomLayoutId: () {
        if (id == null) {
          return null;
        }
        final exists = state.value!.savedLayouts.any(
          (layout) => layout.id == id,
        );
        return exists ? id : null;
      }(),
    );
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  /// Creates an empty saved layout slot and returns its id.
  Future<String> createCustomLayout(String name) async {
    final id = 'layout-${DateTime.now().microsecondsSinceEpoch}';
    final settings = state.value!.copyWith(
      savedLayouts: [
        ...state.value!.savedLayouts,
        SavedRemoteLayout(
          id: id,
          name: name,
          gridJson: jsonEncode(FreeRemoteLayout.defaultTemplate().toJson()),
        ),
      ],
      activeCustomLayoutId: null,
    );
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
    return id;
  }

  Future<void> renameCustomLayout(String id, String name) async {
    final settings = state.value!.copyWith(
      savedLayouts: [
        for (final layout in state.value!.savedLayouts)
          if (layout.id == id) layout.copyWith(name: name) else layout,
      ],
    );
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  /// Persists an edited layout. [activate] also switches to it immediately.
  Future<void> saveCustomLayout(
    String id,
    String json, {
    bool activate = true,
  }) async {
    final current = state.value!;
    final settings = current.copyWith(
      savedLayouts: [
        for (final layout in current.savedLayouts)
          if (layout.id == id) layout.copyWith(gridJson: json) else layout,
      ],
      activeCustomLayoutId: activate ? id : current.activeCustomLayoutId,
    );
    state = AsyncData(settings);
    await ref.read(settingsStoreProvider).save(settings);
  }

  Future<void> deleteCustomLayout(String id) async {
    final current = state.value!;
    final wasActive = current.activeCustomLayoutId == id;
    final settings = current.copyWith(
      savedLayouts: [
        for (final layout in current.savedLayouts)
          if (layout.id != id) layout,
      ],
      activeCustomLayoutId: wasActive ? null : current.activeCustomLayoutId,
    );
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
