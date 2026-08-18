import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/settings_store.dart';

class SharedPreferencesSettingsStore implements SettingsStore {
  static const _commandFeedbackKey = 'command_feedback';

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = CommandFeedback.values.asNameMap()[prefs.getString(
      _commandFeedbackKey,
    )];
    return AppSettings(commandFeedback: mode ?? CommandFeedback.errorsOnly);
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_commandFeedbackKey, settings.commandFeedback.name);
  }
}