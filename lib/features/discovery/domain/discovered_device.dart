/// A device discovered on the local network.
///
/// Instances are produced by [DeviceDiscovery] implementations and are
/// identified by their IP address.
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.name,
    required this.ipAddress,
    required this.port,
    this.manufacturer,
    this.model,
  });

  final String name;
  final String ipAddress;
  final int port;
  final String? manufacturer;
  final String? model;

  DiscoveredDevice copyWith({
    String? name,
    String? ipAddress,
    int? port,
    String? manufacturer,
    String? model,
  }) {
    return DiscoveredDevice(
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DiscoveredDevice && other.ipAddress == ipAddress;

  @override
  int get hashCode => ipAddress.hashCode;

  @override
  String toString() =>
      'DiscoveredDevice(name: $name, ipAddress: $ipAddress, port: $port)';
}
