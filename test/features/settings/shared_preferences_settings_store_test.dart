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

      await store.save(
        const AppSettings(commandFeedback: CommandFeedback.all),
      );
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
      expect(settings.sleepTimerShowMinutesInParens, isTrue);
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
  });
}