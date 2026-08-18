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
  const AppSettings({required this.commandFeedback});

  /// Command feedback mode. Defaults to [CommandFeedback.errorsOnly].
  final CommandFeedback commandFeedback;

  AppSettings copyWith({CommandFeedback? commandFeedback}) {
    return AppSettings(
      commandFeedback: commandFeedback ?? this.commandFeedback,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings && other.commandFeedback == commandFeedback;

  @override
  int get hashCode => commandFeedback.hashCode;
}