class DateFormatter {
  static const List<String> urduMonths = [
    'جنوری',
    'فروری',
    'مارچ',
    'اپریل',
    'مئی',
    'جون',
    'جولائی',
    'اگست',
    'ستمبر',
    'اکتبر',
    'نومبر',
    'دسمبر',
  ];

  static const List<String> urduDays = [
    'اتوار',
    'پیر',
    'منگل',
    'بدھ',
    'جمعرات',
    'جمعہ',
    'ہفتہ',
  ];

  static String formatDate(DateTime date) {
    return '${date.day} ${urduMonths[date.month - 1]} ${date.year}';
  }

  static String formatDateShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatDateFull(DateTime date) {
    final dayName = urduDays[date.weekday % 7];
    return '$dayName، ${date.day} ${urduMonths[date.month - 1]} ${date.year}';
  }

  static String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String formatUrdu(DateTime d) =>
      '${d.day} ${urduMonths[d.month - 1]} ${d.year}';

  static String formatRangeUrdu(DateTime from, DateTime to) =>
      '${formatUrdu(from)} - ${formatUrdu(to)}';

  static String formatDateTimeUrdu(DateTime d) =>
      '${d.year}/${d.month}/${d.day} '
      '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}
