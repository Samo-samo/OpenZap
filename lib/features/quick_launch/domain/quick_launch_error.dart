/// Thrown when a quick-launch action cannot be carried out.
class QuickLaunchException implements Exception {
  QuickLaunchException(this.message);

  final String message;

  @override
  String toString() => 'QuickLaunchException: $message';
}
