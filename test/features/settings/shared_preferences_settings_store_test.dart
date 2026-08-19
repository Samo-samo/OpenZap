import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openzap/features/settings/data/shared_preferences_settings_store.dart';
import 'package:openzap/features/settings/domain/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesSettingsStore', () {
    test('defaults to errors-only feedback', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesSettingsStore();

      final settings = await store.load();

      expect(settings.commandFeedback, CommandFeedback.errorsOnly);
    });

    test('round-trips the feedback mode', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesSettingsStore();

      await store.save(const AppSettings(commandFeedback: CommandFeedback.all));
      final loaded = await store.load();

      expect(loaded.commandFeedback, CommandFeedback.all);
    });

    test('falls back to errors-only for unknown values', () async {
      SharedPreferences.setMockInitialValues({'command_feedback': 'bogus'});
      final store = SharedPreferencesSettingsStore();

      final settings = await store.load();

      expect(settings.commandFeedback, CommandFeedback.errorsOnly);
    });

    test('defaults sleep-timer display settings', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesSettingsStore();

      final settings = await store.load();

      expect(settings.sleepTimerHumanReadable, isTrue);
      expect(settings.sleepTimerShowMinutesInParens, isFalse);
      expect(settings.sleepTimerManualInput, isFalse);
    });

    test('round-trips sleep-timer display settings', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesSettingsStore();

      await store.save(
        const AppSettings(
          sleepTimerHumanReadable: false,
          sleepTimerShowMinutesInParens: false,
          sleepTimerManualInput: true,
        ),
      );
      final loaded = await store.load();

      expect(loaded.sleepTimerHumanReadable, isFalse);
      expect(loaded.sleepTimerShowMinutesInParens, isFalse);
      expect(loaded.sleepTimerManualInput, isTrue);
    });

    test('round-trips theme and language', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesSettingsStore();

      await store.save(
        const AppSettings(themeMode: AppThemeMode.dark, languageCode: 'tr'),
      );
      final loaded = await store.load();

      expect(loaded.themeMode, AppThemeMode.dark);
      expect(loaded.languageCode, 'tr');
    });

    test('defaults all remote sections to visible', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesSettingsStore();

      final settings = await store.load();

      expect(settings.showTvStatus, isTrue);
      expect(settings.showDigits, isTrue);
      expect(settings.showSleepTimer, isTrue);
      expect(settings.showExtras, isTrue);
    });

    test('round-trips remote section visibility', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesSettingsStore();

      await store.save(
        const AppSettings(
          showTvStatus: false,
          showDigits: false,
          showSleepTimer: false,
          showExtras: true,
        ),
      );
      final loaded = await store.load();

      expect(loaded.showTvStatus, isFalse);
      expect(loaded.showDigits, isFalse);
      expect(loaded.showSleepTimer, isFalse);
      expect(loaded.showExtras, isTrue);
    });

    test('defaults to system theme and dynamic color', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesSettingsStore();

      final settings = await store.load();

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.dynamicColor, isTrue);
      expect(settings.languageCode, isNull);
    });

    test('round-trips the dynamic color setting', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesSettingsStore();

      await store.save(const AppSettings(dynamicColor: false));
      final loaded = await store.load();

      expect(loaded.dynamicColor, isFalse);
    });

    test('round-trips status tracking and defaults to off', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesSettingsStore();

      expect((await store.load()).tvStatusTracking, isFalse);

      await store.save(const AppSettings(tvStatusTracking: true));
      expect((await store.load()).tvStatusTracking, isTrue);
    });

    test('wifi warning defaults to on and round-trips', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesSettingsStore();

      expect((await store.load()).wifiWarningEnabled, isTrue);

      await store.save(const AppSettings(wifiWarningEnabled: false));
      expect((await store.load()).wifiWarningEnabled, isFalse);
    });
  });
}
