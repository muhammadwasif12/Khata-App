import '../constants/app_strings.dart';

class CurrencyFormatter {
  static String formatAmount(double amount) {
    final String str = amount.toStringAsFixed(0);
    final StringBuffer result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write(',');
      }
      result.write(str[i]);
      count++;
    }
    final String formatted = result.toString().split('').reversed.join();
    return '${AppStrings.currency} $formatted';
  }

  static String formatAmountSigned(double amount) {
    if (amount >= 0) {
      return '+${formatAmount(amount)}';
    } else {
      return '-${formatAmount(amount.abs())}';
    }
  }

  static String formatShort(double amount) {
    final String str = amount.toStringAsFixed(0);
    final StringBuffer result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write(',');
      }
      result.write(str[i]);
      count++;
    }
    return result.toString().split('').reversed.join();
  }
}
