import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';

/// Model representing a currency option
class CurrencyOption {
  final String code;
  final String symbol;
  final String name;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

/// Provider for managing the selected currency across the app
class CurrencyProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  /// List of supported currencies
  static const List<CurrencyOption> supportedCurrencies = [
    CurrencyOption(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee'),
    CurrencyOption(code: 'USD', symbol: '\$', name: 'US Dollar'),
    CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound'),
    CurrencyOption(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    CurrencyOption(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
    CurrencyOption(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    CurrencyOption(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    CurrencyOption(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    CurrencyOption(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
  ];

  String _currencyCode = 'PKR';
  String _currencySymbol = '₨';
  bool _isLoaded = false;

  // Getters
  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  bool get isLoaded => _isLoaded;

  CurrencyOption get currentCurrency =>
      supportedCurrencies.firstWhere(
        (c) => c.code == _currencyCode,
        orElse: () => supportedCurrencies.first,
      );

  /// Load saved currency preference from database
  Future<void> loadCurrency() async {
    try {
      final code = await _settingsService.getSetting('currency_code');
      final symbol = await _settingsService.getSetting('currency_symbol');
      if (code != null && symbol != null) {
        _currencyCode = code;
        _currencySymbol = symbol;
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      _isLoaded = true;
      debugPrint('Error loading currency: $e');
    }
  }

  /// Set the active currency and persist to database
  Future<void> setCurrency(CurrencyOption currency) async {
    _currencyCode = currency.code;
    _currencySymbol = currency.symbol;
    notifyListeners();

    try {
      await _settingsService.setSetting('currency_code', currency.code);
      await _settingsService.setSetting('currency_symbol', currency.symbol);
    } catch (e) {
      debugPrint('Error saving currency: $e');
    }
  }
}
