class Validators {
  static String? Function(String?) notEmpty(String message) {
    return (v) => (v == null || v.trim().isEmpty) ? message : null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
    final digits = v.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^(\+?60|0)\d{8,10}$').hasMatch(digits)) {
      return 'Enter a valid Malaysian number, e.g. 012-3456789';
    }
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your work email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Enter a valid email, e.g. name@company.com';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Please create a password';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Include both letters and numbers';
    }
    return null;
  }
}
