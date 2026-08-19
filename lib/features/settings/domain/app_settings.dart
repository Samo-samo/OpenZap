/// How the UI reports command delivery to the user.
enum CommandFeedback {
  /// Show a message only when a command fails.
  errorsOnly,

  /// Show a message for both successes and failures.
  all,

  /// Do not show any command feedback.
  none,
}

/// User-configurable application settings.
class AppSettings {
  const AppSettings({
    this.commandFeedback = CommandFeedback.errorsOnly,
    this.sleepTimerHumanReadable = true,
    this.sleepTimerShowMinutesInParens = true,
    this.sleepTimerManualInput = false,
  });

  /// Command feedback mode.
  final CommandFeedback commandFeedback;

  /// Whether sleep-timer durations are shown as hours and minutes
  /// (e.g. "2 hours 5 minutes") instead of flat minutes.
  final bool sleepTimerHumanReadable;

  /// Whether the flat total is shown in parentheses next to the
  /// hours/minutes form (e.g. "... (125 minutes)").
  final bool sleepTimerShowMinutesInParens;

  /// Whether the custom sleep-timer dialog offers a manual minute entry.
  final bool sleepTimerManualInput;

  AppSettings copyWith({
    CommandFeedback? commandFeedback,
    bool? sleepTimerHumanReadable,
    bool? sleepTimerShowMinutesInParens,
    bool? sleepTimerManualInput,
  }) {
    return AppSettings(
      commandFeedback: commandFeedback ?? this.commandFeedback,
      sleepTimerHumanReadable:
          sleepTimerHumanReadable ?? this.sleepTimerHumanReadable,
      sleepTimerShowMinutesInParens:
          sleepTimerShowMinutesInParens ?? this.sleepTimerShowMinutesInParens,
      sleepTimerManualInput:
          sleepTimerManualInput ?? this.sleepTimerManualInput,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.commandFeedback == commandFeedback &&
      other.sleepTimerHumanReadable == sleepTimerHumanReadable &&
      other.sleepTimerShowMinutesInParens == sleepTimerShowMinutesInParens &&
      other.sleepTimerManualInput == sleepTimerManualInput;

  @override
  int get hashCode => Object.hash(
        commandFeedback,
        sleepTimerHumanReadable,
        sleepTimerShowMinutesInParens,
        sleepTimerManualInput,
      );
}