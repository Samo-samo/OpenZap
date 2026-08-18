/// Thrown when a remote-control command could not be delivered to the device.
class RemoteControlException implements Exception {
  const RemoteControlException(this.message);

  final String message;

  @override
  String toString() => 'RemoteControlException: $message';
}