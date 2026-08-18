/// Error raised while discovering devices on the local network.
class DiscoveryError implements Exception {
  const DiscoveryError(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'DiscoveryError: $message';
}