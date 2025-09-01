// core/utils/validators.dart
class Validators {
  // ✅ Your existing required validators (unchanged)
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? positiveInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    final intValue = int.tryParse(value);
    if (intValue == null || intValue <= 0) {
      return 'Please enter a positive integer';
    }

    return null;
  }

  static String? nonNegativeInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    final intValue = int.tryParse(value);
    if (intValue == null || intValue < 0) {
      return 'Please enter a non-negative integer';
    }

    return null;
  }

  static String? positiveDouble(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    final doubleValue = double.tryParse(value);
    if (doubleValue == null || doubleValue <= 0) {
      return 'Please enter a positive number';
    }

    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // ========================================
  // ✅ NEW - OPTIONAL VALIDATORS
  // ========================================

  /// Generic optional validator - runs validator only if value is not empty
  ///
  /// Usage:
  /// ```
  /// validator: (value) => Validators.optional(value, Validators.positiveDouble),
  /// ```
  static String? optional(String? value, String? Function(String?) validator) {
    // If value is empty, skip validation (return null = valid)
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    // If value exists, run the provided validator
    return validator(value);
  }

  /// Optional positive integer - validates only if not empty
  static String? optionalPositiveInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Skip validation if empty
    }

    final intValue = int.tryParse(value);
    if (intValue == null || intValue <= 0) {
      return 'Please enter a positive integer';
    }

    return null;
  }

  /// Optional non-negative integer - validates only if not empty
  static String? optionalNonNegativeInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Skip validation if empty
    }

    final intValue = int.tryParse(value);
    if (intValue == null || intValue < 0) {
      return 'Please enter a non-negative integer';
    }

    return null;
  }

  /// Optional positive double - validates only if not empty
  static String? optionalPositiveDouble(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Skip validation if empty
    }

    final doubleValue = double.tryParse(value);
    if (doubleValue == null || doubleValue <= 0) {
      return 'Please enter a positive number';
    }

    return null;
  }

  /// Optional email - validates only if not empty
  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Skip validation if empty
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Optional minimum length - validates only if not empty
  static String? optionalMinLength(String? value, int minLength) {
    if (value == null || value.trim().isEmpty) {
      return null; // Skip validation if empty
    }

    if (value.length < minLength) {
      return 'Must be at least $minLength characters long';
    }

    return null;
  }

  /// Optional maximum length - validates only if not empty
  static String? optionalMaxLength(String? value, int maxLength) {
    if (value == null || value.trim().isEmpty) {
      return null; // Skip validation if empty
    }

    if (value.length > maxLength) {
      return 'Must be no more than $maxLength characters long';
    }

    return null;
  }

  /// Optional phone number - validates only if not empty
  static String? optionalPhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Skip validation if empty
    }

    if (!RegExp(r'^\+?[\d\-\(\)\s]{10,}$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Optional URL - validates only if not empty
  static String? optionalUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Skip validation if empty
    }

    if (!RegExp(r'^https?:\/\/.+\..+').hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Optional range validator - validates only if not empty
  static String? optionalRange(String? value, double min, double max) {
    if (value == null || value.trim().isEmpty) {
      return null; // Skip validation if empty
    }

    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Please enter a valid number';
    }

    if (doubleValue < min || doubleValue > max) {
      return 'Must be between $min and $max';
    }

    return null;
  }

  // ========================================
  // ✅ COMPOSITE VALIDATORS
  // ========================================

  /// Combine multiple validators - stops at first error
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result; // Return first error found
        }
      }
      return null; // All validators passed
    };
  }

  /// Either/or validator - value must pass at least one validator
  static String? Function(String?) either(
      List<String? Function(String?)> validators,
      String errorMessage
      ) {
    return (String? value) {
      for (final validator in validators) {
        if (validator(value) == null) {
          return null; // At least one validator passed
        }
      }
      return errorMessage; // All validators failed
    };
  }
}
