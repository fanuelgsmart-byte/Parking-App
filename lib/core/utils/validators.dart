import 'package:flutter/services.dart';

/// Centralized input validation for all user-facing forms.
///
/// Each validator returns `null` on success or an error message on failure.
/// Use with Flutter's `TextFormField.validator` parameter.
class Validators {
  Validators._();

  // ──────────────────── License Plate ────────────────────

  /// Allows alphanumeric characters, hyphens, and spaces (2–15 chars).
  static final _licensePlateRegex = RegExp(r'^[A-Za-z0-9\- ]{2,15}$');

  static String? licensePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License plate is required';
    }
    if (!_licensePlateRegex.hasMatch(value.trim())) {
      return 'Invalid license plate format';
    }
    return null;
  }

  /// [TextInputFormatter] that restricts input to valid plate characters.
  static final licensePlateFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[A-Za-z0-9\- ]'),
  );

  // ──────────────────── Email ────────────────────

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
  );

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ──────────────────── Password ────────────────────

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must contain at least one number';
    }
    return null;
  }

  // ──────────────────── Name ────────────────────

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Name must be under 100 characters';
    }
    // Reject suspicious characters that could be injection attempts
    if (value.contains(RegExp(r'[<>{}()\[\]\\;]'))) {
      return 'Name contains invalid characters';
    }
    return null;
  }

  // ──────────────────── Payment Amount ────────────────────

  static String? paymentAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Enter a valid number';
    }
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }
    if (amount > 99999.99) {
      return 'Amount exceeds maximum allowed';
    }
    // Max 2 decimal places
    if (value.contains('.') && value.split('.').last.length > 2) {
      return 'Maximum 2 decimal places';
    }
    return null;
  }

  // ──────────────────── Rate Per Hour ────────────────────

  static String? ratePerHour(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Rate is required';
    }
    final rate = double.tryParse(value.trim());
    if (rate == null || rate <= 0) {
      return 'Enter a valid positive rate';
    }
    if (rate > 1000) {
      return 'Rate exceeds reasonable maximum';
    }
    return null;
  }

  // ──────────────────── Description / Free Text ────────────────────

  static String? description(String? value, {int maxLength = 500}) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length > maxLength) {
      return 'Description must be under $maxLength characters';
    }
    return null;
  }

  // ──────────────────── Vehicle Color ────────────────────

  static final _colorRegex = RegExp(r'^[A-Za-z\s\-]{2,30}$');

  static String? vehicleColor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vehicle color is required';
    }
    if (!_colorRegex.hasMatch(value.trim())) {
      return 'Enter a valid color (letters only)';
    }
    return null;
  }

  // ──────────────────── Spot Number ────────────────────

  static String? spotNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Spot number is required';
    }
    if (value.trim().length > 10) {
      return 'Spot number must be under 10 characters';
    }
    return null;
  }

  // ──────────────────── Generic Required ────────────────────

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
