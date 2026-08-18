import 'tv_status.dart';

/// Contract for observing live status/events of a device.
///
/// Concrete implementations are provided by TV-brand integrations.
abstract class TvStatusService {
  /// Emits a status snapshot whenever the device pushes an event.
  ///
  /// The stream completes when the connection is lost; the caller decides
  /// whether to treat that as `TvStatus.unknown()` or reconnect.
  Stream<TvStatus> watch();

  /// Releases any underlying resources.
  Future<void> close();
}