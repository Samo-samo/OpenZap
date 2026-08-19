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

/// Preset arrangements of the remote screen sections.
///
/// Selecting a preset turns the individual sections on/off through
/// [AppSettings.copyWith]; the user can deviate from a preset to build a
/// custom layout.
enum RemoteLayout {
  /// All sections: status, power/mute/info, volume/channels, D-pad,
  /// back/exit, digits, quick controls, sleep timer.
  classic,

  /// Hides the status chip and the digit row, keeps quick controls.
  compact,

  /// Only the essential controls: power/mute/info, volume/channels, D-pad,
  /// back/exit.
  minimal,
}

/// Applies the section visibility of a [RemoteLayout] preset to [settings].
AppSettings applyRemoteLayoutPreset(RemoteLayout layout, AppSettings settings) {
  return switch (layout) {
    RemoteLayout.classic => settings.copyWith(
      showTvStatus: true,
      showDigits: true,
      showSleepTimer: true,
      showExtras: true,
    ),
    RemoteLayout.compact => settings.copyWith(
      showTvStatus: false,
      showDigits: false,
      showSleepTimer: true,
      showExtras: true,
    ),
    RemoteLayout.minimal => settings.copyWith(
      showTvStatus: false,
      showDigits: false,
      showSleepTimer: false,
      showExtras: false,
    ),
  };
}

/// The preset matching [settings]' section visibility, or `null` when the
/// combination is custom.
RemoteLayout? matchingRemoteLayoutPreset(AppSettings settings) {
  if (settings.showTvStatus &&
      settings.showDigits &&
      settings.showSleepTimer &&
      settings.showExtras) {
    return RemoteLayout.classic;
  }
  if (!settings.showTvStatus &&
      !settings.showDigits &&
      settings.showSleepTimer &&
      settings.showExtras) {
    return RemoteLayout.compact;
  }
  if (!settings.showTvStatus &&
      !settings.showDigits &&
      !settings.showSleepTimer &&
      !settings.showExtras) {
    return RemoteLayout.minimal;
  }
  return null;
}

/// User-configurable application settings.
class AppSettings {
  const AppSettings({
    this.commandFeedback = CommandFeedback.errorsOnly,
    this.themeMode = AppThemeMode.system,
    this.dynamicColor = true,
    this.showTvStatus = true,
    this.showDigits = true,
    this.showSleepTimer = true,
    this.showExtras = true,
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

  /// Whether the app uses the system's Material You dynamic color scheme
  /// (wallpaper-based, Android 12+) when available.
  final bool dynamicColor;

  /// Whether the remote screen shows the TV status chip.
  final bool showTvStatus;

  /// Whether the remote screen shows the digit key row.
  final bool showDigits;

  /// Whether the remote screen shows the sleep-timer control.
  final bool showSleepTimer;

  /// Whether the remote screen shows the quick controls (picture, audio,
  /// favorites, settings, teletext).
  final bool showExtras;

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
    bool? dynamicColor,
    bool? showTvStatus,
    bool? showDigits,
    bool? showSleepTimer,
    bool? showExtras,
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
      dynamicColor: dynamicColor ?? this.dynamicColor,
      showTvStatus: showTvStatus ?? this.showTvStatus,
      showDigits: showDigits ?? this.showDigits,
      showSleepTimer: showSleepTimer ?? this.showSleepTimer,
      showExtras: showExtras ?? this.showExtras,
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
      other.dynamicColor == dynamicColor &&
      other.showTvStatus == showTvStatus &&
      other.showDigits == showDigits &&
      other.showSleepTimer == showSleepTimer &&
      other.showExtras == showExtras &&
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
    dynamicColor,
    showTvStatus,
    showDigits,
    showSleepTimer,
    showExtras,
    languageCode,
    sleepTimerHumanReadable,
    sleepTimerShowMinutesInParens,
    sleepTimerManualInput,
    tvStatusTracking,
    wifiWarningEnabled,
  );
}
