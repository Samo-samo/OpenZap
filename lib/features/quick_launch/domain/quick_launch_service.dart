/// Apps and inputs the user can launch on a device.
///
/// The set is deliberately small and brand-neutral: concrete apps are mapped
/// to platform mechanisms (e.g. DIAL) by TV-brand integrations.
enum QuickLaunchTarget {
  /// YouTube video streaming app.
  youtube,

  /// Netflix video streaming app.
  netflix,

  /// Switches the TV to the first HDMI input.
  hdmi,

  /// Opens the TV's smart portal / home screen.
  portal,
}

/// Contract for launching apps and switching inputs on a device.
///
/// Concrete implementations are provided by TV-brand integrations.
abstract class QuickLaunchService {
  /// Launches [target] on the device.
  Future<void> launch(QuickLaunchTarget target);

  /// Releases any underlying resources.
  Future<void> close();
}
