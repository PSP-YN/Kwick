import '../config/app_config.dart';

/// Central input validation rules across customer, provider, and auth forms
class Validators {
  Validators._();

  static String? validateRequired(
    String? value, [
    String fieldName = 'This field',
  ]) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address.';
    }
    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a contact phone number.';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 13) {
      return 'Please enter a valid 10-digit phone number.';
    }
    return null;
  }

  static String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a 6-digit pincode.';
    }
    final cleaned = value.trim();
    if (!RegExp(r'^[0-9]{6}$').hasMatch(cleaned)) {
      return 'Pincode must be exactly 6 digits.';
    }
    // Pilot region warning/check
    if (cleaned != AppConfig.pilotPincode) {
      return 'NexHelp currently serves pincode ${AppConfig.pilotPincode} (HSR Layout focus).';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please describe the problem.';
    }
    final len = value.trim().length;
    if (len < AppConfig.minDescriptionLength) {
      return 'Description must be at least ${AppConfig.minDescriptionLength} characters.';
    }
    if (len > AppConfig.maxDescriptionLength) {
      return 'Description cannot exceed ${AppConfig.maxDescriptionLength} characters.';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your service address.';
    }
    if (value.trim().length < AppConfig.minAddressLength) {
      return 'Address must be at least ${AppConfig.minAddressLength} characters.';
    }
    if (value.trim().length > AppConfig.maxAddressLength) {
      return 'Address cannot exceed ${AppConfig.maxAddressLength} characters.';
    }
    return null;
  }

  static String? validateExperienceYears(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please specify your years of experience.';
    }
    final years = int.tryParse(value.trim());
    if (years == null || years < 0 || years > 60) {
      return 'Please enter a valid number of years (0 - 60).';
    }
    return null;
  }
}
