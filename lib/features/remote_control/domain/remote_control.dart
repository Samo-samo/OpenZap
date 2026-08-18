import 'remote_key.dart';

/// Contract for sending remote-control commands to a device.
///
/// Concrete implementations are provided by TV-brand integrations.
abstract class RemoteControl {
  /// Sends a single [key] press to the device.
  Future<void> sendKey(RemoteKey key);

  /// Sends a brand-specific raw key code to the device.
  ///
  /// Escape hatch for codes that have no [RemoteKey] mapping yet.
  Future<void> sendCode(int code);

  /// Releases any underlying resources.
  Future<void> close();
}