/// How the UI reports command delivery to the user.
enum CommandFeedback {
  /// Show a message only when a command fails.
  errorsOnly,

  /// Show a message for both successes and failures.
  all,

  /// Do not show any command feedback.
  none,
}

/// The color theme used by the app.
enum AppThemeMode {
  /// Follow the operating system theme.
  system,

  /// Always use the light theme.
  light,

  /// Always use the dark theme.
  dark,
}

/// Preset arrangements of the remote screen.
enum RemoteLayout {
  /// All sections: status, power/mute/info, volume/channels, D-pad,
  /// back/exit, digits, sleep timer.
  classic,

  /// Hides the status chip and the digit row.
  compact,

  /// Only the essential controls: power/mute/info, volume/channels, D-pad,
  /// back/exit.
  minimal,
}

/// User-configurable application settings.
class AppSettings {
  const AppSettings({
    this.commandFeedback = CommandFeedback.errorsOnly,
    this.themeMode = AppThemeMode.system,
    this.remoteLayout = RemoteLayout.classic,
    this.languageCode,
    this.sleepTimerHumanReadable = true,
    this.sleepTimerShowMinutesInParens = false,
    this.sleepTimerManualInput = false,
    this.tvStatusTracking = false,
    this.wifiWarningEnabled = true,
  });

  /// Command feedback mode.
  final CommandFeedback commandFeedback;

  /// Color theme mode.
  final AppThemeMode themeMode;

  /// Preset arrangement of the remote screen.
  final RemoteLayout remoteLayout;

  /// App language (`tr`, `en`, ...), or `null` to follow the system locale.
  final String? languageCode;

  /// Whether sleep-timer durations are shown as hours and minutes
  /// (e.g. "2 hours 5 minutes") instead of flat minutes.
  final bool sleepTimerHumanReadable;

  /// Whether the flat total is shown in parentheses next to the
  /// hours/minutes form (e.g. "... (125 minutes)").
  final bool sleepTimerShowMinutesInParens;

  /// Whether the custom sleep-timer dialog offers a manual minute entry.
  final bool sleepTimerManualInput;

  /// Whether the app connects to the TV's status channel to show its
  /// power state on the remote screen.
  final bool tvStatusTracking;

  /// Whether the start screen shows the same-Wi-Fi warning banner.
  final bool wifiWarningEnabled;

  AppSettings copyWith({
    CommandFeedback? commandFeedback,
    AppThemeMode? themeMode,
    RemoteLayout? remoteLayout,
    String? languageCode,
    bool? sleepTimerHumanReadable,
    bool? sleepTimerShowMinutesInParens,
    bool? sleepTimerManualInput,
    bool? tvStatusTracking,
    bool? wifiWarningEnabled,
  }) {
    return AppSettings(
      commandFeedback: commandFeedback ?? this.commandFeedback,
      themeMode: themeMode ?? this.themeMode,
      remoteLayout: remoteLayout ?? this.remoteLayout,
      languageCode: languageCode ?? this.languageCode,
      sleepTimerHumanReadable:
          sleepTimerHumanReadable ?? this.sleepTimerHumanReadable,
      sleepTimerShowMinutesInParens:
          sleepTimerShowMinutesInParens ?? this.sleepTimerShowMinutesInParens,
      sleepTimerManualInput:
          sleepTimerManualInput ?? this.sleepTimerManualInput,
      tvStatusTracking: tvStatusTracking ?? this.tvStatusTracking,
      wifiWarningEnabled: wifiWarningEnabled ?? this.wifiWarningEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.commandFeedback == commandFeedback &&
      other.themeMode == themeMode &&
      other.remoteLayout == remoteLayout &&
      other.languageCode == languageCode &&
      other.sleepTimerHumanReadable == sleepTimerHumanReadable &&
      other.sleepTimerShowMinutesInParens == sleepTimerShowMinutesInParens &&
      other.sleepTimerManualInput == sleepTimerManualInput &&
      other.tvStatusTracking == tvStatusTracking &&
      other.wifiWarningEnabled == wifiWarningEnabled;

  @override
  int get hashCode => Object.hash(
    commandFeedback,
    themeMode,
    remoteLayout,
    languageCode,
    sleepTimerHumanReadable,
    sleepTimerShowMinutesInParens,
    sleepTimerManualInput,
    tvStatusTracking,
    wifiWarningEnabled,
  );
}
