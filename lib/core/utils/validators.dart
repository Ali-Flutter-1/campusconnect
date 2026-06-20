/// Reusable form-field validators for the auth (and other) forms.
abstract final class Validators {
  static final RegExp _emailRegExp =
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    if (!_emailRegExp.hasMatch(s)) return 'Enter a valid email';
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
