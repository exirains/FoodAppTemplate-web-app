class BabkaNumberFormatter {
  static String format(dynamic value, String languageCode) {
    String stringValue = value.toString();
    if (languageCode == 'fa') {
      return stringValue
          .replaceAll('0', '۰')
          .replaceAll('1', '۱')
          .replaceAll('2', '۲')
          .replaceAll('3', '۳')
          .replaceAll('4', '۴')
          .replaceAll('5', '۵')
          .replaceAll('6', '۶')
          .replaceAll('7', '۷')
          .replaceAll('8', '۸')
          .replaceAll('9', '۹');
    }
    return stringValue;
  }

  static String formatCurrency(double amount, String languageCode) {
    final formattedValue = format(amount.toStringAsFixed(0), languageCode);
    return '₺$formattedValue';
  }
}
