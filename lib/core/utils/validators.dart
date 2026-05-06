import '../constants/app_strings.dart';

class Validators {
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.enterAmount;
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return AppStrings.invalidAmount;
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final phoneRegex = RegExp(r'^03[0-9]{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return AppStrings.invalidPhone;
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.enterName;
    }
    if (value.trim().length < 2) {
      return AppStrings.enterName;
    }
    return null;
  }
}
