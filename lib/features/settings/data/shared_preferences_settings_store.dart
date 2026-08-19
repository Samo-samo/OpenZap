import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/settings_store.dart';

class SharedPreferencesSettingsStore implements SettingsStore {
  static const _commandFeedbackKey = 'command_feedback';
  static const _themeModeKey = 'theme_mode';
  static const _languageCodeKey = 'language_code';
  static const _sleepTimerHumanReadableKey = 'sleep_timer_human_readable';
  static const _sleepTimerMinutesInParensKey = 'sleep_timer_minutes_in_parens';
  static const _sleepTimerManualInputKey = 'sleep_timer_manual_input';

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = CommandFeedback.values.asNameMap()[prefs.getString(
      _commandFeedbackKey,
    )];
    final theme = AppThemeMode.values.asNameMap()[prefs.getString(
      _themeModeKey,
    )];
    return AppSettings(
      commandFeedback: mode ?? CommandFeedback.errorsOnly,
      themeMode: theme ?? AppThemeMode.system,
      languageCode: prefs.getString(_languageCodeKey),
      sleepTimerHumanReadable:
          prefs.getBool(_sleepTimerHumanReadableKey) ?? true,
      sleepTimerShowMinutesInParens:
          prefs.getBool(_sleepTimerMinutesInParensKey) ?? true,
      sleepTimerManualInput: prefs.getBool(_sleepTimerManualInputKey) ?? false,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_commandFeedbackKey, settings.commandFeedback.name);
    await prefs.setString(_themeModeKey, settings.themeMode.name);
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
  }
}