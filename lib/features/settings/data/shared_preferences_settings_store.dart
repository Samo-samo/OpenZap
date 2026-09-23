import 'package:shared_preferences/shared_preferences.dart';

import '../../remote_control/domain/remote_layout.dart';
import '../domain/app_settings.dart';
import '../domain/settings_store.dart';

class SharedPreferencesSettingsStore implements SettingsStore {
  static const _commandFeedbackKey = 'command_feedback';
  static const _themeModeKey = 'theme_mode';
  static const _dynamicColorKey = 'dynamic_color';
  static const _showTvStatusKey = 'show_tv_status';
  static const _showDigitsKey = 'show_digits';
  static const _showSleepTimerKey = 'show_sleep_timer';
  static const _showExtrasKey = 'show_extras';
  static const _savedLayoutsKey = 'custom_layouts_v1';
  static const _activeCustomLayoutIdKey = 'active_custom_layout_id';
  static const _editorZoomEnabledKey = 'editor_zoom_enabled';
  // Pre-multi-layout keys, migrated on load.
  static const _legacyUseCustomLayoutKey = 'use_custom_layout';
  static const _legacyCustomLayoutJsonKey = 'custom_layout_json';
  static const _languageCodeKey = 'language_code';
  static const _sleepTimerHumanReadableKey = 'sleep_timer_human_readable';
  static const _sleepTimerMinutesInParensKey = 'sleep_timer_minutes_in_parens';
  static const _sleepTimerManualInputKey = 'sleep_timer_manual_input';
  static const _tvStatusTrackingKey = 'tv_status_tracking';
  static const _wifiWarningEnabledKey = 'wifi_warning_enabled';

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = CommandFeedback.values
        .asNameMap()[prefs.getString(_commandFeedbackKey)];
    final theme = AppThemeMode.values
        .asNameMap()[prefs.getString(_themeModeKey)];
    final (savedLayouts, activeId) = _loadLayouts(prefs);
    return AppSettings(
      commandFeedback: mode ?? CommandFeedback.errorsOnly,
      themeMode: theme ?? AppThemeMode.system,
      dynamicColor: prefs.getBool(_dynamicColorKey) ?? true,
      showTvStatus: prefs.getBool(_showTvStatusKey) ?? true,
      showDigits: prefs.getBool(_showDigitsKey) ?? true,
      showSleepTimer: prefs.getBool(_showSleepTimerKey) ?? true,
      showExtras: prefs.getBool(_showExtrasKey) ?? true,
      savedLayouts: savedLayouts,
      activeCustomLayoutId: activeId,
      editorZoomEnabled: prefs.getBool(_editorZoomEnabledKey) ?? true,
      languageCode: prefs.getString(_languageCodeKey),
      sleepTimerHumanReadable:
          prefs.getBool(_sleepTimerHumanReadableKey) ?? true,
      sleepTimerShowMinutesInParens:
          prefs.getBool(_sleepTimerMinutesInParensKey) ?? false,
      sleepTimerManualInput: prefs.getBool(_sleepTimerManualInputKey) ?? false,
      tvStatusTracking: prefs.getBool(_tvStatusTrackingKey) ?? false,
      wifiWarningEnabled: prefs.getBool(_wifiWarningEnabledKey) ?? true,
    );
  }

  /// Loads the saved-layout list and active id; also migrates the legacy
  /// single-custom-layout keys once.
  (List<SavedRemoteLayout>, String?) _loadLayouts(SharedPreferences prefs) {
    final rawList = prefs.getString(_savedLayoutsKey);
    if (rawList != null) {
      final activeId = prefs.getString(_activeCustomLayoutIdKey);
      final layouts = parseSavedLayouts(rawList);
      return (layouts, activeId == null || activeId.isEmpty ? null : activeId);
    }
    final legacyJson = prefs.getString(_legacyCustomLayoutJsonKey);
    if (legacyJson == null || legacyJson.isEmpty) {
      return (const [], null);
    }
    final migrated = SavedRemoteLayout(
      id: 'migrated',
      name: 'Custom',
      gridJson: legacyJson,
    );
    final wasActive = prefs.getBool(_legacyUseCustomLayoutKey) ?? false;
    // Persist in the new format right away so migration runs only once.
    prefs.setString(_savedLayoutsKey, serializeSavedLayouts([migrated]));
    prefs.setString(_activeCustomLayoutIdKey, wasActive ? migrated.id : '');
    prefs.remove(_legacyUseCustomLayoutKey);
    prefs.remove(_legacyCustomLayoutJsonKey);
    return ([migrated], wasActive ? migrated.id : null);
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_commandFeedbackKey, settings.commandFeedback.name);
    await prefs.setString(_themeModeKey, settings.themeMode.name);
    await prefs.setBool(_dynamicColorKey, settings.dynamicColor);
    await prefs.setBool(_showTvStatusKey, settings.showTvStatus);
    await prefs.setBool(_showDigitsKey, settings.showDigits);
    await prefs.setBool(_showSleepTimerKey, settings.showSleepTimer);
    await prefs.setBool(_showExtrasKey, settings.showExtras);
    await prefs.setString(
      _savedLayoutsKey,
      serializeSavedLayouts(settings.savedLayouts),
    );
    final activeId = settings.activeCustomLayoutId;
    if (activeId == null) {
      await prefs.remove(_activeCustomLayoutIdKey);
    } else {
      await prefs.setString(_activeCustomLayoutIdKey, activeId);
    }
    await prefs.setBool(_editorZoomEnabledKey, settings.editorZoomEnabled);
    final languageCode = settings.languageCode;
    if (languageCode == null) {
      await prefs.remove(_languageCodeKey);
    } else {
      await prefs.setString(_languageCodeKey, languageCode);
    }
    await prefs.setBool(
      _sleepTimerHumanReadableKey,
      settings.sleepTimerHumanReadable,
    );
    await prefs.setBool(
      _sleepTimerMinutesInParensKey,
      settings.sleepTimerShowMinutesInParens,
    );
    await prefs.setBool(
      _sleepTimerManualInputKey,
      settings.sleepTimerManualInput,
    );
    await prefs.setBool(_tvStatusTrackingKey, settings.tvStatusTracking);
    await prefs.setBool(_wifiWarningEnabledKey, settings.wifiWarningEnabled);
  }
}
