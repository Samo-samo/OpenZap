import 'app_settings.dart';

/// Persists user settings across launches.
abstract class SettingsStore {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
