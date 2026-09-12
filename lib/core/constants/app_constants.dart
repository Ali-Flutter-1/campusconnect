/// App-wide constants.
abstract final class AppConstants {
  /// Rows fetched per page for paginated lists / chat history.
  static const int pageSize = 20;

  /// Shown on the Settings screen. Keep in step with `version:` in pubspec.yaml.
  static const String appVersion = '1.0.0';

  /// Where "Contact support" and data-deletion requests are sent.
  // TODO: point this at the real campus support inbox before release.
  static const String supportEmail = 'support@campusconnect.app';
}
