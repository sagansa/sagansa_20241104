class FormatUtils {
  static String formatNumber(int number) {
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = number
        .toString()
        .replaceAllMapped(reg, (Match match) => '${match[1]}.');
    return result;
  }

  static String formatCurrency(int number) {
    return 'Rp ${formatNumber(number)}';
  }

  static String formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }

  static String stripHtml(String html) {
    if (html.isEmpty) return html;
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  /// Compact rupiah formatting for dashboard cards/charts.
  /// Examples: 12500000 → "Rp 12.5jt", 1200000000 → "Rp 1.2M", 5000 → "Rp 5rb".
  static String formatCurrencyCompact(int value) {
    if (value >= 1000000000) {
      return 'Rp ${(value / 1000000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    }
    if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp $value';
  }
}
