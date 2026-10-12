/// Reusable form-field validators for the auth (and other) forms.
abstract final class Validators {
  static final RegExp _emailRegExp =
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Campus addresses only: name@root.edu or name@dept.root.edu. Mirrors the
  /// `enforce_campus_email` trigger in migration 0013, which is the real
  /// guard — this check just gives a clear message before the request.
  static final RegExp _campusDomain = RegExp(
    r'@([a-z0-9-]+\.)*root\.edu$',
    caseSensitive: false,
  );

  /// Shown as the email field hint wherever an address is entered.
  static const String campusEmailHint = 'you@root.edu';

  static String? email(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    if (!_emailRegExp.hasMatch(s)) return 'Enter a valid email';
    if (!_campusDomain.hasMatch(s)) {
      return 'Use your campus email ending in root.edu';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Minimum 6 characters';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }
}
