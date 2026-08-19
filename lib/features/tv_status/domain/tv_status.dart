/// Power/state of a TV as reported by its status/events channel.
enum TvPowerState { on, off, unknown }

/// The latest live status of a TV, pushed by the device.
class TvStatus {
  const TvStatus({required this.powerState, this.stateName});

  /// [stateName] carries the raw platform state (e.g. `PLAYER_PORTAL`,
  /// `NOSIGNAL`) when known.
  const TvStatus.unknown()
    : this(powerState: TvPowerState.unknown, stateName: null);

  final TvPowerState powerState;
  final String? stateName;

  @override
  String toString() =>
      'TvStatus(powerState: $powerState, stateName: $stateName)';
}
