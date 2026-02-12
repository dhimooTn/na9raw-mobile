// utils/validators.dart

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    return null;
  }

  // Phone validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // Professional Experience validation
  static String? validateExperience(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please describe your professional experience';
    }
    if (value.trim().length < 50) {
      return 'Please provide at least 50 characters describing your experience';
    }
    return null;
  }

  // Educational Qualifications validation
  static String? validateQualifications(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please list your educational qualifications';
    }
    if (value.trim().length < 20) {
      return 'Please provide at least 20 characters describing your qualifications';
    }
    return null;
  }

  // Generic text validation with custom message and min length
  static String? validateText({
    String? value,
    required String fieldName,
    int minLength = 1,
  }) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    return null;
  }
}