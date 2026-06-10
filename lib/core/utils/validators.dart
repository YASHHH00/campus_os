import '../constants/app_constants.dart';

/// Input validators used across the app.
///
/// All methods return `null` on valid input, or an error message string
/// on invalid input. Compatible with Flutter's `TextFormField.validator`.
class Validators {
  Validators._();

  /// Validate a title/name field.
  static String? title(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < AppConstants.minTitleLength) {
      return 'Title is too short';
    }
    if (value.trim().length > AppConstants.maxTitleLength) {
      return 'Title must be under ${AppConstants.maxTitleLength} characters';
    }
    return null;
  }

  /// Validate an expense amount.
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < AppConstants.minExpenseAmount) {
      return 'Amount must be at least ₹${AppConstants.minExpenseAmount}';
    }
    if (parsed > 1000000) {
      return 'Amount seems too large. Please verify.';
    }
    return null;
  }

  /// Validate that a participant list has enough members.
  static String? participants(List<String>? names) {
    if (names == null || names.isEmpty) {
      return 'Add at least ${AppConstants.minParticipants} participants';
    }
    if (names.length < AppConstants.minParticipants) {
      return 'Need at least ${AppConstants.minParticipants} participants to split';
    }
    final uniqueNames = names.map((n) => n.trim().toLowerCase()).toSet();
    if (uniqueNames.length != names.length) {
      return 'Duplicate participant names found';
    }
    return null;
  }

  /// Validate a description field.
  static String? description(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length > 1000) {
      return 'Description must be under 1000 characters';
    }
    return null;
  }

  /// Validate a location field.
  static String? location(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Location is required';
    }
    return null;
  }

  /// Validate that a paid-by name is in the participants list.
  static String? paidBy(String? value, List<String> participants) {
    if (value == null || value.trim().isEmpty) {
      return 'Select who paid';
    }
    if (!participants.contains(value.trim())) {
      return 'Payer must be a participant';
    }
    return null;
  }

  /// Validate a date is not in the past (for scheduling).
  static String? futureDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }
    if (date.isBefore(DateTime.now())) {
      return 'Date cannot be in the past';
    }
    return null;
  }

  /// Validate that a string looks like valid JSON.
  static bool isValidJson(String value) {
    try {
      // ignore: unnecessary_import
      final _ = value; // Simple structure check
      return value.startsWith('{') || value.startsWith('[');
    } catch (_) {
      return false;
    }
  }
}
