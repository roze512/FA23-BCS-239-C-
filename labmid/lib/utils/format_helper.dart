/// Utility class for formatting money and numbers
class FormatHelper {
  /// Formats money to prevent overflow, using a dynamic currency symbol.
  /// [symbol] defaults to '₨' (PKR) but should be passed from CurrencyProvider.
  /// $1,500 -> ₨1.5K
  /// $25,000 -> ₨25K
  /// $1,500,000 -> ₨1.5M
  static String formatMoney(double value, {bool showSign = false, String symbol = '₨'}) {
    String sign = '';
    if (showSign && value > 0) sign = '+';
    if (value < 0) {
      sign = '-';
      value = value.abs();
    }
    
    if (value >= 1000000) {
      return '$sign$symbol${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '$sign$symbol${(value / 1000).toStringAsFixed(1)}K';
    } else if (value >= 100) {
      return '$sign$symbol${value.toStringAsFixed(0)}';
    }
    return '$sign$symbol${value.toStringAsFixed(2)}';
  }
  
  /// Format a price value with full precision (no K/M abbreviation)
  static String formatPrice(double value, {String symbol = '₨'}) {
    return '$symbol${value.toStringAsFixed(2)}';
  }

  /// Format number without currency symbol
  static String formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
  
  /// Format percentage
  static String formatPercentage(double value) {
    if (value.isNaN || value.isInfinite) return '0%';
    String sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }
  
  /// Format date
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
