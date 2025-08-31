// core/utils/validators.dart
class Validators {
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
}
